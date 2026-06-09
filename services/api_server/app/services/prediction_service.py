"""
Care 2.0 — Health Risk Prediction Service
XGBoost-based 30-day health risk prediction engine.
"""
import numpy as np
import os
from typing import Optional
from app.models.health import (
    ThirtyDayData, RiskPrediction, RiskCategory, DailyHealthMetrics
)

# Try to load trained model; fall back to rule-based prediction
_model = None
_scaler = None

def _try_load_model():
    global _model, _scaler
    try:
        import joblib
        model_path = os.path.join(os.path.dirname(__file__), "..", "ml", "models", "risk_model.pkl")
        scaler_path = os.path.join(os.path.dirname(__file__), "..", "ml", "models", "scaler.pkl")
        if os.path.exists(model_path):
            _model = joblib.load(model_path)
            if os.path.exists(scaler_path):
                _scaler = joblib.load(scaler_path)
    except Exception:
        _model = None
        _scaler = None

_try_load_model()


def _engineer_features(data: ThirtyDayData) -> dict:
    """
    Engineer features from 30-day wearable data.
    Aggregates time-series metrics into model-ready features.
    """
    metrics = data.metrics
    
    if not metrics:
        # Return defaults
        return {
            "avg_heart_rate": 72, "max_heart_rate": 100,
            "heart_rate_variability": 50, "avg_spo2": 97,
            "min_spo2": 95, "spo2_below_95_pct": 0,
            "avg_daily_steps": 5000, "step_trend": 0,
            "avg_sleep_hours": 7, "sleep_consistency": 0.8,
            "age": data.age, "bmi": data.bmi,
            "genetic_risk_cardiac": data.genetic_risk_cardiac,
            "genetic_risk_diabetes": data.genetic_risk_diabetes,
            "genetic_risk_respiratory": data.genetic_risk_respiratory,
        }
    
    hr_values = [m.avg_heart_rate for m in metrics]
    max_hr_values = [m.max_heart_rate for m in metrics]
    hrv_values = [m.heart_rate_variability for m in metrics]
    spo2_values = [m.avg_spo2 for m in metrics]
    min_spo2_values = [m.min_spo2 for m in metrics]
    step_values = [m.daily_steps for m in metrics]
    sleep_values = [m.sleep_hours for m in metrics]
    
    # Calculate step trend (linear regression slope)
    if len(step_values) >= 7:
        x = np.arange(len(step_values))
        coeffs = np.polyfit(x, step_values, 1)
        step_trend = coeffs[0] / (np.mean(step_values) + 1)  # normalized slope
    else:
        step_trend = 0
    
    # SpO2 below 95% percentage
    spo2_below_95 = sum(1 for s in min_spo2_values if s < 95) / len(min_spo2_values) if min_spo2_values else 0
    
    # Sleep consistency (standard deviation)
    sleep_std = np.std(sleep_values) if len(sleep_values) > 1 else 0
    sleep_consistency = max(0, 1 - (sleep_std / 3))  # normalized 0-1
    
    return {
        "avg_heart_rate": np.mean(hr_values),
        "max_heart_rate": np.max(max_hr_values),
        "heart_rate_variability": np.mean(hrv_values),
        "avg_spo2": np.mean(spo2_values),
        "min_spo2": np.min(min_spo2_values),
        "spo2_below_95_pct": spo2_below_95,
        "avg_daily_steps": np.mean(step_values),
        "step_trend": step_trend,
        "avg_sleep_hours": np.mean(sleep_values),
        "sleep_consistency": sleep_consistency,
        "age": data.age,
        "bmi": data.bmi,
        "genetic_risk_cardiac": data.genetic_risk_cardiac,
        "genetic_risk_diabetes": data.genetic_risk_diabetes,
        "genetic_risk_respiratory": data.genetic_risk_respiratory,
    }


