"""
Care 2.0 API Server — Main Application Entry Point

A high-performance FastAPI backend for the Care 2.0 preventive health ecosystem.
Provides endpoints for:
- User medical profile management (CRUD + OCR)
- Environmental-biometric sync (AQI + exercise recommendations)
- Computer vision nutrition pipeline (food analysis + spike factors)
- 30-day predictive health dashboard (XGBoost risk model)
- Nearby care facility finder (risk-profile aware)
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import get_settings
from app.routers import profile, environment, nutrition, prediction, nearby, auth

settings = get_settings()

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="""
    ## Care 2.0 — Context-Aware Preventive Health API
    
    Moving from reactive treatment to proactive prevention through
    environmental awareness, nutritional intelligence, and predictive analytics.
    
    ### Key Features
    - **Multimodal Onboarding** — Biometrics, genetic mapping, OCR report parsing
    - **Delhi Logic Engine** — AQI-aware exercise recommendations
    - **Nutrition Pipeline** — Indian food classification with medical spike detection
    - **Predictive Analytics** — 30-day XGBoost health risk forecasting
    - **Nearby Care** — Risk-profile filtered hospital/clinic finder
    """,
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS — Allow Flutter apps to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, restrict to specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(auth.router)
app.include_router(profile.router)
app.include_router(environment.router)
app.include_router(nutrition.router)
app.include_router(prediction.router)
app.include_router(nearby.router)


@app.get("/", tags=["Health"])
async def root():
    return {
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "status": "operational",
        "docs": "/docs",
        "endpoints": {
            "profile": "/api/v1/profile",
            "environment": "/api/v1/environment",
            "nutrition": "/api/v1/nutrition",
            "prediction": "/api/v1/prediction",
            "nearby": "/api/v1/nearby",
        }
    }


@app.get("/health", tags=["Health"])
async def health_check():
    return {"status": "healthy", "version": settings.APP_VERSION}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
    )
