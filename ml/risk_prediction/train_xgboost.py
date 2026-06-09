"""
Care 2.0 — XGBoost Health Risk Model Training Script

Trains an XGBoost classifier on synthetic health data to predict
risk categories: Healthy (0), At Risk (1), Critical (2).

Features:
- avg_heart_rate, max_heart_rate, heart_rate_variability
- avg_spo2, min_spo2, spo2_below_95_pct
- avg_daily_steps, step_trend
- avg_sleep_hours, sleep_consistency
- age, bmi
- genetic_risk_cardiac, genetic_risk_diabetes, genetic_risk_respiratory

Usage: python train_xgboost.py
"""
import numpy as np
import pandas as pd
from xgboost import XGBClassifier
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import classification_report, confusion_matrix
import joblib
import os


def generate_synthetic_data(n_samples: int = 3000) -> pd.DataFrame:
    """Generate synthetic health data for model training."""
    np.random.seed(42)
    
    data = []
    for _ in range(n_samples):
        # Randomly assign a true risk category
        true_risk = np.random.choice([0, 1, 2], p=[0.5, 0.35, 0.15])
        
        if true_risk == 0:  # Healthy
            avg_hr = np.random.normal(70, 8)
            max_hr = np.random.normal(120, 15)
            hrv = np.random.normal(55, 10)
            avg_spo2 = np.random.normal(97.5, 0.8)
            min_spo2 = np.random.normal(96, 1.2)
            spo2_below_95 = np.random.uniform(0, 0.03)
            avg_steps = np.random.normal(8000, 2000)
            step_trend = np.random.normal(0.01, 0.02)
            avg_sleep = np.random.normal(7.5, 0.8)
            sleep_consistency = np.random.uniform(0.7, 1.0)
            age = np.random.randint(20, 55)
            bmi = np.random.normal(22, 2)
            gen_cardiac = np.random.choice([0, 1], p=[0.8, 0.2])
            gen_diabetes = np.random.choice([0, 1], p=[0.8, 0.2])
            gen_resp = np.random.choice([0, 1], p=[0.9, 0.1])
            
        elif true_risk == 1:  # At Risk
            avg_hr = np.random.normal(82, 10)
            max_hr = np.random.normal(140, 18)
            hrv = np.random.normal(38, 10)
            avg_spo2 = np.random.normal(96, 1.2)
            min_spo2 = np.random.normal(94, 2)
            spo2_below_95 = np.random.uniform(0.02, 0.12)
            avg_steps = np.random.normal(5000, 2000)
            step_trend = np.random.normal(-0.01, 0.03)
            avg_sleep = np.random.normal(6.5, 1.0)
            sleep_consistency = np.random.uniform(0.4, 0.8)
            age = np.random.randint(30, 65)
            bmi = np.random.normal(27, 3)
            gen_cardiac = np.random.choice([0, 1], p=[0.5, 0.5])
            gen_diabetes = np.random.choice([0, 1], p=[0.5, 0.5])
            gen_resp = np.random.choice([0, 1], p=[0.7, 0.3])
            
        else:  # Critical
            avg_hr = np.random.normal(95, 12)
            max_hr = np.random.normal(160, 20)
            hrv = np.random.normal(22, 8)
            avg_spo2 = np.random.normal(94, 1.5)
            min_spo2 = np.random.normal(91, 2.5)
            spo2_below_95 = np.random.uniform(0.1, 0.4)
            avg_steps = np.random.normal(2500, 1500)
            step_trend = np.random.normal(-0.04, 0.03)
            avg_sleep = np.random.normal(5.5, 1.2)
            sleep_consistency = np.random.uniform(0.2, 0.6)
            age = np.random.randint(40, 80)
            bmi = np.random.normal(31, 4)
            gen_cardiac = np.random.choice([0, 1], p=[0.3, 0.7])
            gen_diabetes = np.random.choice([0, 1], p=[0.3, 0.7])
            gen_resp = np.random.choice([0, 1], p=[0.5, 0.5])
        
        data.append({
            "avg_heart_rate": max(40, avg_hr),
            "max_heart_rate": max(60, max_hr),
            "heart_rate_variability": max(5, hrv),
            "avg_spo2": min(100, max(85, avg_spo2)),
            "min_spo2": min(100, max(80, min_spo2)),
            "spo2_below_95_pct": min(1, max(0, spo2_below_95)),
            "avg_daily_steps": max(100, int(avg_steps)),
            "step_trend": step_trend,
            "avg_sleep_hours": max(2, min(12, avg_sleep)),
            "sleep_consistency": max(0, min(1, sleep_consistency)),
            "age": age,
            "bmi": max(15, min(50, bmi)),
            "genetic_risk_cardiac": gen_cardiac,
            "genetic_risk_diabetes": gen_diabetes,
            "genetic_risk_respiratory": gen_resp,
            "risk_category": true_risk,
        })
    
    return pd.DataFrame(data)


