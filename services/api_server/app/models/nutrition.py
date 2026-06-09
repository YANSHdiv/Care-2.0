"""
Care 2.0 — Pydantic Models for Nutrition Analysis
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class NutritionInfo(BaseModel):
    calories: int = 0
    protein_g: float = 0
    carbs_g: float = 0
    fat_g: float = 0
    sodium_mg: float = 0
    fiber_g: float = 0
    sugar_g: float = 0
    cholesterol_mg: float = 0


class SpikeFactor(BaseModel):
    nutrient: str
    value: float
    threshold: float
    severity: str  # low, medium, high
    warning: str


class FoodAnalysisResult(BaseModel):
    food_name: str
    confidence: float = Field(ge=0, le=1)
    nutrition: NutritionInfo
    spike_factors: list[SpikeFactor] = Field(default_factory=list)
    is_suitable: bool = True
    alternative_suggestions: list[str] = Field(default_factory=list)
    analyzed_at: datetime = Field(default_factory=datetime.utcnow)


class MealLogEntry(BaseModel):
    uid: str
    food_name: str
    nutrition: NutritionInfo
    spike_factors: list[SpikeFactor] = Field(default_factory=list)
    image_url: Optional[str] = None
    meal_type: str = "other"  # breakfast, lunch, dinner, snack, other
    logged_at: datetime = Field(default_factory=datetime.utcnow)


class DailyNutritionSummary(BaseModel):
    uid: str
    date: str
    total_calories: int = 0
    total_protein_g: float = 0
    total_carbs_g: float = 0
    total_fat_g: float = 0
    total_sodium_mg: float = 0
    meals_logged: int = 0
    warnings_triggered: int = 0
