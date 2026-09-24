from sqlalchemy import Column, Integer, String, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from backend.app.core.database import Base

class ScheduledDose(Base):
    __tablename__ = "scheduled_doses"

    id = Column(String(100), primary_key=True, index=True)
    patient_id = Column(Integer, ForeignKey("patients.id"), nullable=False)
    medication_id = Column(Integer, ForeignKey("medications.id"), nullable=False)
    
    dose_time = Column(String(20), nullable=False)  # e.g. "07:00 AM"
    window_str = Column(String(50), nullable=False) # e.g. "07:00 AM - 07:45 AM"
    status = Column(String(30), default="SCHEDULED") # SCHEDULED, TAKEN, MISSED, SNOOZED
    
    adherence_percent = Column(Integer, default=100)
    adherence_time = Column(String(20)) # e.g. "07:02 AM"
    
    tag = Column(String(100)) # e.g. "EMPTY STOMACH WINDOW"
    tag_color = Column(String(30), default="amber") # amber, cyan, emerald
    gap_info = Column(String(50)) # e.g. "Gap 5h 28m"
    is_active_focus = Column(Boolean, default=False)
    clinical_notes = Column(String(500))
    
    # Relationships
    patient = relationship("Patient", back_populates="doses")
    medication = relationship("Medication", back_populates="doses")
