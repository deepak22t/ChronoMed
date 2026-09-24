from sqlalchemy.orm import Session
from fastapi import HTTPException
from backend.app.repositories.scheduled_dose_repo import scheduled_dose_repo
from backend.app.schemas.scheduled_dose import DoseToggleResponse

class DoseService:
    def toggle_dose(self, db: Session, dose_id: str) -> DoseToggleResponse:
        dose = scheduled_dose_repo.get_by_id(db, dose_id)
        if not dose:
            raise HTTPException(status_code=404, detail=f"Scheduled dose '{dose_id}' not found.")

        prev_status = dose.status
        updated_dose = scheduled_dose_repo.toggle_dose_status(db, dose_id)

        msg = (
            f"Dose marked as taken at {updated_dose.adherence_time}"
            if updated_dose.status == "TAKEN"
            else "Dose status reset to scheduled"
        )

        return DoseToggleResponse(
            id=updated_dose.id,
            previous_status=prev_status,
            new_status=updated_dose.status,
            adherence_time=updated_dose.adherence_time,
            message=msg
        )

dose_service = DoseService()
