from sqlalchemy import Column, Integer, String
from backend.app.core.database import Base

class ChelationConflict(Base):
    __tablename__ = "chelation_conflicts"

    id = Column(Integer, primary_key=True, index=True)
    drug_a = Column(String(100), nullable=False)
    drug_b = Column(String(100), nullable=False)
    gap_minutes = Column(Integer, nullable=False, default=240) # 4 hours
    severity = Column(String(30), default="HIGH")
    mechanism = Column(String(255), default="Polyvalent cation binding reducing oral bioavailability")
    rationale = Column(String(500), default="Must be separated by at least 4 hours to avoid 80% loss in therapeutic efficacy.")
