"""
Care 2.0 — Weather & AQI Service
Integrates with OpenWeatherMap API for real-time environmental data.
"""
import httpx
from typing import Optional
from app.config import get_settings
from app.models.health import (
    EnvironmentData, ExerciseRecommendation, ExerciseActivity
)

settings = get_settings()

def get_aqi_label(aqi: int) -> str:
    if aqi <= 50: return "Good"
    if aqi <= 100: return "Moderate"
    if aqi <= 200: return "Poor"
    if aqi <= 300: return "Very Poor"
    return "Hazardous"

def get_weather_description(code: int) -> str:
    if code == 0: return "Clear"
    elif code in [1, 2, 3]: return "Clouds"
    elif code in [45, 48]: return "Fog"
    elif code in [51, 53, 55, 56, 57]: return "Drizzle"
    elif code in [61, 63, 65, 66, 67, 80, 81, 82]: return "Rain"
    elif code in [71, 73, 75, 77, 85, 86]: return "Snow"
    elif code in [95, 96, 99]: return "Thunderstorm"
    else: return "Clear"

# Indian food nutrition database for common foods
INDOOR_ACTIVITIES = [
    ExerciseActivity(
        name="Power Yoga",
        duration_min=30,
        intensity="medium",
        calories_burn_estimate=200,
        description="Sun salutations, warrior poses, and breathing exercises for core strength and flexibility."
    ),
    ExerciseActivity(
        name="Indoor HIIT Circuit",
        duration_min=20,
        intensity="high",
        calories_burn_estimate=250,
        description="Burpees, mountain climbers, jump squats, and plank variations. 40s work / 20s rest."
    ),
    ExerciseActivity(
        name="Bodyweight Strength Training",
        duration_min=25,
        intensity="medium",
        calories_burn_estimate=180,
        description="Push-ups, squats, lunges, and core exercises. 3 sets of 12 reps each."
    ),
    ExerciseActivity(
        name="Stretching & Meditation",
        duration_min=20,
        intensity="low",
        calories_burn_estimate=60,
        description="Full-body stretching routine followed by guided breathing meditation."
    ),
    ExerciseActivity(
        name="Indoor Cycling / Spot Jogging",
        duration_min=30,
        intensity="high",
        calories_burn_estimate=280,
        description="Stationary cycling or high-knee spot jogging with intervals."
    ),
]

OUTDOOR_ACTIVITIES = [
    ExerciseActivity(
        name="Morning Run",
        duration_min=30,
        intensity="high",
        calories_burn_estimate=300,
        description="Moderate-pace running in a park or open area. Maintain conversational pace."
    ),
    ExerciseActivity(
        name="Brisk Walking",
        duration_min=40,
        intensity="low",
        calories_burn_estimate=180,
        description="Walk at 5-6 km/h pace. Great for cardiovascular health without joint stress."
    ),
    ExerciseActivity(
        name="Cycling",
        duration_min=45,
        intensity="medium",
        calories_burn_estimate=350,
        description="Road cycling at moderate intensity. Excellent for leg strength and endurance."
    ),
    ExerciseActivity(
        name="Outdoor Calisthenics",
        duration_min=30,
        intensity="high",
        calories_burn_estimate=280,
        description="Pull-ups, dips, push-ups at a park gym. Full body compound movements."
    ),
    ExerciseActivity(
        name="Sports (Badminton / Cricket)",
        duration_min=60,
        intensity="medium",
        calories_burn_estimate=400,
        description="Recreational sports for cardiovascular fitness and social engagement."
    ),
]


async def fetch_environment_data(lat: float, lon: float) -> EnvironmentData:
    """
    Fetch real-time AQI, weather, and atmospheric data from Open-Meteo.
    Completely free and requires no API keys.
    Falls back to simulated data if the request fails.
    """
    try:
        async with httpx.AsyncClient(timeout=8.0) as client:
            weather_url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m"
            aqi_url = f"https://air-quality-api.open-meteo.com/v1/air-quality?latitude={lat}&longitude={lon}&current=pm10,pm2_5,us_aqi"
            
            w_resp = await client.get(weather_url)
            a_resp = await client.get(aqi_url)
            
            if w_resp.status_code == 200 and a_resp.status_code == 200:
                w_data = w_resp.json()["current"]
                a_data = a_resp.json()["current"]
                
                aqi = int(a_data.get("us_aqi", 50))
                weather_code = w_data.get("weather_code", 0)
                weather_str = get_weather_description(weather_code)
                
                return EnvironmentData(
                    latitude=lat,
                    longitude=lon,
                    aqi=aqi,
                    aqi_label=get_aqi_label(aqi),
                    temperature_c=w_data.get("temperature_2m", 25.0),
                    humidity=int(w_data.get("relative_humidity_2m", 50)),
                    weather_main=weather_str,
                    weather_description=weather_str,
                    wind_speed=w_data.get("wind_speed_10m", 0.0),
                    pm25=a_data.get("pm2_5", 0.0),
                    pm10=a_data.get("pm10", 0.0),
                )
    except Exception as e:
        print(f"Open-Meteo fallback triggered: {e}")
        
    return _get_simulated_environment(lat, lon)


