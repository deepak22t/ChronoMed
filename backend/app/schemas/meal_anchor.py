from pydantic import BaseModel, ConfigDict

class MealAnchorBase(BaseModel):
    name: str # e.g. BREAKFAST
    time_str: str # e.g. 08:30 AM
    icon: str = "restaurant"

class MealAnchorCreate(MealAnchorBase):
    patient_id: int

class MealAnchorRead(MealAnchorBase):
    id: int
    patient_id: int
    model_config = ConfigDict(from_attributes=True)
