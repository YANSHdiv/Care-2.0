"""
Care 2.0 — Prediction Router
30-day health risk prediction and reporting endpoints.
"""
from fastapi import APIRouter, HTTPException
from app.models.health import ThirtyDayData, DailyHealthMetrics
from app.services.prediction_service import predict_health_risk
from app.services import firebase_service
import random

router = APIRouter(prefix="/api/v1/prediction", tags=["Prediction"])


@router.post("/analyze")
async def analyze_health_risk(data: ThirtyDayData):
    """
    Analyze 30 days of wearable health data and generate a risk report.
    
    Uses XGBoost classifier (when trained model available) or
    rule-based clinical heuristics to predict:
    - Overall risk score (0-100)
    - Cardiac, respiratory, and metabolic risk scores
    - Risk category (Healthy / At Risk / Critical)
    - Specific concerns and actionable recommendations
    - 3-month healthspan trajectory projection
    """
    if len(data.metrics) < 7:
        raise HTTPException(
            status_code=400,
            detail="At least 7 days of health data required for meaningful analysis. 30 days recommended."
        )
    
    # Run prediction
    prediction = predict_health_risk(data)
    
    # Save report
    await firebase_service.save_risk_report(data.uid, prediction.model_dump())
    
    return prediction.model_dump()


@router.get("/report/{uid}")
async def get_latest_report(uid: str):
    """Get the most recent risk prediction report for a user."""
    report = await firebase_service.get_latest_risk_report(uid)
    if not report:
        raise HTTPException(
            status_code=404,
            detail="No risk report found. Complete 30 days of health tracking first."
        )
    return report


@router.post("/demo/{uid}")
async def generate_demo_report(uid: str):
    """
    Generate a demo risk report with simulated 30-day data.
    Useful for testing and demonstration purposes.
    """
    # Generate 30 days of simulated wearable data
    metrics = []
    for day in range(30):
        metrics.append(DailyHealthMetrics(
            date=f"2026-03-{day+1:02d}",
            avg_heart_rate=round(random.gauss(75, 8), 1),
            max_heart_rate=round(random.gauss(130, 15), 1),
            min_heart_rate=round(random.gauss(58, 5), 1),
            heart_rate_variability=round(random.gauss(45, 12), 1),
            avg_spo2=round(random.gauss(97, 1.2), 1),
            min_spo2=round(random.gauss(94, 2), 1),
            daily_steps=int(random.gauss(6000, 2000)),
            sleep_hours=round(random.gauss(6.8, 1.2), 1),
        ))
    
    # Get user profile for genetic risks
    profile = await firebase_service.get_user_profile(uid)
    genetic_cardiac = 0
    genetic_diabetes = 0
    genetic_resp = 0
    age = 30
    bmi = 24.0
    
    if profile:
        bio = profile.get("biometrics", {})
        age = bio.get("age", 30)
        bmi = bio.get("bmi", 24.0)
        genetic = profile.get("genetic_risks", {})
        all_conditions = []
        for relative_conditions in genetic.values():
            if isinstance(relative_conditions, list):
                all_conditions.extend(relative_conditions)
        genetic_cardiac = 1 if any("heart" in c for c in all_conditions) else 0
        genetic_diabetes = 1 if any("diabetes" in c for c in all_conditions) else 0
        genetic_resp = 1 if any("asthma" in c or "respiratory" in c for c in all_conditions) else 0
    
    data = ThirtyDayData(
        uid=uid,
        metrics=metrics,
        age=age,
        bmi=bmi,
        genetic_risk_cardiac=genetic_cardiac,
        genetic_risk_diabetes=genetic_diabetes,
        genetic_risk_respiratory=genetic_resp,
    )
    
    prediction = predict_health_risk(data)
    await firebase_service.save_risk_report(uid, prediction.model_dump())
    
    return {
        "report": prediction.model_dump(),
        "data_summary": {
            "days_tracked": 30,
            "avg_steps": sum(m.daily_steps for m in metrics) // 30,
            "avg_heart_rate": round(sum(m.avg_heart_rate for m in metrics) / 30, 1),
            "avg_spo2": round(sum(m.avg_spo2 for m in metrics) / 30, 1),
            "avg_sleep": round(sum(m.sleep_hours for m in metrics) / 30, 1),
        }
    }
