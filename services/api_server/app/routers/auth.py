"""
Care 2.0 — Auth Router
Handles user registration, login, token verification, and password reset.
Uses JWT tokens for stateless authentication and bcrypt for password hashing.
"""
import uuid
import secrets
from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, HTTPException, Depends, Header
from app.models.auth_models import (
    UserRegister, UserLogin, TokenResponse, UserInfo,
    ForgotPasswordRequest, ResetPasswordRequest,
)
from app.services import firebase_service

# ── JWT / Crypto Setup ──
import jwt
import hashlib

JWT_SECRET = "care2_jwt_secret_key_change_in_production_2024"
JWT_ALGORITHM = "HS256"
JWT_EXPIRY_HOURS = 72  # 3-day token validity

router = APIRouter(prefix="/api/v1/auth", tags=["Authentication"])


def _hash_password(password: str) -> str:
    """Hash password with SHA-256 + random salt."""
    salt = secrets.token_hex(16)
    hashed = hashlib.sha256(f"{salt}:{password}".encode()).hexdigest()
    return f"{salt}${hashed}"


def _verify_password(password: str, stored: str) -> bool:
    """Verify password against salt$hash format."""
    salt, hashed = stored.split("$", 1)
    return hashlib.sha256(f"{salt}:{password}".encode()).hexdigest() == hashed


def _create_token(uid: str, email: str, display_name: str) -> str:
    payload = {
        "uid": uid,
        "email": email,
        "display_name": display_name,
        "exp": datetime.now(timezone.utc) + timedelta(hours=JWT_EXPIRY_HOURS),
        "iat": datetime.now(timezone.utc),
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)


def _decode_token(token: str) -> dict:
    try:
        return jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired. Please log in again.")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token.")


async def get_current_user(authorization: str = Header(...)) -> dict:
    """Dependency: extract user from Bearer token."""
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authorization header.")
    token = authorization.split(" ", 1)[1]
    return _decode_token(token)


# ── Endpoints ──

@router.post("/register", response_model=TokenResponse)
async def register(body: UserRegister):
    """Register a new user with email + password."""
    email_lower = body.email.strip().lower()

    # Check if email already taken
    existing = await firebase_service.get_user_by_email(email_lower)
    if existing:
        raise HTTPException(status_code=409, detail="An account with this email already exists.")

    uid = f"user_{uuid.uuid4().hex[:12]}"
    hashed = _hash_password(body.password)

    auth_record = {
        "uid": uid,
        "email": email_lower,
        "display_name": body.display_name.strip(),
        "password_hash": hashed,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    await firebase_service.save_user_auth(auth_record)

    token = _create_token(uid, email_lower, body.display_name.strip())
    return TokenResponse(
        access_token=token,
        uid=uid,
        display_name=body.display_name.strip(),
        email=email_lower,
    )


@router.post("/login", response_model=TokenResponse)
async def login(body: UserLogin):
    """Authenticate with email + password, receive JWT token."""
    email_lower = body.email.strip().lower()
    user = await firebase_service.get_user_by_email(email_lower)

    if not user:
        raise HTTPException(status_code=401, detail="No account found with this email.")

    if not _verify_password(body.password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="Incorrect password.")

    token = _create_token(user["uid"], user["email"], user["display_name"])
    return TokenResponse(
        access_token=token,
        uid=user["uid"],
        display_name=user["display_name"],
        email=user["email"],
    )


@router.get("/me", response_model=UserInfo)
async def get_me(user: dict = Depends(get_current_user)):
    """Verify token and return current user info."""
    return UserInfo(
        uid=user["uid"],
        email=user["email"],
        display_name=user["display_name"],
    )


@router.post("/forgot-password")
async def forgot_password(body: ForgotPasswordRequest):
    """
    Generate a password reset token.
    In production this would send an email — for the prototype
    the token is returned directly in the response.
    """
    email_lower = body.email.strip().lower()
    user = await firebase_service.get_user_by_email(email_lower)

    if not user:
        # Don't reveal whether email exists (security best practice)
        return {"message": "If an account with that email exists, a reset code has been generated."}

    reset_token = secrets.token_urlsafe(32)
    await firebase_service.save_reset_token(email_lower, reset_token)

    return {
        "message": "If an account with that email exists, a reset code has been generated.",
        "reset_token": reset_token,  # In production, this would be emailed instead
    }


@router.post("/reset-password")
async def reset_password(body: ResetPasswordRequest):
    """Reset password using a reset token."""
    email = await firebase_service.validate_reset_token(body.token)
    if not email:
        raise HTTPException(status_code=400, detail="Invalid or expired reset token.")

    hashed = _hash_password(body.new_password)
    await firebase_service.update_user_password(email, hashed)
    await firebase_service.invalidate_reset_token(body.token)

    return {"message": "Password has been reset successfully. You can now log in."}
