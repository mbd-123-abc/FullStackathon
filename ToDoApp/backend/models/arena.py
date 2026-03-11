#Mahika Bagri
#March 10 2026

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