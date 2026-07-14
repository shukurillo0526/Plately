"""Debug: dump full Ollama API response."""
import asyncio, json
import httpx

async def main():
    client = httpx.AsyncClient(timeout=120.0)
    
    payload = {
        "model": "qwen3:14b",
        "messages": [
            {"role": "user", "content": "Say hello in Uzbek"}
        ],
        "stream": False,
        "options": {"temperature": 0.3, "num_predict": 500}
    }
    resp = await client.post("http://localhost:11434/api/chat", json=payload)
    data = resp.json()
    
    # Print full response structure
    print(json.dumps(data, indent=2, ensure_ascii=False, default=str))
    
    await client.aclose()

if __name__ == "__main__":
    asyncio.run(main())
