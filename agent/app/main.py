from fastapi import FastAPI
from pydantic import BaseModel
import httpx, os

NIM_URL = os.getenv("NIM_URL", "http://localhost:8000/v1/chat/completions")
NIM_KEY = os.getenv("NIM_API_KEY")

class Message(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    messages: list[Message]
    model: str = "llama3-8b-instruct"

app = FastAPI()

@app.post("/agent/chat")
async def chat(req: ChatRequest):
    headers = {"Authorization": f"Bearer {NIM_KEY}"}
    async with httpx.AsyncClient() as client:
        r = await client.post(NIM_URL, headers=headers, json=req.dict())
        r.raise_for_status()
        return r.json()
