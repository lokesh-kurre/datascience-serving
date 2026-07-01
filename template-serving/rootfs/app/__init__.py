from fastapi import APIRouter, FastAPI
from pydantic import BaseModel


class InferenceRequest(BaseModel):
    model_name: str
    payload: dict


router = APIRouter()


@router.get("/health")
def health() -> dict:
    return {"status": "ok"}


@router.post("/infer-placeholder")
def infer_placeholder(req: InferenceRequest) -> dict:
    # Placeholder endpoint to demonstrate request shape for Triton infer calls.
    return {
        "message": "Wire tritonclient call here",
        "model_name": req.model_name,
        "payload_keys": list(req.payload.keys()),
    }


def create_app() -> FastAPI:
    app = FastAPI(title="Triton Frontend Template", version="0.1.0")
    app.include_router(router)
    return app
