from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import List
from backend.app.core.database import get_db
from backend.app.services.timeline_service import timeline_service
from backend.app.services.dose_service import dose_service
from backend.app.repositories.scheduled_dose_repo import scheduled_dose_repo
from backend.app.schemas.timeline import TodayTimelineResponse
from backend.app.schemas.scheduled_dose import ScheduledDoseRead, DoseToggleResponse

router = APIRouter(prefix="/timeline", tags=["Timeline"])

@router.get("/today", response_model=TodayTimelineResponse)
def get_today_timeline(patient_id: int = Query(1, description="Patient ID"), db: Session = Depends(get_db)):
    return timeline_service.get_today_timeline(db, patient_id=patient_id)

@router.get("/doses", response_model=List[ScheduledDoseRead])
def get_patient_doses(patient_id: int = Query(1, description="Patient ID"), db: Session = Depends(get_db)):
    return scheduled_dose_repo.get_by_patient(db, patient_id=patient_id)

@router.post("/doses/{dose_id}/toggle", response_model=DoseToggleResponse)
def toggle_dose(dose_id: str, db: Session = Depends(get_db)):
    return dose_service.toggle_dose(db, dose_id=dose_id)
