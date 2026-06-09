"""
Care 2.0 API Server — Configuration
"""
import os
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""
    
    # App
    APP_NAME: str = "Care 2.0 API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True
    
    # Firebase
    FIREBASE_CREDENTIALS_PATH: str = os.path.join(
        os.path.dirname(__file__), "..", "firebase_credentials.json"
    )
    FIREBASE_STORAGE_BUCKET: str = "care2-app.appspot.com"
    
    # OpenWeatherMap
    OPENWEATHERMAP_API_KEY: str = "demo_key_replace_me"
    
    # Google Maps / Places
    GOOGLE_MAPS_API_KEY: str = "demo_key_replace_me"
    
    # ML Model Paths
    FOOD_MODEL_PATH: str = os.path.join(
        os.path.dirname(__file__), "ml", "models", "food_classifier.pkl"
    )
    RISK_MODEL_PATH: str = os.path.join(
        os.path.dirname(__file__), "ml", "models", "risk_model.pkl"
    )
    
    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8005
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache()
def get_settings() -> Settings:
    return Settings()
