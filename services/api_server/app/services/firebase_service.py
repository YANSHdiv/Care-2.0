"""
Care 2.0 — Firebase Service
Handles Firestore CRUD operations for user profiles, health data, and authentication.
Falls back to in-memory storage when Firebase is not configured.
"""
from typing import Optional
from datetime import datetime
import json

# In-memory fallback storage (used when Firebase is not configured)
_memory_store: dict[str, dict] = {}
_meal_logs: dict[str, list] = {}
_risk_reports: dict[str, list] = {}
_auth_store: dict[str, dict] = {}          # email -> auth record
_reset_tokens: dict[str, str] = {}         # token -> email

# Try Firebase initialization
_db = None
_bucket = None

def _init_firebase():
    global _db, _bucket
    try:
        import firebase_admin
        from firebase_admin import credentials, firestore, storage
        from app.config import get_settings
        settings = get_settings()
        
        import os
        if os.path.exists(settings.FIREBASE_CREDENTIALS_PATH):
            cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
            firebase_admin.initialize_app(cred, {
                'storageBucket': settings.FIREBASE_STORAGE_BUCKET
            })
            _db = firestore.client()
            _bucket = storage.bucket()
    except Exception:
        pass

_init_firebase()


# ══════════════════════════════════════════════════
# Authentication Storage
# ══════════════════════════════════════════════════

async def save_user_auth(auth_record: dict) -> dict:
    """Save a new user auth record (email, password_hash, uid, display_name)."""
    email = auth_record["email"]
    if _db:
        _db.collection("user_auth").document(email).set(auth_record)
    else:
        _auth_store[email] = auth_record
    return {"status": "created", "uid": auth_record["uid"]}


async def get_user_by_email(email: str) -> Optional[dict]:
    """Look up a user auth record by email."""
    if _db:
        doc = _db.collection("user_auth").document(email).get()
        return doc.to_dict() if doc.exists else None
    else:
        return _auth_store.get(email)


async def update_user_password(email: str, new_password_hash: str) -> dict:
    """Update user's password hash."""
    if _db:
        doc_ref = _db.collection("user_auth").document(email)
        doc_ref.update({"password_hash": new_password_hash})
    else:
        if email in _auth_store:
            _auth_store[email]["password_hash"] = new_password_hash
    return {"status": "password_updated", "email": email}


async def save_reset_token(email: str, token: str) -> None:
    """Store a password reset token linked to an email."""
    if _db:
        _db.collection("password_reset_tokens").document(token).set({
            "email": email,
            "created_at": datetime.utcnow().isoformat(),
        })
    else:
        _reset_tokens[token] = email


async def validate_reset_token(token: str) -> Optional[str]:
    """Validate a reset token and return the associated email, or None."""
    if _db:
        doc = _db.collection("password_reset_tokens").document(token).get()
        if doc.exists:
            return doc.to_dict().get("email")
        return None
    else:
        return _reset_tokens.get(token)


async def invalidate_reset_token(token: str) -> None:
    """Delete a used reset token."""
    if _db:
        _db.collection("password_reset_tokens").document(token).delete()
    else:
        _reset_tokens.pop(token, None)


# ══════════════════════════════════════════════════
# Profile Storage
# ══════════════════════════════════════════════════

async def save_user_profile(uid: str, profile_data: dict) -> dict:
    """Save or update user medical profile."""
    profile_data["updated_at"] = datetime.utcnow().isoformat()
    
    if _db:
        doc_ref = _db.collection("user_medical_profiles").document(uid)
        doc_ref.set(profile_data, merge=True)
    else:
        _memory_store[uid] = profile_data
    
    return {"status": "success", "uid": uid}


async def get_user_profile(uid: str) -> Optional[dict]:
    """Retrieve user medical profile."""
    if _db:
        doc = _db.collection("user_medical_profiles").document(uid).get()
        return doc.to_dict() if doc.exists else None
    else:
        return _memory_store.get(uid)


async def update_user_profile(uid: str, updates: dict) -> dict:
    """Partially update user profile."""
    if _db:
        doc_ref = _db.collection("user_medical_profiles").document(uid)
        updates["updated_at"] = datetime.utcnow().isoformat()
        doc_ref.update(updates)
    else:
        if uid in _memory_store:
            _memory_store[uid].update(updates)
        else:
            _memory_store[uid] = updates
    
    return {"status": "updated", "uid": uid}


async def save_meal_log(uid: str, meal_data: dict) -> dict:
    """Log a meal analysis result."""
    meal_data["logged_at"] = datetime.utcnow().isoformat()
    
    if _db:
        _db.collection("meal_logs").document(uid).collection("meals").add(meal_data)
    else:
        if uid not in _meal_logs:
            _meal_logs[uid] = []
        _meal_logs[uid].append(meal_data)
    
    return {"status": "logged", "uid": uid}


async def get_meal_history(uid: str, limit: int = 30) -> list[dict]:
    """Get meal history for a user."""
    if _db:
        meals_ref = (_db.collection("meal_logs").document(uid)
                     .collection("meals")
                     .order_by("logged_at", direction="DESCENDING")
                     .limit(limit))
        return [doc.to_dict() for doc in meals_ref.stream()]
    else:
        return (_meal_logs.get(uid, []))[-limit:]


async def save_risk_report(uid: str, report_data: dict) -> dict:
    """Save a risk prediction report."""
    report_data["generated_at"] = datetime.utcnow().isoformat()
    
    if _db:
        _db.collection("risk_reports").document(uid).collection("reports").add(report_data)
    else:
        if uid not in _risk_reports:
            _risk_reports[uid] = []
        _risk_reports[uid].append(report_data)
    
    return {"status": "saved", "uid": uid}


async def get_latest_risk_report(uid: str) -> Optional[dict]:
    """Get the most recent risk report for a user."""
    if _db:
        reports = (_db.collection("risk_reports").document(uid)
                   .collection("reports")
                   .order_by("generated_at", direction="DESCENDING")
                   .limit(1))
        docs = list(reports.stream())
        return docs[0].to_dict() if docs else None
    else:
        reports = _risk_reports.get(uid, [])
        return reports[-1] if reports else None