def _rule_based_prediction(features: dict) -> RiskPrediction:
    """
    Rule-based risk prediction fallback when no trained model is available.
    Uses clinical guidelines and heuristics for risk scoring.
    """
    cardiac_risk = 0.0
    respiratory_risk = 0.0
    metabolic_risk = 0.0
    concerns = []
    recommendations = []
    
    # ── Cardiac Risk Scoring ──
    # Heart rate
    if features["avg_heart_rate"] > 100:
        cardiac_risk += 0.25
        concerns.append(f"Elevated resting heart rate ({features['avg_heart_rate']:.0f} bpm). Normal: 60-100 bpm.")
    elif features["avg_heart_rate"] > 85:
        cardiac_risk += 0.10
    
    # HRV (low HRV = higher cardiac risk)
    if features["heart_rate_variability"] < 20:
        cardiac_risk += 0.20
        concerns.append("Very low heart rate variability — indicates cardiac stress.")
    elif features["heart_rate_variability"] < 35:
        cardiac_risk += 0.10
    
    # Genetic risk
    if features["genetic_risk_cardiac"]:
        cardiac_risk += 0.15
        concerns.append("Family history of cardiac conditions increases baseline risk.")
    
    # Steps (sedentary lifestyle)
    if features["avg_daily_steps"] < 3000:
        cardiac_risk += 0.15
        concerns.append(f"Very low activity level ({features['avg_daily_steps']:.0f} steps/day). Recommend 8000+.")
        recommendations.append("Increase daily steps to at least 5000, ideally 8000+.")
    elif features["avg_daily_steps"] < 5000:
        cardiac_risk += 0.08
        recommendations.append("Increase daily steps to 8000+ for optimal cardiovascular health.")
    
    # Step trend
    if features["step_trend"] < -0.03:
        cardiac_risk += 0.08
        concerns.append(f"Declining activity trend over 30 days ({features['step_trend']*100:.1f}% decline).")
    
    # ── Respiratory Risk Scoring ──
    if features["avg_spo2"] < 95:
        respiratory_risk += 0.30
        concerns.append(f"Average SpO2 below normal ({features['avg_spo2']:.1f}%). Normal: >95%.")
        recommendations.append("Consult a pulmonologist. Low SpO2 may indicate respiratory issues.")
    elif features["avg_spo2"] < 96:
        respiratory_risk += 0.12
    
    if features["spo2_below_95_pct"] > 0.1:
        respiratory_risk += 0.20
        concerns.append(f"SpO2 dropped below 95% in {features['spo2_below_95_pct']*100:.0f}% of readings.")
    
    if features["genetic_risk_respiratory"]:
        respiratory_risk += 0.15
    
    # ── Metabolic Risk Scoring ──
    if features["bmi"] > 30:
        metabolic_risk += 0.25
        concerns.append(f"BMI {features['bmi']:.1f} indicates obesity. Target: 18.5-24.9.")
        recommendations.append("Focus on calorie deficit and regular cardio exercise.")
    elif features["bmi"] > 25:
        metabolic_risk += 0.12
        concerns.append(f"BMI {features['bmi']:.1f} indicates overweight.")
    elif features["bmi"] < 18.5:
        metabolic_risk += 0.10
        concerns.append(f"BMI {features['bmi']:.1f} indicates underweight.")
    
    if features["genetic_risk_diabetes"]:
        metabolic_risk += 0.20
        concerns.append("Family history of diabetes increases metabolic risk.")
        recommendations.append("Schedule HbA1c blood test within 2 weeks.")
    
    # Sleep
    if features["avg_sleep_hours"] < 6:
        metabolic_risk += 0.15
        cardiac_risk += 0.08
        concerns.append(f"Insufficient sleep ({features['avg_sleep_hours']:.1f} hrs). Recommend 7-9 hours.")
        recommendations.append("Target 7+ hours of consistent sleep.")
    elif features["avg_sleep_hours"] < 7:
        metabolic_risk += 0.05
    
    if features["sleep_consistency"] < 0.5:
        metabolic_risk += 0.08
        concerns.append("Irregular sleep patterns detected. Sleep inconsistency affects metabolism.")
    
    # Age factor
    if features["age"] > 50:
        cardiac_risk += 0.10
        metabolic_risk += 0.08
    elif features["age"] > 40:
        cardiac_risk += 0.05
        metabolic_risk += 0.05
    
    # Clamp risks to [0, 1]
    cardiac_risk = min(1.0, cardiac_risk)
    respiratory_risk = min(1.0, respiratory_risk)
    metabolic_risk = min(1.0, metabolic_risk)
    
    # Overall risk score (weighted average)
    overall = int(((cardiac_risk * 0.4) + (respiratory_risk * 0.3) + (metabolic_risk * 0.3)) * 100)
    overall = min(100, max(0, overall))
    
    # Category
    if overall <= 30:
        category = RiskCategory.HEALTHY
    elif overall <= 60:
        category = RiskCategory.AT_RISK
    else:
        category = RiskCategory.CRITICAL
    
    # Add general recommendations
    if not recommendations:
        recommendations.append("Continue maintaining your current healthy lifestyle!")
    recommendations.append("Regular health check-ups every 6 months are advisable.")
    
    # Healthspan trajectory (3-month projection)
    trajectory = []
    projected_score = overall
    for month in range(1, 4):
        # Simple projection: if steps trending up → improving, else degrading
        if features["step_trend"] > 0:
            projected_score = max(0, projected_score - 3)
        else:
            projected_score = min(100, projected_score + 2)
        trajectory.append({
            "month": month,
            "projected_score": projected_score,
            "label": f"Month {month}"
        })
    
    return RiskPrediction(
        overall_risk_score=overall,
        cardiac_risk=round(cardiac_risk, 2),
        respiratory_risk=round(respiratory_risk, 2),
        metabolic_risk=round(metabolic_risk, 2),
        risk_category=category,
        top_concerns=concerns[:5],
        recommendations=recommendations[:5],
        healthspan_trajectory=trajectory,
    )


