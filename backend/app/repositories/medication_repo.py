from sqlalchemy.orm import Session
from typing import List, Optional
from backend.app.models.medication import Medication
from backend.app.schemas.medication import MedicationCreate

class MedicationRepository:
    def get_all(self, db: Session) -> List[Medication]:
        return db.query(Medication).all()

    def get_by_id(self, db: Session, med_id: int) -> Optional[Medication]:
        return db.query(Medication).filter(Medication.id == med_id).first()

    def get_by_name(self, db: Session, name: str) -> Optional[Medication]:
        return db.query(Medication).filter(Medication.name.ilike(f"%{name}%")).first()

    def create(self, db: Session, med_in: MedicationCreate) -> Medication:
        db_med = Medication(**med_in.model_dump())
        db.add(db_med)
        db.commit()
        db.refresh(db_med)
        return db_med

medication_repo = MedicationRepository()
