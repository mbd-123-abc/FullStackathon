#Mahika Bagri
#February 11 2026

from sqlalchemy import Column, Integer, String, Boolean, Date, ForeignKey, Sequence, desc, create_engine
from sqlalchemy.orm import sessionmaker, relationship, declarative_base, Session
from starlette import status
from datetime import date, timedelta, datetime
from enum import Enum, auto
from fastapi import FastAPI, HTTPException, APIRouter, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer
from pydantic import BaseModel
from typing import Optional
from passlib.hash import argon2 
from passlib.context import CryptContext
from jose import jwt, JWTError
from something import SECRET_KEY, ALGORITHM, TOKEN_EXPIRES

engine = create_engine('sqlite:///orm.db')

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

app = FastAPI()

scheme = OAuth2PasswordBearer(tokenUrl = "token")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: Optional[str] 

def create_token(data:dict, expires_delta: Optional[timedelta] = None):
    copy = data.copy()

    if expires_delta:
        expires = datetime.utcnow() + expires_delta
    else:
        expires = datetime.utcnow() + expires_delta(hours=TOKEN_EXPIRES) 
    copy.update({"exp":expires})

    en_jwt = jwt.encode(copy, SECRET_KEY, algorithm = ALGORITHM)
    return en_jwt

def verify_token(token:str) -> TokenData:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms = [ALGORITHM])
        username: str = payload.get("sub")
        if  username is None:
            raise HTTPException(status_code=401)
        return TokenData(username = username)
    except jwt.JWTError:
        raise HTTPException(status_code=401)

class Login(BaseModel):
    username: str
    password: str

class User(Base):
    __tablename__ = 'users'
    id = Column(Integer, primary_key = True)
    username = Column(String(50), nullable = False)
    password = Column(String(225), nullable = False)
    is_active = Column(Boolean, default = True)

    arenas = relationship('Arena', back_populates = 'user')
    todos = relationship('Todo', back_populates = 'user')

    @classmethod
    def check_password(cls, username, password, db):
        user = db.query(User).filter(User.username == username).first()
        if not argon2.verify(password,user.password):
            user = False
            raise HTTPException(status_code=401)
        
        return user

    @classmethod
    def check_input(cls, username, password, db):
        if not username:
            raise ValueError("The username cannot be empty.")
        if not password:
            raise ValueError("The password cannot be empty.")
        if len(password) < 8:
            raise ValueError("The password cannot be shorter than 8 characters.")
        if(db.query(User).filter(User.username == username).first()):
            raise ValueError("Username taken; Please try another.")
        if("'" in password or '"' in password or ';' in password or '--' in password or
        '*' in password or '\\' in password or '/' in password or '=' in password or
        '<' in password or '>' in password):
            raise ValueError("Password cannot contain \', \", ;, --, *, \\, /, =, <, >")
        
    @classmethod
    def add(cls, db, username, password, is_active = True):
        hash = argon2.hash(password)

        db.add(User(username = username, password = hash, is_active = is_active))
        db.commit()

class UserPy(BaseModel):
    username: str
    password: str
    is_active: bool = True

def get_user(token:str = Depends(scheme), db: Session = Depends(get_db)):
    token_data = verify_token(token) 
    user = db.query(User).filter(User.username == token_data.username).first()
    if user is None:
            raise HTTPException(status_code=401)
    return user

def get_active(curr_user: User = Depends(get_user)):
    if not curr_user.is_active:
            raise HTTPException(status_code=404)
    return curr_user

@app.post("/user")
def add(user: UserPy, db: Session = Depends(get_db)):
    try:
        User.check_input(user.username, user.password, db)
    except ValueError as error:
        raise HTTPException(status_code = 400, detail = str(error))
    
    User.add(db, user.username, user.password, True)
    return {"status": "user created"}

class Login(BaseModel):
    username: str
    password: str

@app.post("/token", response_model = Token)
def verify(login: Login, db: Session = Depends(get_db)):
    try:
        user = User.check_password(login.username, login.password, db)
    except ValueError as error:
        raise HTTPException(status_code = 401, detail = str(error))
    if not user.is_active:
        raise HTTPException(status_code = 404)
    
    token_expires = timedelta(hours = TOKEN_EXPIRES)
    token = create_token(data = {"sub":user.username}, expires_delta = token_expires)

    return {"access_token": token, "token_type": "bearer"}
    
class Themes(Enum):
    FORREST = auto()
    DAYDREAM = auto()
    STARRYNIGHT = auto()
    SAKURA = auto()

class Arena(Base):
    __tablename__ = 'arenas'
    id = Column(Integer, primary_key = True)
    name = Column(String(50), nullable = False)
    goal =  Column(String(20), nullable = False)
    completion_status = Column(Boolean)
    theme_key = Column(String(50))

    user_key = Column(Integer, ForeignKey('users.id'), nullable = False)
    todos = relationship('Todo', back_populates = 'arena')
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
    def update(db, curr_user, id, name, goal, completion_status = False, theme_key = "FORREST"):
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

class ArenaPy(BaseModel):

    name: str
    goal: str
    theme_key: str = "FORREST"
    completion_status: bool = False

