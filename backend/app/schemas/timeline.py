from pydantic import BaseModel
from typing import List, Optional
from backend.app.schemas.patient import PatientRead
from backend.app.schemas.scheduled_dose import ScheduledDoseRead
from backend.app.schemas.meal_anchor import MealAnchorRead

class CircadianMarker(BaseModel):
    time_str: str
    label: str
    is_peak: bool = False
    icon: Optional[str] = None

class TodayTimelineResponse(BaseModel):
    patient: PatientRead
    current_time: str
    cortisol_badge: str
    wave_markers: List[CircadianMarker]
    doses: List[ScheduledDoseRead]
    meal_anchors: List[MealAnchorRead]
    adherence_rate: int
    conflict_detected: bool = False
    conflict_message: Optional[str] = None
