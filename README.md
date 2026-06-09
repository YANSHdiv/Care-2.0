# Care 2.0 — Preventive Health Ecosystem

> Moving from reactive treatment to proactive prevention through a context-aware health platform.

## 🏗️ Architecture

```
care2/
├── apps/care2_app/          # Flutter cross-platform app (iOS, Android, Windows)
├── services/api_server/     # Python FastAPI backend
└── ml/                      # ML training scripts
```

## 🚀 Quick Start

### Backend (FastAPI)

```bash
cd services/api_server
pip install -r requirements.txt
python -m uvicorn app.main:app --reload --port 8000
```

Visit: http://localhost:8000/docs for Swagger UI

### Train ML Model (Optional)

```bash
cd ml/risk_prediction
pip install xgboost scikit-learn pandas numpy joblib
python train_xgboost.py
```

### Flutter App

```bash
cd apps/care2_app
flutter pub get
flutter run -d windows    # or: flutter run -d chrome
```

## 🔌 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/profile/` | Create user medical profile |
| GET | `/api/v1/profile/{uid}` | Get user profile |
| PUT | `/api/v1/profile/{uid}` | Update user profile |
| POST | `/api/v1/profile/ocr/parse` | Parse medical report (OCR) |
| GET | `/api/v1/environment/aqi` | Get AQI & weather data |
| POST | `/api/v1/environment/recommendation` | Exercise recommendation |
| POST | `/api/v1/nutrition/analyze` | Analyze food image |
| GET | `/api/v1/nutrition/history/{uid}` | Meal history |
| GET | `/api/v1/nutrition/database` | Indian food database |
| POST | `/api/v1/prediction/analyze` | 30-day health risk analysis |
| GET | `/api/v1/prediction/report/{uid}` | Latest risk report |
| POST | `/api/v1/prediction/demo/{uid}` | Generate demo report |
| GET | `/api/v1/nearby/care` | Find nearby hospitals |

## 🧠 Features

### A. Multimodal Onboarding
- Multi-step form: Biometrics → Genetic Risk Map → Clinical History
- OCR-based medical report parsing
- Firestore User_Medical_Profile document

### B. Environmental-Biometric Sync ("Delhi Logic")
- Real-time AQI via OpenWeatherMap
- Constraint engine overrides outdoor exercise when:
  - AQI ≥ 4 (Poor/Very Poor)
  - AQI ≥ 3 for sensitive individuals
  - Rain/Thunderstorm/extreme temps

### C. Computer Vision Nutrition Pipeline
- Camera → CNN food classification (TFLite MobileNetV2)
- 25-item Indian food nutrition database
- Spike factor detection against medical conditions
- Real-time warnings + healthier alternatives

### D. 30-Day Predictive Dashboard
- Heart Rate, Steps, SpO₂, Sleep trend charts
- XGBoost-based risk classifier (trained on synthetic data)
- Color-coded risk categories (Green/Amber/Red)
- Healthspan trajectory projection

### E. Nearby Care
- Risk-profile-aware hospital/clinic finder
- Specialty matching with relevance scoring
- Haversine distance calculation

## 🎨 Design System

- **Theme**: Clinical dark mode with glassmorphism
- **Primary**: Emerald Green (#00E5A0)
- **Secondary**: Deep Purple (#7C4DFF)
- **Font**: Inter (Google Fonts)
- **Animations**: Animated risk gauges, chart transitions

## ⚙️ Environment Variables

Copy `.env` in `services/api_server/` and fill:
- `OPENWEATHERMAP_API_KEY` — for AQI data
- `GOOGLE_MAPS_API_KEY` — for nearby care
- `FIREBASE_CREDENTIALS_PATH` — for Firestore

## 📄 License

MIT
