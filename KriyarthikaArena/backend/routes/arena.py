#Mahika Bagri
#March 10 2026

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import get_db
from auth import get_user
from models.arena import Arena
from models.user import User
from schemas.arena import ArenaPy

router = APIRouter()

@router.post("/arena")
def add(arena: ArenaPy, curr_user: User = Depends(get_user), db: Session = Depends(get_db)):

    try:
        Arena.check_data(arena.name, arena.goal, arena.theme_key)
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error))

    if not curr_user:
        raise HTTPException(status_code=401, detail="Please log in.")

    Arena.add(
        db,
        curr_user,
        arena.name,
        arena.goal,
        arena.completion_status,
        arena.theme_key
    )

    return {"status": "arena created"}

@router.get("/arena")
def get_arenas(curr_user: User = Depends(get_user), db: Session = Depends(get_db)):

    if not curr_user:
        raise HTTPException(status_code=401, detail="Please log in.")

    all_arenas = db.query(Arena).filter(Arena.user_key == curr_user.id).all()

    return all_arenas

@router.get("/arena/{id}")
def get_arena(id: int, curr_user: User = Depends(get_user), db: Session = Depends(get_db)):

    if not curr_user:
        raise HTTPException(status_code=401, detail="Please log in.")

    return db.get(Arena, id)

@router.delete("/arena/{id}")
def delete_arena(id: int, curr_user: User = Depends(get_user), db: Session = Depends(get_db)):

    try:
        Arena.delete(db, curr_user, id)
    except Exception as error:
        raise error

    return {"status": "arena deleted"}