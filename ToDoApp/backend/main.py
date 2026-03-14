#Mahika Bagri
#March 10 2026

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routes import user, arena, todo

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "https://your-app-name.vercel.app",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(user.router)
app.include_router(arena.router)
app.include_router(todo.router)