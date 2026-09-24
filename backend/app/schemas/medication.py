from pydantic import BaseModel, ConfigDict
from typing import Optional

class MedicationBase(BaseModel):
    rxcui: Optional[str] = None
    name: str
    dosage: str
    form: str = "Tablet"
    instructions: Optional[str] = None
    requires_empty_stomach: bool = False
    empty_stomach_pre_meal_minutes: int = 60
    empty_stomach_post_meal_minutes: int = 120
    circadian_preference: str = "ANY"

class MedicationCreate(MedicationBase):
    pass

class MedicationRead(MedicationBase):
    id: int
    model_config = ConfigDict(from_attributes=True)
