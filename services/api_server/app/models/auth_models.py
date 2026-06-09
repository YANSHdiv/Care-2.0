"""
Care 2.0 — Pydantic Models for Authentication
"""
from pydantic import BaseModel, EmailStr, Field


class UserRegister(BaseModel):
    email: str = Field(..., description="User email address")
    password: str = Field(..., min_length=6, description="Password (min 6 chars)")
    display_name: str = Field(..., min_length=2, max_length=50, description="Display name")


class UserLogin(BaseModel):
    email: str = Field(..., description="User email address")
    password: str = Field(..., description="Password")


class ForgotPasswordRequest(BaseModel):
    email: str = Field(..., description="Registered email address")


class ResetPasswordRequest(BaseModel):
    token: str = Field(..., description="Password reset token")
    new_password: str = Field(..., min_length=6, description="New password (min 6 chars)")


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    uid: str
    display_name: str
    email: str


class UserInfo(BaseModel):
    uid: str
    email: str
    display_name: str
