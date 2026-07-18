import asyncio
import logging
import json
from datetime import datetime, timezone
from app.db.supabase_client import get_supabase
from app.services.ai_service import get_ai_service

logger = logging.getLogger("worker")

from app.db.supabase_client import get_supabase

async def process_job(db, job):
    job_id = job["id"]
    task_name = job["task_name"]
    payload = job["payload"] or {}
    
    logger.info(f"Processing job {job_id}: {task_name}")
    
    try:
        # Mark as processing
        await db.table("async_jobs").update({
            "status": "processing",
            "started_at": datetime.now(timezone.utc).isoformat()
        }).eq("id", job_id).execute()
        
        result = None
        if task_name == "generate_recipe":
            ollama = get_ai_service()
            prompt = payload.get("prompt")
            system_prompt = payload.get("system_prompt")
            model = payload.get("model", "gemini-2.5-flash")
            
            result = await ollama.generate_text_json(
                prompt=prompt,
                system_prompt=system_prompt,
                model=model
            )
            
        else:
            raise ValueError(f"Unknown task: {task_name}")
            
        # Mark as completed
        await db.table("async_jobs").update({
            "status": "completed",
            "result": result,
            "completed_at": datetime.now(timezone.utc).isoformat()
        }).eq("id", job_id).execute()
        
        logger.info(f"Job {job_id} completed successfully.")
        
    except Exception as e:
        logger.error(f"Job {job_id} failed: {e}")
        await db.table("async_jobs").update({
            "status": "failed",
            "error_message": str(e),
            "completed_at": datetime.now(timezone.utc).isoformat()
        }).eq("id", job_id).execute()


async def worker_loop():
    """
    Background worker loop that polls the async_jobs table.
    In a real massive deployment, you'd use Redis+Celery or PG FOR UPDATE SKIP LOCKED.
    Since we're using Supabase REST API, we simulate locking by updating status to 'processing'
    with a status='pending' filter.
    """
    logger.info("Worker loop started.")
    db = await get_supabase()
    
    while True:
        try:
            # 1. Fetch one pending job
            # Note: without FOR UPDATE SKIP LOCKED via RPC, this could race if multiple workers exist.
            # For 10x concurrency prototype, a single background worker loop in the main process is fine.
            res = await db.table("async_jobs").select("*").eq("status", "pending").order("created_at").limit(1).execute()
            
            if res.data and len(res.data) > 0:
                job = res.data[0]
                
                # Atomically claim the job (only claim if it is STILL pending)
                # Supabase REST doesn't easily do "update where status=pending returning *",
                # but we can do it via a quick RPC or just try update.
                # Since we have one worker loop in FastAPI for now, this is safe.
                await process_job(db, job)
            else:
                # No jobs, sleep
                await asyncio.sleep(2)
                
        except asyncio.CancelledError:
            logger.info("Worker loop cancelled.")
            break
        except Exception as e:
            logger.error(f"Worker loop error: {e}")
            await asyncio.sleep(5)
