#Mahika Bagri
#March 10 2026

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import desc

from database import get_db
from auth import get_user
from models.todo import Todo
from models.arena import Arena
from models.user import User
from schemas.todo import TodosPy

router = APIRouter()

@router.post("/todo")
def add(todo: TodosPy, curr_user: User = Depends(get_user), db: Session = Depends(get_db)):

    if not curr_user:
        raise HTTPException(status_code=401, detail="Please log in.")

    try:
        Todo.check_data(todo.name, todo.due_date, todo.length_minutes, todo.tag)
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error))

    Todo.add(
        db,
        curr_user,
        todo.name,
        todo.due_date,
        todo.length_minutes,
        todo.tag,
        todo.arena_key
    )

    return {"status": "todo created"}

@router.get("/todo/parking")
def get_parking(curr_user: User = Depends(get_user), db: Session = Depends(get_db)):

    if not curr_user:
        raise HTTPException(status_code=401, detail="Please log in.")

    return (
        db.query(Todo)
        .filter(curr_user.id == Todo.user_key)
        .filter(Todo.arena_key.is_(None))
        .all()
    )

@router.delete("/todo/parking")
def clear_parking(curr_user: User = Depends(get_user), db: Session = Depends(get_db)):

    if not curr_user:
        raise HTTPException(status_code=401, detail="Please log in.")

    (
        db.query(Todo)
        .filter(curr_user.id == Todo.user_key)
        .filter(Todo.arena_key.is_(None))
        .delete()
    )

    db.commit()

    return {"status": "todo cleared"}

@router.get("/todo/arena/{arena_key}")
def get_arena_todos(arena_key: int, curr_user: User = Depends(get_user), db: Session = Depends(get_db)):

    arena = db.query(Arena).filter(Arena.id == arena_key).first()

    if not curr_user:
        raise HTTPException(status_code=401, detail="Please log in.")

    if not arena:
        raise HTTPException(status_code=404, detail="Todo doesn't exist.")

    if arena.user_key != curr_user.id:
        raise HTTPException(status_code=403, detail="Permission denied.")

    return (
        db.query(Todo)
        .filter(Todo.arena_key == arena_key)
        .order_by(desc(Todo.due_date))
        .all()
    )

@router.get("/todo/{id}")
def get_todo(id: int, curr_user: User = Depends(get_user), db: Session = Depends(get_db)):

    todo = db.get(Todo, id)

    if not curr_user:
        raise HTTPException(status_code=401, detail="Please log in.")

    if not todo:
        raise HTTPException(status_code=404, detail="Todo doesn't exist.")

    if todo.user_key != curr_user.id:
        raise HTTPException(status_code=403, detail="Permission denied.")

    return todo

@router.patch("/todo/{id}")
def update_completion(id: int, curr_user: User = Depends(get_user), db: Session = Depends(get_db)):

    try:
        Todo.update_completion_status(db, curr_user, id, True)
    except Exception as error:
        raise error

    return {"status": "todo updated"}

@router.patch("/todo/{id}/{length_minutes}")
def update_length(id: int, length_minutes: int, curr_user: User = Depends(get_user), db: Session = Depends(get_db)):

    try:
        Todo.update_length(db, curr_user, id, length_minutes)
    except Exception as error:
        raise error

    return {"status": "todo updated"}