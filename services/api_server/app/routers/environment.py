"""
Care 2.0 — Environment Router
AQI dashboard and exercise recommendation endpoints.
"""
from fastapi import APIRouter, Query
from pydantic import BaseModel
from typing import Optional
from app.services.weather_service import fetch_environment_data, get_exercise_recommendation

router = APIRouter(prefix="/api/v1/environment", tags=["Environment"])


class RecommendationRequest(BaseModel):
    latitude: float
    longitude: float
    user_conditions: list[str] = []


@router.get("/aqi")
async def get_aqi(
    lat: float = Query(..., description="Latitude"),
    lon: float = Query(..., description="Longitude")
):
    """
    Fetch real-time AQI and weather data for a location.
    Uses OpenWeatherMap API with simulated fallback for demo.
    """
    data = await fetch_environment_data(lat, lon)
    return data.model_dump()


@router.post("/recommendation")
async def get_recommendation(request: RecommendationRequest):
    """
    Get context-aware exercise recommendation based on:
    - Current AQI and weather at the user's location
    - User's medical conditions (for sensitivity detection)
    
    Implements the "Delhi Logic" — automatically overrides
    outdoor exercise with indoor alternatives when:
    - AQI >= 4 (Poor/Very Poor) 
    - AQI >= 3 for sensitive individuals (asthma/COPD)
    - Rain/Thunderstorm weather
    - Temperature > 40°C or < 5°C
    """
    # Fetch current environment data
    env_data = await fetch_environment_data(request.latitude, request.longitude)
    
    # Run constraint engine
    recommendation = get_exercise_recommendation(
        user_conditions=request.user_conditions,
        current_aqi=env_data.aqi,
        weather=env_data.weather_main,
        temperature=env_data.temperature_c,
    )
    
    return {
        "environment": env_data.model_dump(),
        "recommendation": recommendation.model_dump(),
    }
