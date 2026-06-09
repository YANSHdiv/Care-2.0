"""
Care 2.0 — Pydantic Models for Health Data & Predictions
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from enum import Enum


class RiskCategory(str, Enum):
    HEALTHY = "healthy"
    AT_RISK = "at_risk"
    CRITICAL = "critical"


class DailyHealthMetrics(BaseModel):
    date: str  # YYYY-MM-DD
    avg_heart_rate: float = Field(default=72, ge=30, le=220)
    max_heart_rate: float = Field(default=100, ge=30, le=250)
    min_heart_rate: float = Field(default=55, ge=25, le=200)
    heart_rate_variability: float = Field(default=50, ge=0)
    avg_spo2: float = Field(default=97, ge=70, le=100)
    min_spo2: float = Field(default=95, ge=70, le=100)
    daily_steps: int = Field(default=5000, ge=0)
    sleep_hours: float = Field(default=7, ge=0, le=24)
    systolic_bp: Optional[float] = None
    diastolic_bp: Optional[float] = None


class ThirtyDayData(BaseModel):
    uid: str
    metrics: list[DailyHealthMetrics]
    age: int
    bmi: float
    genetic_risk_cardiac: int = Field(default=0, ge=0, le=1)
    genetic_risk_diabetes: int = Field(default=0, ge=0, le=1)
    genetic_risk_respiratory: int = Field(default=0, ge=0, le=1)


class RiskPrediction(BaseModel):
    overall_risk_score: int = Field(ge=0, le=100)
    cardiac_risk: float = Field(ge=0, le=1)
    respiratory_risk: float = Field(ge=0, le=1)
    metabolic_risk: float = Field(ge=0, le=1)
    risk_category: RiskCategory
    top_concerns: list[str]
    recommendations: list[str]
    healthspan_trajectory: list[dict]  # [{month, projected_score}]
    generated_at: datetime = Field(default_factory=datetime.utcnow)


class EnvironmentData(BaseModel):
    latitude: float
    longitude: float
    aqi: int = Field(ge=0)
    aqi_label: str
    temperature_c: float
    humidity: int
    weather_main: str
    weather_description: str
    wind_speed: float
    pm25: Optional[float] = None
    pm10: Optional[float] = None


class ExerciseActivity(BaseModel):
    name: str
    duration_min: int
    intensity: str  # low, medium, high
    calories_burn_estimate: int = 0
    description: str = ""


class ExerciseRecommendation(BaseModel):
    mode: str  # indoor / outdoor
    reason: str
    aqi_level: int
    weather: str
    temperature: float
    activities: list[ExerciseActivity]
    warnings: list[str] = Field(default_factory=list)
