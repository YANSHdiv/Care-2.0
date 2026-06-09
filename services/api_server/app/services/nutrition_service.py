"""
Care 2.0 — Nutrition Analysis Service
Handles food classification and nutritional analysis with spike factor detection.
Uses a comprehensive Indian food nutrition database.
"""
from app.models.nutrition import (
    NutritionInfo, SpikeFactor, FoodAnalysisResult
)
from typing import Optional
import random
import os
import httpx
import base64
import json

# ─────────────────────────────────────────────────────────
# Comprehensive Indian Food Nutrition Database
# Source: IFCT (Indian Food Composition Tables) + USDA
# ─────────────────────────────────────────────────────────
INDIAN_FOOD_DB: dict[str, NutritionInfo] = {
    "butter_chicken": NutritionInfo(
        calories=438, protein_g=28, carbs_g=12, fat_g=32,
        sodium_mg=820, fiber_g=2, sugar_g=5, cholesterol_mg=95
    ),
    "dal_makhani": NutritionInfo(
        calories=320, protein_g=15, carbs_g=38, fat_g=14,
        sodium_mg=680, fiber_g=8, sugar_g=3, cholesterol_mg=20
    ),
    "paneer_tikka": NutritionInfo(
        calories=350, protein_g=22, carbs_g=8, fat_g=26,
        sodium_mg=550, fiber_g=1, sugar_g=2, cholesterol_mg=65
    ),
    "biryani": NutritionInfo(
        calories=520, protein_g=25, carbs_g=65, fat_g=18,
        sodium_mg=920, fiber_g=3, sugar_g=2, cholesterol_mg=70
    ),
    "chole_bhature": NutritionInfo(
        calories=580, protein_g=16, carbs_g=62, fat_g=30,
        sodium_mg=750, fiber_g=10, sugar_g=4, cholesterol_mg=15
    ),
    "masala_dosa": NutritionInfo(
        calories=380, protein_g=8, carbs_g=52, fat_g=16,
        sodium_mg=620, fiber_g=4, sugar_g=3, cholesterol_mg=10
    ),
    "idli_sambar": NutritionInfo(
        calories=180, protein_g=8, carbs_g=32, fat_g=3,
        sodium_mg=380, fiber_g=4, sugar_g=2, cholesterol_mg=0
    ),
    "tandoori_chicken": NutritionInfo(
        calories=260, protein_g=35, carbs_g=4, fat_g=12,
        sodium_mg=480, fiber_g=1, sugar_g=1, cholesterol_mg=85
    ),
    "palak_paneer": NutritionInfo(
        calories=290, protein_g=16, carbs_g=10, fat_g=22,
        sodium_mg=520, fiber_g=4, sugar_g=3, cholesterol_mg=55
    ),
    "rajma_chawal": NutritionInfo(
        calories=420, protein_g=18, carbs_g=68, fat_g=8,
        sodium_mg=700, fiber_g=12, sugar_g=3, cholesterol_mg=5
    ),
    "samosa": NutritionInfo(
        calories=310, protein_g=6, carbs_g=32, fat_g=18,
        sodium_mg=480, fiber_g=3, sugar_g=2, cholesterol_mg=10
    ),
    "pav_bhaji": NutritionInfo(
        calories=400, protein_g=10, carbs_g=48, fat_g=20,
        sodium_mg=720, fiber_g=6, sugar_g=5, cholesterol_mg=30
    ),
    "roti_sabzi": NutritionInfo(
        calories=250, protein_g=8, carbs_g=38, fat_g=8,
        sodium_mg=350, fiber_g=5, sugar_g=3, cholesterol_mg=5
    ),
    "fish_curry": NutritionInfo(
        calories=280, protein_g=28, carbs_g=8, fat_g=16,
        sodium_mg=580, fiber_g=2, sugar_g=2, cholesterol_mg=75
    ),
    "kheer": NutritionInfo(
        calories=320, protein_g=8, carbs_g=48, fat_g=12,
        sodium_mg=120, fiber_g=1, sugar_g=32, cholesterol_mg=35
    ),
    "gulab_jamun": NutritionInfo(
        calories=380, protein_g=5, carbs_g=52, fat_g=18,
        sodium_mg=80, fiber_g=0, sugar_g=42, cholesterol_mg=25
    ),
    "aloo_gobi": NutritionInfo(
        calories=220, protein_g=5, carbs_g=28, fat_g=10,
        sodium_mg=420, fiber_g=5, sugar_g=4, cholesterol_mg=0
    ),
    "chicken_tikka_masala": NutritionInfo(
        calories=470, protein_g=30, carbs_g=15, fat_g=34,
        sodium_mg=900, fiber_g=2, sugar_g=6, cholesterol_mg=100
    ),
    "naan": NutritionInfo(
        calories=260, protein_g=8, carbs_g=45, fat_g=5,
        sodium_mg=520, fiber_g=2, sugar_g=3, cholesterol_mg=15
    ),
    "poha": NutritionInfo(
        calories=250, protein_g=5, carbs_g=42, fat_g=8,
        sodium_mg=320, fiber_g=3, sugar_g=2, cholesterol_mg=0
    ),
    "upma": NutritionInfo(
        calories=220, protein_g=6, carbs_g=35, fat_g=7,
        sodium_mg=380, fiber_g=3, sugar_g=1, cholesterol_mg=0
    ),
    "vada_pav": NutritionInfo(
        calories=350, protein_g=7, carbs_g=42, fat_g=18,
        sodium_mg=520, fiber_g=3, sugar_g=3, cholesterol_mg=5
    ),
    "thali_veg": NutritionInfo(
        calories=650, protein_g=20, carbs_g=85, fat_g=22,
        sodium_mg=1100, fiber_g=12, sugar_g=8, cholesterol_mg=20
    ),
    "egg_curry": NutritionInfo(
        calories=280, protein_g=18, carbs_g=10, fat_g=20,
        sodium_mg=580, fiber_g=2, sugar_g=3, cholesterol_mg=380
    ),
    "mutton_curry": NutritionInfo(
        calories=420, protein_g=32, carbs_g=8, fat_g=30,
        sodium_mg=750, fiber_g=2, sugar_g=2, cholesterol_mg=110
    ),
}

