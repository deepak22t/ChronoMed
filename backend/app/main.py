from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from backend.app.core.config import settings
from backend.app.core.database import engine, Base, SessionLocal
from backend.app.services.seed_service import seed_service
from backend.app.routers.health import router as health_router
from backend.app.routers.patient import router as patient_router
from backend.app.routers.timeline import router as timeline_router
from backend.app.routers.medications import router as medications_router
from backend.app.routers.ai import router as ai_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: create tables and seed initial clinical data
    try:
        Base.metadata.create_all(bind=engine)
        db = SessionLocal()
        try:
            seed_service.seed_initial_data(db)
        finally:
            db.close()
    except Exception as e:
        print(f"Error during startup database initialization: {e}")
    yield
    # Shutdown logic if any

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="Clinical-Grade Circadian & Medication Orchestration API with SQLite & Pydantic Validation",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Root endpoint
@app.get("/")
def root():
    return {
        "service": "ChronoMed API",
        "version": settings.VERSION,
        "docs": "/docs",
        "health": "/health",
        "api_v1": settings.API_V1_STR
    }

# Register Routers
app.include_router(health_router)
app.include_router(patient_router, prefix=settings.API_V1_STR)
app.include_router(timeline_router, prefix=settings.API_V1_STR)
app.include_router(medications_router, prefix=settings.API_V1_STR)
app.include_router(ai_router, prefix=settings.API_V1_STR)
