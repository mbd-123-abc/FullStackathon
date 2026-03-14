#Mahika Bagri
#March 14 2026

from sqlalchemy import Column, Integer, String, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from fastapi import HTTPException
from enum import Enum, auto

from database import Base
from models.todo import Todo

class Themes(Enum):
    FORREST = auto()
    DAYDREAM = auto()
    STARRYNIGHT = auto()
    SAKURA = auto()

class Arena(Base):
    __tablename__ = "arenas"

    id = Column(Integer, primary_key=True)
    name = Column(String(50), nullable=False)
    goal = Column(String(20), nullable=False)
    completion_status = Column(Boolean)
    theme_key = Column(String(50))

    user_key = Column(Integer, ForeignKey("users.id"), nullable=False)

    todos = relationship("Todo", back_populates="arena")
    user = relationship("User", back_populates="arenas")

    @classmethod
    def check_data(cls, name, goal, theme_key):
        
        if not name:
            raise ValueError("The name of the arena cannot be empty.")
        if len(name) > 50:
            raise ValueError("The name of the arena cannot be longer than 50 characters.")
        
        if not goal:
            raise ValueError("The goal of the arena cannot be empty.")
        if len(goal) > 20:
            raise ValueError("The goal of the arena cannot be longer than 20 characters.")
        
        try:
            Themes[theme_key]
        except:
            raise ValueError("The theme is unavailable.")
        
    @classmethod
    def add(cls, db, curr_user, name, goal, completion_status, theme_key):
        Arena.check_data(name, goal, theme_key)

        db.add(Arena(name = name, goal = goal, completion_status = completion_status, theme_key = theme_key, user_key = curr_user.id))
        db.commit()

    @classmethod
    def delete(cls, db, curr_user, id):
        arena = db.get(Arena, id)

        if not curr_user: 
            raise HTTPException(status_code=401, detail="Please log in.")
        if not arena: 
            raise HTTPException(status_code=404, detail="Arena doesn't exist.")
        if arena.user_key != curr_user.id:
            raise HTTPException(status_code=403, detail="Permission denied.")

        db.query(Todo).filter(Todo.arena_key == id).delete()
        db.delete(arena)

        db.commit()
    
    @classmethod
    def update(cls, db, curr_user, id, name, goal, completion_status = False, theme_key = "FORREST"):
        Arena.check_data(name, goal, theme_key)

        arena = db.get(Arena, id)

        if not curr_user: 
            raise HTTPException(status_code=401, detail="Please log in.")
        if not arena: 
            raise HTTPException(status_code=404, detail="Arena doesn't exist.")
        if arena.user_key != curr_user.id:
            raise HTTPException(status_code=403, detail="Permission denied.")

        arena.name = name
        arena.goal = goal
        arena.completion_status = completion_status
        arena.theme_key = theme_key
        
        db.commit()
