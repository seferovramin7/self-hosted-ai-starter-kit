import os
from fastapi import FastAPI, HTTPException
import httpx
from pydantic import BaseModel

app = FastAPI(title="N8N Webhook Caller")

# Get n8n webhook URL from environment variable
N8N_WEBHOOK_URL = os.getenv("N8N_WEBHOOK_URL", "http://n8n:5678/webhook/your-webhook-path")


class WebhookPayload(BaseModel):
    message: str
    data: dict = {}


@app.get("/")
async def root():
    """Health check endpoint"""
    return {"status": "ok", "service": "FastAPI N8N Webhook Caller"}


@app.get("/health")
async def health():
    """Health check endpoint"""
    return {"status": "healthy"}


@app.post("/trigger-webhook")
async def trigger_webhook(payload: WebhookPayload):
    """
    Trigger the n8n webhook with custom payload
    

    {
        "message": "Hello from FastAPI",
        "data": {"key": "value"}
    }
    """
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                N8N_WEBHOOK_URL,
                json=payload.dict(),
                timeout=30.0
            )
            response.raise_for_status()
            
            return {
                "status": "success",
                "webhook_url": N8N_WEBHOOK_URL,
                "response_status": response.status_code,
                "response_data": response.json() if response.content else None
            }
    except httpx.HTTPError as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to call n8n webhook: {str(e)}"
        )


@app.get("/trigger-webhook-simple")
async def trigger_webhook_simple():
    """
    Simple GET endpoint to trigger the n8n webhook with a default message
    """
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                N8N_WEBHOOK_URL,
                json={"message": "Triggered from FastAPI", "timestamp": "now"},
                timeout=30.0
            )
            response.raise_for_status()
            
            return {
                "status": "success",
                "webhook_url": N8N_WEBHOOK_URL,
                "response_status": response.status_code
            }
    except httpx.HTTPError as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to call n8n webhook: {str(e)}"
        )
