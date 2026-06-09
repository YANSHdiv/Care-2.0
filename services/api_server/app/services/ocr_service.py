"""
Care 2.0 — OCR Service for Medical Report Parsing
Simulated OCR extraction from medical report PDFs.
"""
from typing import Optional
import random


# Common medical conditions that might be found in reports
DETECTABLE_CONDITIONS = [
    "hypertension", "diabetes_type2", "diabetes_type1",
    "asthma", "thyroid_disorder", "anemia",
    "vitamin_d_deficiency", "vitamin_b12_deficiency",
    "high_cholesterol", "fatty_liver", "kidney_stones",
    "migraine", "arthritis", "pcod", "anxiety",
]

# Simulated medical report text templates
REPORT_TEMPLATES = [
    {
        "text": """
PATIENT MEDICAL REPORT
Date: 2025-12-15
Facility: Max Super Speciality Hospital, New Delhi

DIAGNOSIS: Essential Hypertension (Stage 1)
Blood Pressure: 142/92 mmHg (elevated)

BLOOD WORK:
- HbA1c: 5.8% (pre-diabetic range)
- Fasting Glucose: 110 mg/dL
- Total Cholesterol: 220 mg/dL (borderline high)
- LDL: 145 mg/dL
- HDL: 42 mg/dL (low)
- Triglycerides: 180 mg/dL
- Vitamin D: 18 ng/mL (deficient)
- Vitamin B12: 290 pg/mL (low-normal)
- TSH: 4.8 mIU/L (borderline)
- Hemoglobin: 13.2 g/dL

MEDICATIONS PRESCRIBED:
- Amlodipine 5mg (daily)
- Vitamin D3 60000 IU (weekly)

RECOMMENDATIONS:
- Low sodium diet
- Regular exercise (30 min/day)
- Follow-up in 3 months
        """,
        "conditions": ["hypertension", "high_cholesterol", "vitamin_d_deficiency"],
        "medications": ["amlodipine_5mg", "vitamin_d3_60000iu"],
    },
    {
        "text": """
PATIENT HEALTH CHECKUP REPORT
Date: 2026-01-20
Facility: Apollo Hospitals, Chennai

FINDINGS:
- Type 2 Diabetes Mellitus (newly diagnosed)
- BMI: 28.4 (overweight)
- Mild Fatty Liver (Grade 1)

LAB RESULTS:
- HbA1c: 7.2% (diabetic)
- Fasting Glucose: 148 mg/dL
- Post-prandial Glucose: 210 mg/dL
- Liver Function: SGOT 45, SGPT 52 (mildly elevated)
- Creatinine: 0.9 mg/dL (normal)
- Uric Acid: 7.2 mg/dL (borderline)

MEDICATIONS:
- Metformin 500mg (twice daily)
- Pantoprazole 40mg (daily)

ADVICE:
- Strict diabetic diet
- Walk 45 minutes daily
- Avoid sugar and refined carbs
- Recheck HbA1c in 3 months
        """,
        "conditions": ["diabetes_type2", "fatty_liver"],
        "medications": ["metformin_500mg", "pantoprazole_40mg"],
    },
    {
        "text": """
PULMONARY FUNCTION TEST REPORT
Date: 2026-02-10
Facility: AIIMS, New Delhi

DIAGNOSIS: Mild Persistent Asthma
FEV1: 78% of predicted
FVC: 85% of predicted
FEV1/FVC: 72%

ALLERGY PANEL:
- Dust mites: Positive
- Pollen: Positive
- Pet dander: Negative

MEDICATIONS:
- Budecort 200mcg inhaler (twice daily)
- Salbutamol 100mcg (as needed)
- Montelukast 10mg (daily)

RECOMMENDATIONS:
- Avoid exposure to dust and smoke
- Use air purifier at home
- Carry rescue inhaler always
- AQI monitoring recommended
        """,
        "conditions": ["asthma"],
        "medications": ["budecort_inhaler", "salbutamol_inhaler", "montelukast_10mg"],
    },
]


async def parse_medical_report(file_content: bytes, filename: str) -> dict:
    """
    Parse a medical report PDF using OCR.
    
    In production, this would use:
    - Tesseract OCR or Google Cloud Vision API for text extraction
    - NLP-based entity recognition for conditions, medications, and lab values
    
    For the prototype, we return simulated but realistic parsed data.
    """
    # Simulate OCR processing delay concept
    # In production: use pytesseract or Google Vision API
    
    # Select a random report template to simulate parsing
    report = random.choice(REPORT_TEMPLATES)
    
    return {
        "filename": filename,
        "parsed_text": report["text"].strip(),
        "conditions_found": report["conditions"],
        "medications_found": report["medications"],
        "confidence": round(random.uniform(0.82, 0.96), 2),
        "parsing_engine": "simulated_ocr_v1",
        "note": "In production, this would use Tesseract OCR + Medical NER model for accurate extraction."
    }
