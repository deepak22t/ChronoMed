from sqlalchemy.orm import Session
from typing import List
from backend.app.models.meal_anchor import MealAnchor
from backend.app.schemas.meal_anchor import MealAnchorCreate

class MealAnchorRepository:
    def get_by_patient(self, db: Session, patient_id: int) -> List[MealAnchor]:
        return db.query(MealAnchor).filter(MealAnchor.patient_id == patient_id).all()

    def create(self, db: Session, anchor_in: MealAnchorCreate) -> MealAnchor:
        db_anchor = MealAnchor(**anchor_in.model_dump())
        db.add(db_anchor)
        db.commit()
        db.refresh(db_anchor)
        return db_anchor

meal_anchor_repo = MealAnchorRepository()
