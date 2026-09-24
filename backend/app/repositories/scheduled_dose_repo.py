from sqlalchemy.orm import Session, joinedload
from typing import List, Optional
from datetime import datetime
from backend.app.models.scheduled_dose import ScheduledDose
from backend.app.schemas.scheduled_dose import ScheduledDoseCreate

class ScheduledDoseRepository:
    def get_by_patient(self, db: Session, patient_id: int) -> List[ScheduledDose]:
        return (
            db.query(ScheduledDose)
            .options(joinedload(ScheduledDose.medication))
            .filter(ScheduledDose.patient_id == patient_id)
            .all()
        )

    def get_by_id(self, db: Session, dose_id: str) -> Optional[ScheduledDose]:
        return (
            db.query(ScheduledDose)
            .options(joinedload(ScheduledDose.medication))
            .filter(ScheduledDose.id == dose_id)
            .first()
        )

    def toggle_dose_status(self, db: Session, dose_id: str) -> Optional[ScheduledDose]:
        dose = self.get_by_id(db, dose_id)
        if not dose:
            return None
        
        if dose.status == "TAKEN":
            dose.status = "SCHEDULED"
            dose.adherence_time = None
        else:
            dose.status = "TAKEN"
            now = datetime.now()
            dose.adherence_time = now.strftime("%I:%M %p")
        
        db.commit()
        db.refresh(dose)
        return dose

    def create(self, db: Session, dose_in: ScheduledDoseCreate) -> ScheduledDose:
        db_dose = ScheduledDose(**dose_in.model_dump())
        db.add(db_dose)
        db.commit()
        db.refresh(db_dose)
        return db_dose

scheduled_dose_repo = ScheduledDoseRepository()
