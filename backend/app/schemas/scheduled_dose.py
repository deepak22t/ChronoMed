from pydantic import BaseModel, ConfigDict
from typing import Optional
from backend.app.schemas.medication import MedicationRead

class ScheduledDoseBase(BaseModel):
    dose_time: str
    window_str: str
    status: str = "SCHEDULED"
    adherence_percent: int = 100
    adherence_time: Optional[str] = None
    tag: Optional[str] = None
    tag_color: Optional[str] = "amber"
    gap_info: Optional[str] = None
    is_active_focus: bool = False
    clinical_notes: Optional[str] = None

class ScheduledDoseCreate(ScheduledDoseBase):
    id: str
    patient_id: int
    medication_id: int

class ScheduledDoseRead(ScheduledDoseBase):
    id: str
    patient_id: int
    medication_id: int
    medication: Optional[MedicationRead] = None
    model_config = ConfigDict(from_attributes=True)

class DoseToggleResponse(BaseModel):
    id: str
    previous_status: str
    new_status: str
    adherence_time: Optional[str] = None
    message: str
