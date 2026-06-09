"""
Care 2.0 — Profile Router
Handles user medical profile CRUD operations and OCR parsing.
"""
from fastapi import APIRouter, HTTPException, UploadFile, File
from app.models.user import UserProfileCreate, UserProfileUpdate, UserMedicalProfile
from app.services import firebase_service, ocr_service

router = APIRouter(prefix="/api/v1/profile", tags=["Profile"])


@router.post("/", response_model=dict)
async def create_profile(profile: UserProfileCreate):
    """Create a new user medical profile."""
    # Auto-compute BMI
    profile.biometrics.compute_bmi()
    
    profile_data = profile.model_dump()
    if profile.genetic_risks is None:
        profile_data["genetic_risks"] = {}
    if profile.clinical_history is None:
        profile_data["clinical_history"] = {"conditions": [], "medications": [], "allergies": [], "reports": []}
    
    result = await firebase_service.save_user_profile(profile.uid, profile_data)
    return {**result, "bmi": profile.biometrics.bmi}


@router.get("/{uid}")
async def get_profile(uid: str):
    """Retrieve a user's medical profile."""
    profile = await firebase_service.get_user_profile(uid)
    if not profile:
        raise HTTPException(status_code=404, detail=f"Profile not found for uid: {uid}")
    return profile


@router.put("/{uid}")
async def update_profile(uid: str, updates: UserProfileUpdate):
    """Update a user's medical profile."""
    update_data = {}
    if updates.biometrics:
        updates.biometrics.compute_bmi()
        update_data["biometrics"] = updates.biometrics.model_dump()
    if updates.genetic_risks:
        update_data["genetic_risks"] = updates.genetic_risks.model_dump()
    if updates.clinical_history:
        update_data["clinical_history"] = updates.clinical_history.model_dump()
    
    if not update_data:
        raise HTTPException(status_code=400, detail="No fields to update")
    
    return await firebase_service.update_user_profile(uid, update_data)


@router.post("/ocr/parse")
async def parse_report(file: UploadFile = File(...)):
    """
    Parse a medical report PDF using OCR.
    Extracts conditions, medications, and lab values.
    """
    if not file.filename:
        raise HTTPException(status_code=400, detail="No file provided")
    
    allowed_types = [".pdf", ".jpg", ".jpeg", ".png"]
    ext = "." + file.filename.rsplit(".", 1)[-1].lower() if "." in file.filename else ""
    if ext not in allowed_types:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type: {ext}. Allowed: {allowed_types}"
        )
    
    content = await file.read()
    result = await ocr_service.parse_medical_report(content, file.filename)
    return result
