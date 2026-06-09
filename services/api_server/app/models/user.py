"""
Care 2.0 — Pydantic Models for User Profiles & Medical Data
"""
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from enum import Enum


class BloodGroup(str, Enum):
    A_POS = "A+"
    A_NEG = "A-"
    B_POS = "B+"
    B_NEG = "B-"
    AB_POS = "AB+"
    AB_NEG = "AB-"
    O_POS = "O+"
    O_NEG = "O-"


class Biometrics(BaseModel):
    age: int = Field(..., ge=1, le=120, description="Age in years")
    height_cm: float = Field(..., ge=50, le=300, description="Height in cm")
    weight_kg: float = Field(..., ge=10, le=500, description="Weight in kg")
    blood_group: BloodGroup
    bmi: Optional[float] = None

    def compute_bmi(self) -> float:
        self.bmi = round(self.weight_kg / ((self.height_cm / 100) ** 2), 1)
        return self.bmi


class GeneticRisks(BaseModel):
    father: list[str] = Field(default_factory=list)
    mother: list[str] = Field(default_factory=list)
    paternal_grandfather: list[str] = Field(default_factory=list)
    paternal_grandmother: list[str] = Field(default_factory=list)
    maternal_grandfather: list[str] = Field(default_factory=list)
    maternal_grandmother: list[str] = Field(default_factory=list)


class MedicalReport(BaseModel):
    file_url: str
    parsed_text: Optional[str] = None
    conditions_found: list[str] = Field(default_factory=list)
    uploaded_at: datetime = Field(default_factory=datetime.utcnow)


class ClinicalHistory(BaseModel):
    conditions: list[str] = Field(default_factory=list)
    medications: list[str] = Field(default_factory=list)
    allergies: list[str] = Field(default_factory=list)
    reports: list[MedicalReport] = Field(default_factory=list)


class UserMedicalProfile(BaseModel):
    uid: str
    biometrics: Biometrics
    genetic_risks: GeneticRisks = Field(default_factory=GeneticRisks)
    clinical_history: ClinicalHistory = Field(default_factory=ClinicalHistory)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class UserProfileCreate(BaseModel):
    uid: str
    biometrics: Biometrics
    genetic_risks: Optional[GeneticRisks] = None
    clinical_history: Optional[ClinicalHistory] = None


class UserProfileUpdate(BaseModel):
    biometrics: Optional[Biometrics] = None
    genetic_risks: Optional[GeneticRisks] = None
    clinical_history: Optional[ClinicalHistory] = None
