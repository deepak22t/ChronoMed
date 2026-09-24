from sqlalchemy.orm import Session
from backend.app.models.patient import Patient
from backend.app.schemas.patient import PatientCreate

class PatientRepository:
    def get_by_id(self, db: Session, patient_id: int) -> Patient | None:
        return db.query(Patient).filter(Patient.id == patient_id).first()

    def get_default_patient(self, db: Session) -> Patient:
        patient = db.query(Patient).first()
        return patient

    def create(self, db: Session, patient_in: PatientCreate) -> Patient:
        db_patient = Patient(**patient_in.model_dump())
        db.add(db_patient)
        db.commit()
        db.refresh(db_patient)
        return db_patient

patient_repo = PatientRepository()
