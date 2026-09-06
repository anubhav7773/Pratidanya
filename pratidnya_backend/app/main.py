from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.services.opennyai_engine import OpenNyAIEngine
from app.api.v1.endpoints import health, precedents, kanoon, nlp, drafts, billing, trial_judgment, high_court_grounds, high_court_interlocutory, specialized_acts, scst_ni_acts

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Server Startup: Load OpenNyAI into RAM
    engine = OpenNyAIEngine.get_instance()
    engine.initialize()
    yield
    # Server Shutdown: Flush and cleanup memory
    engine.cleanup()

app = FastAPI(
    title="Pratidnya Legal NLP Microservice",
    description="District Court Criminal Chargesheet Deconstruction Engine (Asiverticals)",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router)
app.include_router(health.router, prefix="/api/v1")
app.include_router(precedents.router, prefix="/api/v1")
app.include_router(kanoon.router, prefix="/api/v1")
app.include_router(nlp.router, prefix="/api/v1")
app.include_router(drafts.router, prefix="/api/v1")
app.include_router(billing.router, prefix="/api/v1")
app.include_router(trial_judgment.router, prefix="/api/v1")
app.include_router(high_court_grounds.router, prefix="/api/v1")
app.include_router(high_court_interlocutory.router, prefix="/api/v1")
app.include_router(specialized_acts.router, prefix="/api/v1")
app.include_router(scst_ni_acts.router, prefix="/api/v1")