def train_model():
    """Train XGBoost classifier and save model artifacts."""
    print("=" * 60)
    print("Care 2.0 — XGBoost Health Risk Model Training")
    print("=" * 60)
    
    # Generate data
    print("\n📊 Generating synthetic training data...")
    df = generate_synthetic_data(3000)
    print(f"   Samples: {len(df)}")
    print(f"   Class distribution:")
    for cat, count in df['risk_category'].value_counts().sort_index().items():
        labels = {0: "Healthy", 1: "At Risk", 2: "Critical"}
        print(f"     {labels[cat]}: {count} ({count/len(df)*100:.1f}%)")
    
    # Prepare features
    feature_cols = [
        "avg_heart_rate", "max_heart_rate", "heart_rate_variability",
        "avg_spo2", "min_spo2", "spo2_below_95_pct",
        "avg_daily_steps", "step_trend",
        "avg_sleep_hours", "sleep_consistency",
        "age", "bmi",
        "genetic_risk_cardiac", "genetic_risk_diabetes", "genetic_risk_respiratory",
    ]
    
    X = df[feature_cols]
    y = df["risk_category"]
    
    # Split
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    
    # Scale
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)
    
    # Train XGBoost
    print("\n🤖 Training XGBoost Classifier...")
    model = XGBClassifier(
        n_estimators=200,
        max_depth=6,
        learning_rate=0.1,
        subsample=0.8,
        colsample_bytree=0.8,
        min_child_weight=3,
        gamma=0.1,
        objective="multi:softprob",
        num_class=3,
        eval_metric="mlogloss",
        random_state=42,
        use_label_encoder=False,
    )
    
    model.fit(
        X_train_scaled, y_train,
        eval_set=[(X_test_scaled, y_test)],
        verbose=False,
    )
    
    # Evaluate
    print("\n📈 Model Evaluation:")
    y_pred = model.predict(X_test_scaled)
    
    print("\nClassification Report:")
    labels = {0: "Healthy", 1: "At Risk", 2: "Critical"}
    print(classification_report(y_test, y_pred, target_names=list(labels.values())))
    
    # Cross-validation
    cv_scores = cross_val_score(model, X_train_scaled, y_train, cv=5, scoring="accuracy")
    print(f"Cross-validation accuracy: {cv_scores.mean():.3f} ± {cv_scores.std():.3f}")
    
    # Feature importance
    print("\n🔍 Feature Importance (Top 10):")
    importance = dict(zip(feature_cols, model.feature_importances_))
    sorted_imp = sorted(importance.items(), key=lambda x: x[1], reverse=True)
    for feat, imp in sorted_imp[:10]:
        bar = "█" * int(imp * 50)
        print(f"   {feat:30s} {imp:.4f} {bar}")
    
    # Save models
    model_dir = os.path.join(os.path.dirname(__file__), "..", "services", "api_server", "app", "ml", "models")
    os.makedirs(model_dir, exist_ok=True)
    
    model_path = os.path.join(model_dir, "risk_model.pkl")
    scaler_path = os.path.join(model_dir, "scaler.pkl")
    
    joblib.dump(model, model_path)
    joblib.dump(scaler, scaler_path)
    
    print(f"\n✅ Model saved to: {model_path}")
    print(f"✅ Scaler saved to: {scaler_path}")
    print(f"\n{'=' * 60}")
    print("Training complete! Model ready for deployment.")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    train_model()
