#Mahika Bagri
#January 20 2026

from sqlalchemy import Column, Integer, String, Boolean, Date, ForeignKey, Sequence, CheckConstraint, create_engine
from sqlalchemy.orm import sessionmaker, relationship, declarative_base
from enum import Enum, auto
from fastapi import FastAPI, HTTPException

engine = create_engine('sqlite:///orm.db')

Session = sessionmaker(bind = engine)
session = Session()

Base = declarative_base()

class Themes(Enum):
    NONE = auto()
    DAYDREAM = auto()
    STARRYNIGHT = auto()

class Arena(Base):
    __tablename__ = 'arenas'
    id = Column(Integer, Sequence('arena_id_sequence'), primary_key = True)
    name = Column(String(50), nullable = False)
    goal =  Column(String(150), nullable = False)
    completion_status = Column(Boolean)
    theme_key = Column(String(50))

    todo = relationship('Todo', back_populates = 'arena')

    @classmethod
    def check_data(name, goal, theme_key):
        
        if not name:
            raise ValueError("The name of the arena cannot be empty.")
        if len(name) > 50:
            raise ValueError("The name of the arena cannot be longer than 50 characters.")
        
        if not goal:
            raise ValueError("The goal of the arena cannot be empty.")
        if len(goal) > 150:
            raise ValueError("The goal of the arena cannot be longer than 150 characters.")
        
        theme_key = theme_key.upper().replace(" ","")
        try:
            Themes[theme_key]
        except:
            raise ValueError("The theme is unavailable.")


    @classmethod
    def add(name, goal, completion_status = False, theme_key = None):
        Arena.check_data(name, goal, theme_key)

        session.add(Arena(name = name, goal = goal, completion_status = completion_status, theme_key = theme_key))
        session.commit()

    @classmethod
    def delete(id):
        arena_todos = session.query(Todo).filter(Todo.arena_key == id)
        for arena_todo in arena_todos: 
            Todo.delete(arena_todo.id)

        session.get(Arena, id).delete()

        session.commit()
    
    @classmethod
    def update(id, name, goal, completion_status = False, theme_key = None):
        Arena.check_data(name, goal, theme_key)

        this = session.get(Arena, id)
        this.name = name
        this.goal = goal
        this.completion_status = completion_status
        this.theme_key = theme_key
        
        session.commit()


class Todo(Base):
    __tablename__ = 'todos'
    id = Column(Integer, primary_key = True)
    name = Column(String(50), nullable = False)
    due_date =  Column(Date)
    length_minutes = Column(Integer)
    completion_status = Column(Boolean)
    tag = Column(String(50))

    arena_key = Column(Integer, ForeignKey('arenas.id'))
    arena = relationship('Arena', back_populates = "todos")

    __table_args__ = (
        CheckConstraint('length_minutes >= 0', name = 'length_non_negative'),
        CheckConstraint('due_date >= CURRENT_DATE', name = 'due_date_in_future')
    )

    @classmethod
    def check_data(name, due_date, length_minutes, tag):
        if not name:
            raise ValueError("The name of the task cannot be empty.")
        if len(name) > 50:
            raise ValueError("The name of the task cannot be longer than 50 characters.")
        
        if due_date < 'CURRENT_DATE'():
            raise ValueError("The due date cannot be in the past.")
        
        if length_minutes < 0:
            raise ValueError("The due date cannot be in the past.")
        
        if len(tag) > 50:
            raise ValueError("A tag cannot be longer than 50 characters.")

    @classmethod
    def add(name, due_date = None, length_minutes = None, tag = None):
        Todo.check_data(name, due_date, length_minutes, tag)
                
        session.todo(Todo(name = name, due_date = due_date, length_minutes = length_minutes,
                           completion_status = False, tag = tag))
        session.commit()

    @classmethod
    def delete(id):

        session.get(Todo, id).delete()
        session.commit()

    @classmethod
    def update(id, name, due_date = None, length_minutes = None, completion_status = False,
                tag = None):
        Todo.check_data(name, due_date, length_minutes, tag)

        this = session.get(Todo, id)
        this.name = name
        this.due_date = due_date
        this.length_minutes = length_minutes
        this.completion_status = completion_status
        this.tag = tag
        
        session.commit()

    @classmethod
    def filter_by_duedate(date = None):
        if date == None:
            session.query(Todo).order_by(Todo.due_date).all()
        else:
            session.query(Todo).filter(Todo.due_date == date).all()
        
        session.commit()

    @classmethod
    def filter_by_lengthminutes(length = None):
        if length == None:
            session.query(Todo).order_by(Todo.length_minutes).all()
        else:
            session.query(Todo).filter(Todo.length_minutes == length).all()
        
        session.commit()

    @classmethod
    def filter_by_completionstatus(status = False):
        session.query(Todo).filter(Todo.completion_status == status).all()
        
        session.commit()

    Base.metadata.create_all(engine)