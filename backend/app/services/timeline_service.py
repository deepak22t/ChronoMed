from sqlalchemy.orm import Session
from datetime import datetime
from typing import List
from backend.app.repositories.patient_repo import patient_repo
from backend.app.repositories.scheduled_dose_repo import scheduled_dose_repo
from backend.app.repositories.meal_anchor_repo import meal_anchor_repo
from backend.app.schemas.timeline import TodayTimelineResponse, CircadianMarker
from backend.app.schemas.patient import PatientRead
from backend.app.schemas.scheduled_dose import ScheduledDoseRead
from backend.app.schemas.meal_anchor import MealAnchorRead

class TimelineService:
    def get_today_timeline(self, db: Session, patient_id: int = 1) -> TodayTimelineResponse:
        patient = patient_repo.get_by_id(db, patient_id)
        if not patient:
            patient = patient_repo.get_default_patient(db)

        doses = scheduled_dose_repo.get_by_patient(db, patient.id)
        meals = meal_anchor_repo.get_by_patient(db, patient.id)

        # Dynamic adherence rate
        total_doses = len(doses)
        taken_doses = sum(1 for d in doses if d.status == "TAKEN")
        adherence_rate = int((taken_doses / total_doses * 100)) if total_doses > 0 else 100

        # Circadian wave markers matching the UI design
        markers = [
            CircadianMarker(time_str="06:00 AM", label="Sunrise • Baseline", is_peak=False, icon="wb_twilight"),
            CircadianMarker(time_str="08:00 AM", label="Cortisol Rise", is_peak=False, icon="wb_sunny_outlined"),
            CircadianMarker(time_str="09:45 AM", label="Morning Cortisol Peak", is_peak=True, icon="wb_sunny"),
            CircadianMarker(time_str="10:00 AM", label="Active Window • Sun", is_peak=False, icon="wb_sunny"),
            CircadianMarker(time_str="13:00 PM", label="Midday Solar Peak", is_peak=False, icon="light_mode"),
            CircadianMarker(time_str="02:00 PM", label="Afternoon Plateau", is_peak=False, icon="wb_sunny_outlined"),
            CircadianMarker(time_str="Evening", label="Melatonin Priming", is_peak=False, icon="nights_stay"),
        ]

        now = datetime.now()
        current_time_str = now.strftime("%I:%M %p")

        return TodayTimelineResponse(
            patient=PatientRead.model_validate(patient),
            current_time=current_time_str,
            cortisol_badge=patient.cortisol_peak,
            wave_markers=markers,
            doses=[ScheduledDoseRead.model_validate(d) for d in doses],
            meal_anchors=[MealAnchorRead.model_validate(m) for m in meals],
            adherence_rate=adherence_rate,
            conflict_detected=False,
            conflict_message=None
        )

timeline_service = TimelineService()
