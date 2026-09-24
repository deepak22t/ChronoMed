from backend.app.routers.health import router as health_router
from backend.app.routers.patient import router as patient_router
from backend.app.routers.timeline import router as timeline_router
from backend.app.routers.medications import router as medications_router
from backend.app.routers.ai import router as ai_router

__all__ = ["health_router", "patient_router", "timeline_router", "medications_router", "ai_router"]
