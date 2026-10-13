import os
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from gemma_service import PurifyRequest, PurifyResponse, process_purification

app = FastAPI(
    title="Google AI Edge Eloquent API",
    description="Speech Polishing & Transformation Service powered by Google Gemma",
    version="1.0.0"
)

# Allow Flutter Web and local development origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

SAMPLE_PRESETS = [
    {
        "id": "meeting_sync",
        "title": "Messy Team Sync",
        "category": "Meeting",
        "raw_text": "Um, hey guys, uh, we had the sync today and, like, we decided to launch on Friday, but, um, Sarah needs to test the payment gateway first, you know? And also, like, we really need to check the mobile responsive layout before going live.",
        "recommended_mode": "meeting",
        "tone": "professional"
    },
    {
        "id": "product_brainstorm",
        "title": "Voice Note Idea Pitch",
        "category": "Product",
        "raw_text": "So, uh, the core idea is, like, what if developers could just, you know, dictate their documentation while driving, and, um, it automatically turns into markdown with clean code snippets and bullet points without having to type everything?",
        "recommended_mode": "bullets",
        "tone": "direct"
    },
    {
        "id": "urgent_bug",
        "title": "Production Bug Report",
        "category": "Engineering",
        "raw_text": "Uh yeah, so a client called and said, like, whenever they click the checkout button on iOS, um, it shows a 500 internal error code, so we gotta check the backend database connection pool and fix it ASAP.",
        "recommended_mode": "email",
        "tone": "professional"
    },
    {
        "id": "exec_update",
        "title": "Quarterly Executive Update",
        "category": "Executive",
        "raw_text": "Basically, uh, we exceeded our Q3 targets by like fifteen percent, and, um, customer acquisition cost went down, so the board should be, you know, pretty happy with the progress.",
        "recommended_mode": "brief",
        "tone": "executive"
    }
]

@app.get("/api/health")
def health_check():
    return {
        "status": "healthy",
        "engine": "Google Gemma (AI Edge Eloquent)",
        "version": "1.0.0"
    }

@app.get("/api/presets")
def get_presets():
    return {"presets": SAMPLE_PRESETS}

@app.post("/api/purify", response_model=PurifyResponse)
def purify_speech(req: PurifyRequest):
    if not req.raw_text or not req.raw_text.strip():
        raise HTTPException(status_code=400, detail="raw_text cannot be empty")
    return process_purification(req)

@app.middleware("http")
async def add_no_cache_header(request, call_next):
    response = await call_next(request)
    if request.url.path.endswith(".html") or request.url.path == "/" or request.url.path.endswith(".js"):
        response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
        response.headers["Pragma"] = "no-cache"
        response.headers["Expires"] = "0"
    return response

# Serve compiled Flutter web app if available
WEB_BUILD_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "build", "web")
if os.path.exists(WEB_BUILD_DIR):
    app.mount("/", StaticFiles(directory=WEB_BUILD_DIR, html=True), name="web_app")
