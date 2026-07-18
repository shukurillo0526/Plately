"""
Plately — Vision Service
===========================
Orchestrates the Clarifai food recognition pipeline
with confidence gating, canonical mapping, and correction logging.
"""

import base64
import logging

try:
    from clarifai_grpc.channel.clarifai_channel import ClarifaiChannel
    from clarifai_grpc.grpc.api import resources_pb2, service_pb2, service_pb2_grpc
    from clarifai_grpc.grpc.api.status import status_code_pb2
    CLARIFAI_AVAILABLE = True
except ImportError:
    CLARIFAI_AVAILABLE = False
    logging.getLogger("plately.vision").warning(
        "[Vision] clarifai-grpc not installed — Clarifai vision disabled"
    )

from app.core.config import get_settings
from app.db.supabase_client import get_supabase
from app.models.vision import VisionPrediction


class VisionAPIError(Exception):
    """Raised when Clarifai API returns an error."""
    pass


class VisionService:
    """
    Processes food images through Clarifai and maps predictions
    to canonical ingredients with confidence-based action gating.

    Thresholds:
        >= 0.90  →  auto_add  (instant, with undo toast)
        >= 0.70  →  confirm   (show confirmation card with alternatives)
        <  0.70  →  correct   (full correction UI with search)
    """

    def __init__(self):
        self.settings = get_settings()
        pass
        self._stub = None
        self._metadata = None

    @property
    def stub(self):
        if self._stub is None:
            channel = ClarifaiChannel.get_grpc_channel()
            self._stub = service_pb2_grpc.V2Stub(channel)
            self._metadata = (("authorization", f"Key {self.settings.CLARIFAI_API_KEY}"),)
        return self._stub

    @property
    def metadata(self):
        if self._metadata is None:
            _ = self.stub  # triggers lazy init
        return self._metadata

    async def recognize_ingredients(
        self, image_bytes: bytes
    ) -> list[VisionPrediction]:
        """
        Send image to Clarifai Food Model and return classified predictions.

        Each prediction is mapped to our canonical ingredient table and
        classified into an action tier (auto_add / confirm / correct).
        """
        # Encode image for gRPC
        b64_image = base64.b64encode(image_bytes)

        request = service_pb2.PostModelOutputsRequest(
            model_id=self.settings.CLARIFAI_FOOD_MODEL_ID,
            inputs=[
                resources_pb2.Input(
                    data=resources_pb2.Data(
                        image=resources_pb2.Image(base64=b64_image)
                    )
                )
            ],
        )

        response = self.stub.PostModelOutputs(request, metadata=self.metadata)

        if response.status.code != status_code_pb2.SUCCESS:
            raise VisionAPIError(
                f"Clarifai API error: {response.status.description}"
            )

        predictions: list[VisionPrediction] = []
        concepts = response.outputs[0].data.concepts

        for concept in concepts:
            confidence = round(concept.value, 3)

            # Map to our canonical ingredient
            canonical = await self._map_to_canonical(concept.name, concept.id)

            # Get alternatives for the correction UI
            alternatives = []
            if confidence < self.settings.VISION_THRESHOLD_AUTO:
                alternatives = await self._get_alternatives(concept.name)

            action = self._classify_action(confidence)

            predictions.append(
                VisionPrediction(
                    clarifai_concept=concept.name,
                    clarifai_id=concept.id,
                    confidence=confidence,
                    action=action,
                    canonical_match=canonical,
                    alternatives=alternatives,
                )
            )

        return predictions

    def _classify_action(self, confidence: float) -> str:
        """Gate predictions by confidence threshold."""
        if confidence >= self.settings.VISION_THRESHOLD_AUTO:
            return "auto_add"
        elif confidence >= self.settings.VISION_THRESHOLD_CONFIRM:
            return "confirm"
        else:
            return "correct"

    async def _map_to_canonical(
        self, concept_name: str, clarifai_id: str
    ) -> dict | None:
        """
        Map a Clarifai concept to our canonical ingredients table.

        Strategy:
        1. Exact match on clarifai_concept_ids array (pre-mapped)
        2. Fuzzy match on display_name_en using trigram similarity
        """
        # 1. Exact concept ID match
        result = await (
            (await get_supabase()).table("ingredients")
            .select("id, canonical_name, display_name_en")
            .contains("clarifai_concept_ids", [clarifai_id])
            .limit(1)
            .execute()
        )
        if result.data:
            return result.data[0]

        # 2. Fuzzy name match via Supabase RPC (uses pg_trgm)
        result = await (await get_supabase()).rpc(
            "fuzzy_match_ingredient",
            {"search_name": concept_name, "min_similarity": 0.3, "max_results": 1},
        ).execute()

        if result.data:
            return result.data[0]

        return None

    async def _get_alternatives(self, concept_name: str) -> list[dict]:
        """
        Get alternative ingredient suggestions for the correction UI.
        Returns top 5 fuzzy matches by name similarity.
        """
        result = await (await get_supabase()).rpc(
            "fuzzy_match_ingredient",
            {"search_name": concept_name, "min_similarity": 0.2, "max_results": 5},
        ).execute()
        return result.data or []

    async def log_correction(
        self,
        user_id: str,
        original_prediction: str,
        corrected_ingredient_id: str,
        clarifai_concept_id: str | None = None,
        confidence: float | None = None,
        image_path: str | None = None,
    ) -> None:
        """
        Log a user correction for model improvement.

        These corrections feed into:
        1. Improved clarifai_concept_ids mappings (batch job)
        2. Fine-tuning dataset for custom vision models
        3. Analytics on model blind spots
        """
        await (await get_supabase()).table("vision_corrections").insert(
            {
                "user_id": user_id,
                "original_prediction": original_prediction,
                "corrected_to": corrected_ingredient_id,
                "clarifai_concept_id": clarifai_concept_id,
                "confidence": confidence,
                "image_storage_path": image_path,
            }
        ).execute()

    async def add_to_inventory(
        self,
        user_id: str,
        ingredient_id: str,
        confidence: float,
        source: str = "camera",
    ) -> str:
        """Add a recognized ingredient to the user's inventory."""
        result = await (
            (await get_supabase()).table("inventory_items")
            .insert(
                {
                    "user_id": user_id,
                    "ingredient_id": ingredient_id,
                    "source": source,
                    "confidence_score": confidence,
                    "quantity": 1,
                    "item_state": "sealed",
                }
            )
            .execute()
        )
        return result.data[0]["id"] if result.data else ""