# Food classification labels matching model output indices
FOOD_LABELS = list(INDIAN_FOOD_DB.keys())

# Spike factor thresholds based on medical conditions
CONDITION_THRESHOLDS = {
    "hypertension": {
        "sodium_mg": {"threshold": 500, "severity": "high",
                      "warning": "High sodium content. Not recommended for hypertension patients. Target <1500mg/day."},
        "cholesterol_mg": {"threshold": 80, "severity": "medium",
                           "warning": "Elevated cholesterol. Monitor intake carefully."},
    },
    "diabetes": {
        "sugar_g": {"threshold": 10, "severity": "high",
                    "warning": "High sugar content. May cause blood glucose spike. Monitor closely."},
        "carbs_g": {"threshold": 50, "severity": "medium",
                    "warning": "High carbohydrate content. Consider portion control."},
    },
    "heart_disease": {
        "fat_g": {"threshold": 20, "severity": "high",
                  "warning": "High fat content. Increases cardiovascular strain."},
        "sodium_mg": {"threshold": 500, "severity": "high",
                      "warning": "High sodium content. Can elevate blood pressure."},
        "cholesterol_mg": {"threshold": 60, "severity": "high",
                           "warning": "High cholesterol. Limit to <200mg/day."},
    },
    "obesity": {
        "calories": {"threshold": 400, "severity": "high",
                     "warning": "High calorie meal. Consider a lighter alternative."},
        "fat_g": {"threshold": 20, "severity": "medium",
                  "warning": "High fat content. Opt for grilled/baked options."},
    },
    "kidney_disease": {
        "sodium_mg": {"threshold": 400, "severity": "high",
                      "warning": "High sodium. Kidney patients should limit to <1000mg/day."},
        "protein_g": {"threshold": 25, "severity": "medium",
                      "warning": "High protein. May increase kidney workload."},
    },
}

# Alternative food suggestions based on conditions
ALTERNATIVES = {
    "hypertension": ["Idli Sambar (low sodium)", "Roti with Aloo Gobi", "Poha (light)", "Upma"],
    "diabetes": ["Roti Sabzi (low carb)", "Tandoori Chicken (no cream)", "Palak Paneer (small portion)", "Fish Curry"],
    "heart_disease": ["Idli Sambar", "Roti Sabzi", "Fish Curry (grilled)", "Poha"],
    "obesity": ["Idli Sambar", "Upma", "Tandoori Chicken", "Aloo Gobi"],
    "kidney_disease": ["Poha", "Roti Sabzi", "Aloo Gobi", "Rice with light dal"],
}


