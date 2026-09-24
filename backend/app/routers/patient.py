from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from backend.app.core.database import get_db
from backend.app.repositories.patient_repo import patient_repo
from backend.app.schemas.patient import PatientRead

router = APIRouter(prefix="/patient", tags=["Patient"])

@router.get("/me", response_model=PatientRead)
def get_current_patient(db: Session = Depends(get_db)):
    patient = patient_repo.get_default_patient(db)
    if not patient:
        raise HTTPException(status_code=404, detail="Patient profile not found")
    return patient

@router.get("/{patient_id}", response_model=PatientRead)
def get_patient_by_id(patient_id: int, db: Session = Depends(get_db)):
    patient = patient_repo.get_by_id(db, patient_id)
    if not patient:
        raise HTTPException(status_code=404, detail="Patient profile not found")
    return patient
