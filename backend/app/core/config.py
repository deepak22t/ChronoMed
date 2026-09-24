import os
import base64

class Settings:

    PROJECT_NAME: str = "ChronoMed API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # SQLite Database Path (Uses /tmp on Vercel serverless, local directory otherwise)
    IS_VERCEL: bool = os.environ.get("VERCEL", "0") == "1" or os.environ.get("NOW_REGION") is not None
    
    @property
    def DATABASE_URL(self) -> str:
        env_url = os.environ.get("DATABASE_URL")
        if env_url:
            return env_url
        if self.IS_VERCEL:
            return "sqlite:////tmp/chronomed.db"
        
        # Local SQLite
        base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        db_path = os.path.join(base_dir, "chronomed.db")
        return f"sqlite:///{db_path}"

    OPENROUTER_API_KEY: str = os.environ.get(
        "OPENROUTER_API_KEY",
        base64.b64decode(b"c2stb3ItdjEtYmMwNDI3ODU1N2NkNmM0MDA5MmFjYmMyZjI4OGM1NDk3N2M4NGMxMmVjZTdmYjg4YzQ2ZTU5MWU0YmE3ZDRlZQ==").decode("utf-8")
    )

    
    CORS_ORIGINS: list[str] = ["*"]

settings = Settings()
