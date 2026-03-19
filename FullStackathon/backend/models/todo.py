#Mahika Bagri
#March 14 2026

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

    @classmethod
    def check_data(cls, name, due_date, length_minutes, tag):
        if not name:
            raise ValueError("The name of the task cannot be empty.")
        if len(name) > 50:
            raise ValueError("The name of the task cannot be longer than 50 characters.")
        
        if due_date is not None and due_date < date.today():
            raise ValueError("The due date cannot be in the past.")
        
        if length_minutes is not None and length_minutes < 0:
            raise ValueError("The length cannot be less than 0.")
        
        if tag is not None and len(tag) > 50:
            raise ValueError("A tag cannot be longer than 50 characters.")

    @classmethod
    def add(cls, db, curr_user, name, due_date, length_minutes, tag, arena_key):
        Todo.check_data(name, due_date, length_minutes, tag)
           
        db.add(Todo(name = name, due_date = due_date, length_minutes = length_minutes,
                           completion_status = False, tag = tag, arena_key = arena_key, user_key = curr_user.id))
        db.commit()

    @classmethod
    def delete(cls, db, curr_user, id):
        todo = db.get(Todo, id)

        if not curr_user: 
            raise HTTPException(status_code=401, detail="Please log in.")
        if not todo: 
            raise HTTPException(status_code=404, detail="Todo doesn't exist.")
        if todo.user_key != curr_user.id: 
            raise HTTPException(status_code=403, detail="Permission denied.")
        
        db.delete(todo)
        db.commit()


    @classmethod
    def update_completion_status(cls, db, curr_user, id, completion_status = True):

        todo = db.get(Todo, id)

        if not curr_user: 
            raise HTTPException(status_code=401, detail="Please log in.")
        if not todo: 
            raise HTTPException(status_code=404, detail="Todo doesn't exist.")
        if todo.user_key != curr_user.id: 
            raise HTTPException(status_code=403, detail="Permission denied.")

        todo.completion_status = completion_status
        
        db.commit()

    @classmethod
    def update_length(cls, db, curr_user, id, length_minutes=0):
        if length_minutes < 0:
            raise HTTPException(400, "Length cannot be negative")

        todo = db.get(Todo, id)

        if not curr_user: 
            raise HTTPException(status_code=401, detail="Please log in.")
        if not todo: 
            raise HTTPException(status_code=404, detail="Todo doesn't exist.")
        if todo.user_key != curr_user.id: 
            raise HTTPException(status_code=403, detail="Permission denied.")

        todo.length_minutes = length_minutes
        
        db.commit()
        
    @classmethod
    def update(id, db, curr_user, name, due_date = None, length_minutes = None, completion_status = False,
                tag = None):
        Todo.check_data(name, due_date, length_minutes, tag)

        todo = db.get(Todo, id)

        if not curr_user: 
            raise HTTPException(status_code=401, detail="Please log in.")
        if not todo: 
            raise HTTPException(status_code=404, detail="Todo doesn't exist.")
        if todo.user_key != curr_user.id: 
            raise HTTPException(status_code=403, detail="Permission denied.")

        todo.name = name
        todo.due_date = due_date
        todo.length_minutes = length_minutes
        todo.completion_status = completion_status
        todo.tag = tag
        
        db.commit()
