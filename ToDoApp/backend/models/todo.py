#Mahika Bagri
#March 10 2026

from sqlalchemy import Column, Integer, String, Boolean, Date, ForeignKey
from sqlalchemy.orm import relationship
from datetime import date
from fastapi import HTTPException

from database import Base

class Todo(Base):
    __tablename__ = "todos"

    id = Column(Integer, primary_key=True)
    name = Column(String(50), nullable=False)
    due_date = Column(Date)
    length_minutes = Column(Integer)
    completion_status = Column(Boolean)
    tag = Column(String(50))

    arena_key = Column(Integer, ForeignKey("arenas.id"), nullable=True)
    user_key = Column(Integer, ForeignKey("users.id"), nullable=False)

    arena = relationship("Arena", back_populates="todos")
    user = relationship("User", back_populates="todos")