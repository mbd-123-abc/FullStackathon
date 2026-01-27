#Mahika Bagri
#January 24 2026

from sqlalchemy import Column, Integer, String, Boolean, Date, ForeignKey, Sequence, desc, create_engine
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

class User(Base):
    __tablename__ = 'users'
    id = Column(Integer, Sequence('user_id_sequence'), primary_key = True)
    username = Column(String(50), nullable = False)
    password = Column(String(20), nullable = False)

    arenas = relationship('Arena', back_populates = 'users')

    @classmethod
    def check_input(cls, username, password):
        if not username:
            raise ValueError("The username cannot be empty.")
        if not password:
            raise ValueError("The password cannot be empty.")
        if(session.query(User).filter(User.username == username).exists()):
            raise ValueError("Username taken; Please try another.")
        if(password.contains('\'') or password.contains('\"') or 
           password.contains(';') or password.contains('--') or
           password.contains('*') or password.contains('\\') or 
           password.contains('/') or password.contains('=') or 
           password.contains('<') or password.contains('>')):
            raise ValueError("Password cannot contain \', \", ;, --, *, \\, /, =, <, >")
        
        @classmethod
        def add(cls, username, password):
            session.add(User(username, password))
            session.commit()

class UserPy(BaseModel):
    username: str
    password: str

@app.post("/user")
def add(user: UserPy):
    try:
        User.check_input(user.username, user.password)
    except ValueError as error:
        raise HTTPException(status_code = 400, detail = str(error))
    
    User.add(user.username, user.password)
    return {"status": "user created"}

class Themes(Enum):
    FORREST = auto()
    DAYDREAM = auto()
    STARRYNIGHT = auto()
    SAKURA = auto()

class Arena(Base):
    __tablename__ = 'arenas'
    id = Column(Integer, Sequence('arena_id_sequence'), primary_key = True)
    name = Column(String(50), nullable = False)
    goal =  Column(String(20), nullable = False)
    completion_status = Column(Boolean)
    theme_key = Column(String(50))

    todos = relationship('Todo', back_populates = 'arena')
    user_key = Column(Integer, ForeignKey('users.id'), nullable = False)
    user = relationship('User', back_populates = "arenas")

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
    def add(cls, name, goal, completion_status = False, theme_key = "FORREST"):
        Arena.check_data(name, goal, theme_key)

        session.add(Arena(name = name, goal = goal, completion_status = completion_status, theme_key = theme_key))
        session.commit()

    @classmethod
    def delete(cls, id):
        session.query(Todo).filter(Todo.arena_key == id).delete()

        arena = session.get(Arena, id)
        session.delete(arena)

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
    return session.get(Arena, id)

@app.delete("/arena/{id}")
def delete_arena(id:int):
    Arena.delete(id)
    return {"status": "arena deleted"}

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

    @classmethod
    def check_data(cls, name, due_date, length_minutes, tag):
        if not name:
            raise ValueError("The name of the task cannot be empty.")
        if len(name) > 50:
            raise ValueError("The name of the task cannot be longer than 50 characters.")
        
        if due_date is not None and due_date < date.today():
            raise ValueError("The due date cannot be in the past.")
        
        if length_minutes is not None and length_minutes < 0:
            raise ValueError("The due date cannot be in the past.")
        
        if tag is not None and len(tag) > 50:
            raise ValueError("A tag cannot be longer than 50 characters.")

    @classmethod
    def add(cls, name, due_date, length_minutes, tag, arena_key):
        Todo.check_data(name, due_date, length_minutes, tag)
                
        session.add(Todo(name = name, due_date = due_date, length_minutes = length_minutes,
                           completion_status = False, tag = tag, arena_key = arena_key))
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

class TodosPy(BaseModel):

    name: str
    due_date: date = None
    length_minutes: int = None
    completion_status: bool = False
    tag: str = None
    arena_key: int = None

@app.post("/todo")
def add(todo:TodosPy):
    try:
        Todo.check_data(todo.name, todo.due_date, todo.length_minutes, todo.tag)
    except ValueError as error:
        raise HTTPException(status_code = 400, detail = str(error))
    
    Todo.add(todo.name, todo.due_date, todo.length_minutes, todo.tag, todo.arena_key)

    return {"status": "todo created"}

@app.get("/todo/parking")
def get_parking():
    return session.query(Todo).filter(Todo.arena_key.is_(None)).all()

@app.delete("/todo/parking")
def get_parking():
    session.query(Todo).filter(Todo.arena_key.is_(None)).delete()
    session.commit()
    
    return {"status": "todo cleared"}

@app.get("/todo/arena/{arena_key}")
def get_arena_todos(arena_key):
    return session.query(Todo).filter(Todo.arena_key == (arena_key)).order_by(desc(Todo.due_date)).all() 

@app.get("/todo/{id}")
def get_todo(id):
    return session.get(Todo, id)

#@app.patch(/todo)
#def update_completion()

Base.metadata.create_all(bind=engine)