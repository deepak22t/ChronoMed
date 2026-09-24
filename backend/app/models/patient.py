from sqlalchemy import Column, Integer, String, Float
from sqlalchemy.orm import relationship
from backend.app.core.database import Base

class Patient(Base):
    __tablename__ = "patients"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False, default="HARRY J.")
    age = Column(Integer, nullable=False, default=58)
    conditions = Column(String(255), default="Hypothyroidism, Osteopenia, Type-2 Pre-diabetes")
    wake_time = Column(String(20), default="06:30 AM")
    sleep_time = Column(String(20), default="10:30 PM")
    cortisol_peak = Column(String(50), default="Morning Cortisol Peak • 09:45 AM")
    adherence_score = Column(Integer, default=98)
    
    # Relationships
    doses = relationship("ScheduledDose", back_populates="patient", cascade="all, delete-orphan")
    meal_anchors = relationship("MealAnchor", back_populates="patient", cascade="all, delete-orphan")
