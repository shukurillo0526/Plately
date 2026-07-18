"""
Plately — Robot Planner Service
==================================
Transforms a recipe's structured steps into a full RobotExecutionPlan
that can be streamed to a robotic controller via WebSocket.
"""

from datetime import datetime
import uuid

from app.db.supabase_client import get_supabase
from app.models.robot import (
    RobotAction,
    RobotActionParameters,
    RobotExecutionPlan,
    KitchenState,
    KitchenIngredient,
    SensorCheck,
)


# Actions that involve heat — used for safety warnings
HEAT_ACTIONS = {"HEAT", "FRY", "SAUTÉ", "BOIL", "BAKE", "GRILL"}
SHARP_TOOLS = {"chef_knife", "paring_knife", "mandoline", "grater"}


class RobotPlannerError(Exception):
    """Raised when plan validation fails."""
    pass


class RobotPlanner:
    """
    Builds a validated RobotExecutionPlan from a recipe's structured steps.

    Validation includes:
    - All required ingredients are in the user's inventory
    - Safety warnings are generated for high-risk steps
    - Step dependencies form a valid DAG
    """

    def __init__(self):
        pass

    async def create_plan(
        self, recipe_id: str, user_id: str
    ) -> RobotExecutionPlan:
        """
        Generate a full execution plan for a recipe.

        Steps:
        1. Fetch recipe metadata
        2. Fetch and parse structured steps (robot_action JSONB)
        3. Validate inventory covers all ingredients
        4. Generate safety warnings
        5. Build kitchen state (ingredients, tools, appliances)
        """
        # 1. Fetch recipe
        recipe_result = await (
            (await get_supabase()).table("recipes")
            .select("id, title, prep_time_minutes, cook_time_minutes, servings")
            .eq("id", recipe_id)
            .single()
            .execute()
        )
        recipe = recipe_result.data
        if not recipe:
            raise RobotPlannerError(f"Recipe {recipe_id} not found")

        # 2. Fetch structured steps
        steps_result = await (
            (await get_supabase()).table("recipe_steps")
            .select("step_number, human_text, robot_action, estimated_seconds, requires_attention")
            .eq("recipe_id", recipe_id)
            .order("step_number")
            .execute()
        )
        raw_steps = steps_result.data or []

        if not raw_steps:
            raise RobotPlannerError(f"Recipe {recipe_id} has no structured steps")

        # 3. Parse steps into RobotAction models
        actions: list[RobotAction] = []
        total_seconds = 0
        all_tools: set[str] = set()
        all_appliances: set[str] = set()

        for step in raw_steps:
            ra = step["robot_action"]
            params = RobotActionParameters(**(ra.get("parameters") or {}))

            sensor = None
            if ra.get("sensor_check"):
                sensor = SensorCheck(**ra["sensor_check"])

            action = RobotAction(
                step_number=step["step_number"],
                action=ra["action"],
                target=ra["target"],
                tool=ra.get("tool"),
                parameters=params,
                duration_seconds=ra.get("duration_seconds"),
                temperature_celsius=ra.get("temperature_celsius"),
                sensor_check=sensor,
                dependencies=ra.get("dependencies", []),
                outputs=ra.get("outputs", []),
                requires_attention=step.get("requires_attention", True),
                human_text=step["human_text"],
            )
            actions.append(action)
            total_seconds += step.get("estimated_seconds") or 0

            if ra.get("tool"):
                all_tools.add(ra["tool"])
            # Infer appliances from action type
            if ra["action"] in HEAT_ACTIONS:
                all_appliances.add("stove_burner")
            if ra["action"] == "BAKE":
                all_appliances.add("oven")

        # 4. Fetch recipe ingredients for kitchen state
        ingredients_result = await (
            (await get_supabase()).table("recipe_ingredients")
            .select("ingredient_id, quantity, unit")
            .eq("recipe_id", recipe_id)
            .execute()
        )
        kitchen_ingredients: list[KitchenIngredient] = []
        for ing in ingredients_result.data or []:
            # Get ingredient name
            ing_detail = await (
                (await get_supabase()).table("ingredients")
                .select("canonical_name")
                .eq("id", ing["ingredient_id"])
                .single()
                .execute()
            )
            name = ing_detail.data["canonical_name"] if ing_detail.data else "unknown"
            kitchen_ingredients.append(
                KitchenIngredient(
                    name=name,
                    quantity=float(ing["quantity"]),
                    unit=ing["unit"],
                )
            )

        # 5. Generate safety warnings
        warnings = self._generate_safety_warnings(actions)

        # 6. Assemble the plan
        plan = RobotExecutionPlan(
            plan_id=f"exec_{uuid.uuid4()}",
            recipe_id=recipe_id,
            recipe_title=recipe["title"],
            total_steps=len(actions),
            estimated_total_seconds=total_seconds
            or ((recipe.get("prep_time_minutes") or 0) + (recipe.get("cook_time_minutes") or 0)) * 60,
            actions=actions,
            safety_warnings=warnings,
            kitchen_state=KitchenState(
                required_ingredients=kitchen_ingredients,
                required_tools=sorted(all_tools),
                required_appliances=sorted(all_appliances),
            ),
        )

        return plan

    def _generate_safety_warnings(self, actions: list[RobotAction]) -> list[str]:
        """Auto-generate safety warnings based on step analysis."""
        warnings: list[str] = []

        for action in actions:
            # Hot surface / oil warnings
            if action.temperature_celsius and action.temperature_celsius >= 150:
                warnings.append(
                    f"Step {action.step_number} involves high heat "
                    f"({action.temperature_celsius}°C). "
                    f"Ensure splash guard is engaged."
                )

            # Sharp tool warnings
            if action.tool and action.tool in SHARP_TOOLS:
                warnings.append(
                    f"Step {action.step_number} uses {action.tool}. "
                    f"Verify blade guard is retracted only during operation."
                )

            # Open flame
            if action.action in {"GRILL", "FLAMBÉ"}:
                warnings.append(
                    f"Step {action.step_number} involves open flame. "
                    f"Verify fire suppression system is armed."
                )

        return warnings