def predict_health_risk(data: ThirtyDayData) -> RiskPrediction:
    """
    Main prediction entry point.
    Uses trained XGBoost model if available, otherwise falls back to rule-based.
    """
    features = _engineer_features(data)
    
    if _model is not None:
        try:
            feature_array = np.array([[
                features["avg_heart_rate"],
                features["max_heart_rate"],
                features["heart_rate_variability"],
                features["avg_spo2"],
                features["min_spo2"],
                features["spo2_below_95_pct"],
                features["avg_daily_steps"],
                features["step_trend"],
                features["avg_sleep_hours"],
                features["sleep_consistency"],
                features["age"],
                features["bmi"],
                features["genetic_risk_cardiac"],
                features["genetic_risk_diabetes"],
                features["genetic_risk_respiratory"],
            ]])
            
            if _scaler:
                feature_array = _scaler.transform(feature_array)
            
            prediction = _model.predict(feature_array)[0]
            probabilities = _model.predict_proba(feature_array)[0]
            
            # Map model output to risk prediction
            # Model classes: 0=healthy, 1=at_risk, 2=critical
            categories = [RiskCategory.HEALTHY, RiskCategory.AT_RISK, RiskCategory.CRITICAL]
            category = categories[int(prediction)]
            overall_score = int(probabilities[1] * 40 + probabilities[2] * 80)
            
            # Still use rule-based for detailed concerns/recommendations
            rule_based = _rule_based_prediction(features)
            
            return RiskPrediction(
                overall_risk_score=overall_score,
                cardiac_risk=rule_based.cardiac_risk,
                respiratory_risk=rule_based.respiratory_risk,
                metabolic_risk=rule_based.metabolic_risk,
                risk_category=category,
                top_concerns=rule_based.top_concerns,
                recommendations=rule_based.recommendations,
                healthspan_trajectory=rule_based.healthspan_trajectory,
            )
        except Exception:
            pass
    
    # Fallback to rule-based
    return _rule_based_prediction(features)
