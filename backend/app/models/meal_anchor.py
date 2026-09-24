from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from backend.app.core.database import Base

class MealAnchor(Base):
    __tablename__ = "meal_anchors"

    id = Column(Integer, primary_key=True, index=True)
    patient_id = Column(Integer, ForeignKey("patients.id"), nullable=False)
    name = Column(String(50), nullable=False)  # e.g., "BREAKFAST"
    time_str = Column(String(20), nullable=False)  # e.g., "08:30 AM"
    icon = Column(String(50), default="restaurant")
    
    # Relationships
    patient = relationship("Patient", back_populates="meal_anchors")
