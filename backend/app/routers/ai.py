from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from backend.app.core.database import get_db
from backend.app.services.ai_service import ai_service
from backend.app.schemas.ai_chat import AIChatRequest, AIChatResponse

router = APIRouter(prefix="/ai", tags=["AI Copilot"])

@router.post("/consult", response_model=AIChatResponse)
async def consult_ai(request: AIChatRequest, db: Session = Depends(get_db)):
    return await ai_service.consult(
        db=db,
        query=request.query,
        patient_id=request.patient_id or 1,
        history=request.conversation_history
    )