async def classify_food_with_gemini(image_bytes: bytes, mime_type: str = "image/jpeg") -> tuple[str, float, Optional[NutritionInfo]]:
    """
    Sends the image to Gemini 1.5 Flash for vision parsing.
    Returns (food_name, confidence, custom_nutrition).
    """
    # Force mime_type to bypass Flutter Web octet-stream generic types
    if not mime_type.startswith("image/"):
        mime_type = "image/jpeg"
        
    api_key = os.getenv("GEMINI_API_KEY", "AIzaSyAz8qiFUvfNIOyOGbuGdGj-xZOZ574kFYc")
    if not api_key:
        print("GEMINI_API_KEY missing, using random mock.")
        food = random.choice(FOOD_LABELS)
        return food, round(random.uniform(0.72, 0.97), 2), None
        
    try:
        b64_img = base64.b64encode(image_bytes).decode('utf-8')
        prompt = (
            "You are a clinical nutritionist AI. Look at this food image and identify it. "
            "Return a STRICT JSON dictionary exactly like this, no markdown wrappers: "
            '{"name": "Apple", "confidence": 0.95, "calories": 95, "protein_g": 0.5, "carbs_g": 25.0, '
            '"fat_g": 0.3, "sodium_mg": 2.0, "fiber_g": 4.4, "sugar_g": 19.0, "cholesterol_mg": 0.0}'
        )
        payload = {
            "contents": [{"parts": [{"text": prompt}, {"inline_data": {"mime_type": mime_type, "data": b64_img}}]}]
            , "generationConfig": {"temperature": 0.1, "responseMimeType": "application/json"}
        }
        
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.post(
                f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key={api_key.strip()}",
                json=payload
            )
            if resp.status_code == 200:
                data = resp.json()
                text = data["candidates"][0]["content"]["parts"][0]["text"]
                clean_text = text.replace('```json', '').replace('```', '').strip()
                parsed = json.loads(clean_text)
                
                nut_info = NutritionInfo(
                    calories=parsed.get("calories", 0),
                    protein_g=parsed.get("protein_g", 0.0),
                    carbs_g=parsed.get("carbs_g", 0.0),
                    fat_g=parsed.get("fat_g", 0.0),
                    sodium_mg=parsed.get("sodium_mg", 0.0),
                    fiber_g=parsed.get("fiber_g", 0.0),
                    sugar_g=parsed.get("sugar_g", 0.0),
                    cholesterol_mg=parsed.get("cholesterol_mg", 0.0),
                )
                return parsed.get("name", "Unknown Food"), parsed.get("confidence", 0.9), nut_info
            else:
                return f"API Error: {resp.status_code} - {resp.text[:50]}", 0.0, None
            
    except Exception as e:
        return f"Code Error: {str(e)}", 0.0, None


def analyze_food(
    food_name: str,
    confidence: float,
    user_conditions: list[str],
    custom_nutrition: Optional[NutritionInfo] = None
) -> FoodAnalysisResult:
    """
    Analyze detected food against user's medical conditions.
    Generates spike factor warnings and alternative suggestions.
    """
    if custom_nutrition:
        nutrition = custom_nutrition
    else:
        nutrition = INDIAN_FOOD_DB.get(
            food_name.lower().replace(" ", "_"),
            NutritionInfo(calories=300, protein_g=10, carbs_g=40, fat_g=12,
                          sodium_mg=400, fiber_g=3, sugar_g=5, cholesterol_mg=30)
        )
    
    spike_factors = []
    is_suitable = True
    alt_suggestions = set()
    
    for condition in user_conditions:
        condition_lower = condition.lower()
        thresholds = CONDITION_THRESHOLDS.get(condition_lower, {})
        
        for nutrient, rules in thresholds.items():
            actual_value = getattr(nutrition, nutrient, 0)
            if actual_value > rules["threshold"]:
                spike_factors.append(SpikeFactor(
                    nutrient=nutrient,
                    value=actual_value,
                    threshold=rules["threshold"],
                    severity=rules["severity"],
                    warning=rules["warning"],
                ))
                if rules["severity"] == "high":
                    is_suitable = False
        
        # Add alternatives for this condition
        alts = ALTERNATIVES.get(condition_lower, [])
        alt_suggestions.update(alts)
    
    # Remove the current food from alternatives
    display_name = food_name.replace("_", " ").title()
    alt_suggestions.discard(display_name)
    
    return FoodAnalysisResult(
        food_name=display_name,
        confidence=confidence,
        nutrition=nutrition,
        spike_factors=spike_factors,
        is_suitable=is_suitable,
        alternative_suggestions=list(alt_suggestions)[:5],
    )
