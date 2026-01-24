#Mahika Bagri
#January 23 2026

from sqlalchemy import Column, Integer, String, Boolean, Date, ForeignKey, Sequence, CheckConstraint, create_engine
from sqlalchemy.orm import sessionmaker, relationship, declarative_base
from datetime import date
from enum import Enum, auto
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware

engine = create_engine('sqlite:///orm.db')

Session = sessionmaker(bind = engine)
session = Session()

Base = declarative_base()

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class Themes(Enum):
    FORREST = auto()
    DAYDREAM = auto()
    STARRYNIGHT = auto()
    SAKURA = auto()

class Arena(Base):
    __tablename__ = 'arenas'
    id = Column(Integer, Sequence('arena_id_sequence'), primary_key = True)
    name = Column(String(50), nullable = False)
    goal =  Column(String(150), nullable = False)
    completion_status = Column(Boolean)
    theme_key = Column(String(50))

    todos = relationship('Todo', back_populates = 'arena')

    @classmethod
    def check_data(cls, name, goal, theme_key):
        
        if not name:
            raise ValueError("The name of the arena cannot be empty.")
        if len(name) > 50:
            raise ValueError("The name of the arena cannot be longer than 50 characters.")
        
        if not goal:
            raise ValueError("The goal of the arena cannot be empty.")
        if len(goal) > 150:
            raise ValueError("The goal of the arena cannot be longer than 150 characters.")
        
        try:
            Themes[theme_key]
        except:
            raise ValueError("The theme is unavailable.")
        
    @classmethod
    def add(cls, name, goal, completion_status = False, theme_key = "FORREST"):
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
    def update(id, name, goal, completion_status = False, theme_key = "FORREST"):
        Arena.check_data(name, goal, theme_key)

        this = session.get(Arena, id)
        this.name = name
        this.goal = goal
        this.completion_status = completion_status
        this.theme_key = theme_key
        
        session.commit()

class ArenaPy(BaseModel):

    name: str
    goal: str
    theme_key: str = "FORREST"
    completion_status: bool = False

@app.post("/arena")
def add(arena:ArenaPy):
    try:
        Arena.check_data(arena.name, arena.goal, arena.theme_key)
    except ValueError as error:
        raise HTTPException(status_code = 400, detail = str(error))
    
    Arena.add(arena.name, arena.goal, arena.completion_status, arena.theme_key)

    return {"status": "arena created"}

@app.get("/arena")
def get_arenas():
    all_arenas = session.query(Arena).all()
    return all_arenas

@app.get("/arena/{id}")
def get_arena(id:int):
    arena = session.get(Arena, id)
    return arena

class Todo(Base):
    __tablename__ = 'todos'
    id = Column(Integer, primary_key = True)
    name = Column(String(50), nullable = False)
    due_date =  Column(Date)
    length_minutes = Column(Integer)
    completion_status = Column(Boolean)
    tag = Column(String(50))

    arena_key = Column(Integer, ForeignKey('arenas.id'), nullable = True)
    arena = relationship('Arena', back_populates = "todos")

    __table_args__ = (
        CheckConstraint('length_minutes >= 0', name = 'length_non_negative'),
    )

    @classmethod
    def check_data(cls, name, due_date, length_minutes, tag):
        if not name:
            raise ValueError("The name of the task cannot be empty.")
        if len(name) > 50:
            raise ValueError("The name of the task cannot be longer than 50 characters.")
        
        if due_date is not None and due_date < date.today():
            raise ValueError("The due date cannot be in the past.")
        
        if length_minutes < 0:
            raise ValueError("The due date cannot be in the past.")
        
        if tag is not None and len(tag) > 50:
            raise ValueError("A tag cannot be longer than 50 characters.")

    @classmethod
    def add(cls, name, due_date, length_minutes, tag):
        Todo.check_data(name, due_date, length_minutes, tag)
                
        session.add(Todo(name = name, due_date = due_date, length_minutes = length_minutes,
                           completion_status = False, tag = tag))
        session.commit()

    @classmethod
    def delete(cls, id):
        todo = session.get(id)
        session.delete(todo)
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

class TodosPy(BaseModel):

    name: str
    due_date: date = None
    length_minutes: int = 0
    completion_status: bool = False
    tag: str = None

@app.post("/todo")
def add(todo:TodosPy):
    try:
        Todo.check_data(todo.name, todo.due_date, todo.length_minutes, todo.tag)
    except ValueError as error:
        raise HTTPException(status_code = 400, detail = str(error))
    
    Todo.add(todo.name, todo.due_date, todo.length_minutes, todo.tag)

    return {"status": "todo created"}

@app.get("/todo/parking")
def get_parking():
    parking_todos = session.query(Todo).filter(Todo.arena_key.is_(None)).all()
    return parking_todos

@app.delete("/todo/parking")
def get_parking():
    parking_todos = session.query(Todo).filter(Todo.arena_key.is_(None)).delete()
    session.commit()
    
    return {"status": "todo cleared"}

Base.metadata.create_all(bind=engine)
