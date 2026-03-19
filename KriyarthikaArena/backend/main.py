#Mahika Bagri
#March 19 2026

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routes import user, arena, todo

import subprocess

app = FastAPI()

@app.on_event("startup")
def startup_migrations():
    subprocess.run(["alembic", "upgrade", "head"])

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "https://kriyarthika-arena.vercel.app",
        "https://full-stackathon-mahika-s-projects.vercel.app",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(user.router)
app.include_router(arena.router)
app.include_router(todo.router)