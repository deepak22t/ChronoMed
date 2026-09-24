from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from backend.app.core.database import get_db
from backend.app.repositories.medication_repo import medication_repo
from backend.app.schemas.medication import MedicationRead, MedicationCreate

router = APIRouter(prefix="/medications", tags=["Medications"])

@router.get("", response_model=List[MedicationRead])
def list_medications(db: Session = Depends(get_db)):
    return medication_repo.get_all(db)

@router.get("/{med_id}", response_model=MedicationRead)
def get_medication(med_id: int, db: Session = Depends(get_db)):
    med = medication_repo.get_by_id(db, med_id)
    if not med:
        raise HTTPException(status_code=404, detail="Medication not found")
    return med

@router.post("", response_model=MedicationRead, status_code=201)
def create_medication(med_in: MedicationCreate, db: Session = Depends(get_db)):
    return medication_repo.create(db, med_in)