def _get_simulated_environment(lat: float, lon: float) -> EnvironmentData:
    """
    Simulate environment data based on location heuristics.
    Delhi (28.6°N, 77.2°E) typically has high AQI;
    Coastal/rural areas have lower AQI.
    """
    import random
    
    # Simulate Delhi-like high pollution
    is_delhi_region = (28.0 <= lat <= 29.0 and 76.5 <= lon <= 77.5)
    is_mumbai_region = (18.8 <= lat <= 19.3 and 72.5 <= lon <= 73.0)
    
    if is_delhi_region:
        aqi = random.randint(250, 450)
        temp = round(random.uniform(25, 42), 1)
    elif is_mumbai_region:
        aqi = random.randint(100, 250)
        temp = round(random.uniform(26, 35), 1)
    else:
        aqi = random.randint(20, 150)
        temp = round(random.uniform(20, 35), 1)
    
    weather_options = ["Clear", "Clouds", "Haze", "Rain", "Mist"]
    weather = random.choice(weather_options)
    
    pm25 = float(aqi) if aqi > 50 else round(random.uniform(5, 50), 1)
    pm10 = round(pm25 * 1.5, 1)

    return EnvironmentData(
        latitude=lat,
        longitude=lon,
        aqi=aqi,
        aqi_label=get_aqi_label(aqi),
        temperature_c=temp,
        humidity=random.randint(30, 90),
        weather_main=weather,
        weather_description=f"{weather.lower()} skies",
        wind_speed=round(random.uniform(1, 15), 1),
        pm25=pm25,
        pm10=pm10,
    )


def get_exercise_recommendation(
    user_conditions: list[str],
    current_aqi: int,
    weather: str,
    temperature: float
) -> ExerciseRecommendation:
    """
    Constraint Engine — The "Delhi Logic"
    
    Determines whether exercise should be indoor or outdoor based on:
    1. AQI levels (Poor/Very Poor → indoor)
    2. Weather conditions (Rain/Thunderstorm → indoor)
    3. Temperature extremes (>40°C or <5°C → indoor)
    4. User sensitivity (asthma/COPD patients have lower thresholds)
    
    Returns personalized activity recommendations with durations and intensities.
    """
    is_sensitive = any(
        c.lower() in ["asthma", "copd", "heart_disease", "bronchitis", "respiratory"]
        for c in user_conditions
    )
    
    reasons = []
    warnings = []
    
    # Check AQI - Exceeding 300 is dangerous
    aqi_threshold = 200 if is_sensitive else 300
    if current_aqi >= aqi_threshold:
        reasons.append(
            f"AQI is {get_aqi_label(current_aqi)} ({current_aqi})"
            + (" — you have respiratory sensitivity" if is_sensitive else "")
        )
        if current_aqi >= 300:
            warnings.append("⚠️ Hazardous air quality. Limit all outdoor exposure.")
    
    # Check weather
    bad_weather = ["rain", "thunderstorm", "drizzle", "tornado", "squall"]
    if weather.lower() in bad_weather:
        reasons.append(f"Weather condition: {weather}. Outdoor exercise not safe.")
    
    # Check temperature
    if temperature > 40:
        reasons.append(f"Extreme heat ({temperature}°C). Risk of heat stroke.")
        warnings.append("🌡️ Stay hydrated. Avoid direct sun exposure.")
    elif temperature < 5:
        reasons.append(f"Extreme cold ({temperature}°C). Risk of hypothermia.")
        warnings.append("🥶 Layer up if stepping out. Protect extremities.")
    
    force_indoor = len(reasons) > 0
    
    if force_indoor:
        return ExerciseRecommendation(
            mode="indoor",
            reason=" | ".join(reasons),
            aqi_level=current_aqi,
            weather=weather,
            temperature=temperature,
            activities=INDOOR_ACTIVITIES,
            warnings=warnings,
        )
    else:
        return ExerciseRecommendation(
            mode="outdoor",
            reason=f"Conditions are favorable! AQI: {get_aqi_label(current_aqi)}, Temp: {temperature}°C, Weather: {weather}",
            aqi_level=current_aqi,
            weather=weather,
            temperature=temperature,
            activities=OUTDOOR_ACTIVITIES,
            warnings=[],
        )
