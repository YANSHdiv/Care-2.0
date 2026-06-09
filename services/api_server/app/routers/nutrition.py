"""
Care 2.0 — Nutrition Router
Food image analysis and meal logging endpoints.
"""
from fastapi import APIRouter, HTTPException, UploadFile, File, Form
from typing import Optional
from app.services.nutrition_service import classify_food_with_gemini, analyze_food
from app.services import firebase_service

router = APIRouter(prefix="/api/v1/nutrition", tags=["Nutrition"])


@router.post("/analyze")
async def analyze_meal(
    image: UploadFile = File(...),
    uid: str = Form(...),
    meal_type: str = Form(default="other"),
):
    """
    Analyze a food image for nutritional content and spike factors.
    
    Workflow:
    1. Receives food photo from the Flutter app
    2. Classifies the food using CNN model (simulated for prototype)
    3. Looks up nutritional data from Indian food database
    4. Checks user's medical conditions for spike factor warnings
    5. Returns detailed analysis with alternatives if food is unsuitable
    """
    if not image.filename:
        raise HTTPException(status_code=400, detail="No image provided")
    
    # Read image
    image_bytes = await image.read()
    
    # Get user profile for medical conditions
    user_profile = await firebase_service.get_user_profile(uid)
    user_conditions = []
    if user_profile and "clinical_history" in user_profile:
        user_conditions = user_profile["clinical_history"].get("conditions", [])
    
    # Classify food using Gemini Vision AI
    food_name, confidence, custom_nut = await classify_food_with_gemini(
        image_bytes, mime_type=image.content_type
    )
    
    # Analyze against user conditions
    result = analyze_food(
        food_name=food_name,
        confidence=confidence,
        user_conditions=user_conditions,
        custom_nutrition=custom_nut
    )
    
    # Log the meal
    await firebase_service.save_meal_log(uid, {
        "food_name": result.food_name,
        "nutrition": result.nutrition.model_dump(),
        "spike_factors": [sf.model_dump() for sf in result.spike_factors],
        "is_suitable": result.is_suitable,
        "meal_type": meal_type,
        "confidence": result.confidence,
    })
    
    return result.model_dump()


@router.get("/history/{uid}")
async def get_meal_history(uid: str, limit: int = 30):
    """Get meal analysis history for a user."""
    meals = await firebase_service.get_meal_history(uid, limit)
    return {"uid": uid, "meals": meals, "count": len(meals)}


@router.get("/database")
async def get_food_database():
    """Get the complete Indian food nutrition database."""
    from app.services.nutrition_service import INDIAN_FOOD_DB
    return {
        name.replace("_", " ").title(): info.model_dump()
        for name, info in INDIAN_FOOD_DB.items()
    }
