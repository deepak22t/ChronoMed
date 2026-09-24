from pydantic import BaseModel
from typing import Optional, List, Dict, Any

class AIChatRequest(BaseModel):
    query: str
    patient_id: Optional[int] = 1
    conversation_history: Optional[List[Dict[str, str]]] = []

class AIChatResponse(BaseModel):
    answer: str
    clinical_rationale: Optional[str] = None
    citations: Optional[List[str]] = []
    model_used: str = "nvidia/nemotron-3-ultra-550b-a55b:free"
