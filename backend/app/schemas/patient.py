from pydantic import BaseModel, ConfigDict
from typing import Optional

class PatientBase(BaseModel):
    name: str = "HARRY J."
    age: int = 58
    conditions: str = "Hypothyroidism, Osteopenia, Type-2 Pre-diabetes"
    wake_time: str = "06:30 AM"
    sleep_time: str = "10:30 PM"
    cortisol_peak: str = "Morning Cortisol Peak • 09:45 AM"
    adherence_score: int = 98

class PatientCreate(PatientBase):
    pass

class PatientRead(PatientBase):
    id: int
    model_config = ConfigDict(from_attributes=True)