@app.post("/arena")
def add(arena:ArenaPy, curr_user: User = Depends(get_user), db: Session = Depends(get_db)):
    try:
        Arena.check_data(arena.name, arena.goal, arena.theme_key)
    except ValueError as error:
        raise HTTPException(status_code = 400, detail = str(error))
    
    if not curr_user: 
            raise HTTPException(status_code=401, detail="Please log in.")
    
    Arena.add(db, curr_user, arena.name, arena.goal, arena.completion_status, arena.theme_key)

    return {"status": "arena created"}

@app.get("/arena")
def get_arenas(curr_user: User = Depends(get_user),db: Session = Depends(get_db)):
    if not curr_user: 
            raise HTTPException(status_code=401, detail="Please log in.")
    
    all_arenas = db.query(Arena).filter(Arena.user_key == curr_user.id).all()
    return all_arenas

@app.get("/arena/{id}")
def get_arena(id:int, curr_user: User = Depends(get_user),db: Session = Depends(get_db)):
    if not curr_user: 
            raise HTTPException(status_code=401, detail="Please log in.")
    
    return db.get(Arena, id)

@app.delete("/arena/{id}")
def delete_arena(id:int, curr_user: User = Depends(get_user),db: Session = Depends(get_db)):
    try:
        Arena.delete(db, curr_user, id)
    except Exception as error:
        raise error
    
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
    user_key = Column(Integer, ForeignKey('users.id'), nullable = False)
    arena = relationship('Arena', back_populates = "todos")
    user = relationship('User', back_populates = "todos")

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
        todo = db.get(id)

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
        if length_minutes is not None and length_minutes < 0:
            raise ValueError("The length cannot be less than 0.")

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

class TodosPy(BaseModel):

    name: str
    due_date: date = None
    length_minutes: int = None
    completion_status: bool = False
    tag: str = None
    arena_key: int = None

@app.post("/todo")
def add(todo:TodosPy, curr_user: User = Depends(get_user), db: Session = Depends(get_db)):
    if not curr_user: 
            raise HTTPException(status_code=401, detail="Please log in.")
    
    try:
        Todo.check_data(todo.name, todo.due_date, todo.length_minutes, todo.tag)
    except ValueError as error:
        raise HTTPException(status_code = 400, detail = str(error))
    
    Todo.add(db, curr_user, todo.name, todo.due_date, todo.length_minutes, todo.tag, todo.arena_key)

    return {"status": "todo created"}

@app.get("/todo/parking")
def get_parking(curr_user: User = Depends(get_user), db: Session = Depends(get_db)):
    if not curr_user: 
        raise HTTPException(status_code=401, detail="Please log in.")
    
    return db.query(Todo).filter(curr_user.id == Todo.user_key).filter(Todo.arena_key.is_(None)).all()

@app.delete("/todo/parking")
def get_parking(curr_user: User = Depends(get_user), db: Session = Depends(get_db)):
    if not curr_user: 
        raise HTTPException(status_code=401, detail="Please log in.")
    
    db.query(Todo).filter(curr_user.id == Todo.user_key).filter(Todo.arena_key.is_(None)).delete()
    db.commit()
    
    return {"status": "todo cleared"}

@app.get("/todo/arena/{arena_key}")
def get_arena_todos(arena_key, curr_user: User = Depends(get_user), db: Session = Depends(get_db)):
    arena = db.query(Arena).filter(Arena.id == arena_key).first()

    if not curr_user: 
        raise HTTPException(status_code=401, detail="Please log in.")
    if not arena: 
        raise HTTPException(status_code=404, detail="Todo doesn't exist.")
    if arena.user_key != curr_user.id: 
        raise HTTPException(status_code=403, detail="Permission denied.")

    return db.query(Todo).filter(Todo.arena_key == (arena_key)).order_by(desc(Todo.due_date)).all() 

@app.get("/todo/{id}")
def get_todo(id, curr_user: User = Depends(get_user), db: Session = Depends(get_db)):
    
    todo = db.get(Todo, id)

    if not curr_user: 
        raise HTTPException(status_code=401, detail="Please log in.")
    if not todo: 
        raise HTTPException(status_code=404, detail="Todo doesn't exist.")
    if todo.user_key != curr_user.id: 
        raise HTTPException(status_code=403, detail="Permission denied.")

    return todo

@app.patch("/todo/{id}")
def update_completion(id, curr_user: User = Depends(get_user), db: Session = Depends(get_db)):
    todo = db.get(Todo, id)

    try:
        todo.update_completion_status(db, curr_user, id, True)
    except Exception as error:
        raise error
    
    return {"status": "todo updated"}

@app.patch("/todo/{id}/{length_minutes}")
def update_length(id, length_minutes:int, curr_user: User = Depends(get_user), db: Session = Depends(get_db)):
    todo = db.get(Todo, id)
    
    try:
        todo.update_length(db, curr_user, id, length_minutes)
    except Exception as error:
        raise error

    return {"status": "todo updated"}


Base.metadata.create_all(bind=engine)
