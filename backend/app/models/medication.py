from sqlalchemy import Column, Integer, String, Boolean
from sqlalchemy.orm import relationship
from backend.app.core.database import Base

class Medication(Base):
    __tablename__ = "medications"

    id = Column(Integer, primary_key=True, index=True)
    rxcui = Column(String(50), index=True)
    name = Column(String(150), nullable=False)
    dosage = Column(String(50), nullable=False)
    form = Column(String(50), default="Tablet")
    instructions = Column(String(255))
    requires_empty_stomach = Column(Boolean, default=False)
    empty_stomach_pre_meal_minutes = Column(Integer, default=60)
    empty_stomach_post_meal_minutes = Column(Integer, default=120)
    circadian_preference = Column(String(50), default="ANY")
    
    # Relationships
    doses = relationship("ScheduledDose", back_populates="medication")
