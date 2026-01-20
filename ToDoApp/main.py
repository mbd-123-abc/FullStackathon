#Mahika Bagri
#January 19 2026

from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, Sequence, CheckConstraint, create_engine
from sqlalchemy.orm import sessionmaker, relationship, declarative_base
from datetime import date, time, datetime, timedelta
from enum import Enum, auto

engine = create_engine('sqllite:///orm.db')

Session = sessionmaker(bind = engine)
session = Session()

Base = declarative_base()

class Themes(Enum):
    NONE = auto()
    DAYDREAM = auto()
    STARRYNIGHT = auto()

class arena(Base):
    __tablename__ = 'arenas'
    id = Column(Integer, Sequence('item_id_sequence'), primary_key = True)
    name = Column(String(50), nullable = False)
    goal =  Column(String(150), nullable = False)
    theme_key = Column(String(50))

    Base.metadata.create_all(engine)

    def add(name, goal, theme_key = None):

        if not name:
            raise ValueError("The name of the task cannot be empty.")
        if len(name) > 50:
            raise ValueError("The name of the arena cannot be longer than 50 characters.")
        
        if not goal:
            raise ValueError("The name of the task cannot be empty.")
        if len(goal) > 150:
            raise ValueError("The goal of the arena cannot be longer than 150 characters.")
        
        theme_key = theme_key.upper().replace(" ","")
        try:
            Themes[theme_key]
        except:
            raise ValueError("The theme is unavailable.")
        
        session.add(arena(name = name, goal = goal, theme_key = theme_key))
        session.commit()

    def delete(name, goal, theme_key):

        session.delete(arena(name = name, goal = goal, theme_key = theme_key))
        session.commit()

class item(Base):
    __tablename__ = 'items'
    id = Column(Integer, primary_key = True)
    name = Column(String(50), nullable = False)
    due_date =  Column(date)
    length_minutes = Column(Integer)
    completion_status = Column(Boolean)
    tag = Column(String(50))

    __table_arguements__ = (
        CheckConstraint('length_minutes >= 0', name = 'length_non_negative'),
        CheckConstraint('due_date >= date.today()', name = 'due_date_in_future')
    )

    Base.metadata.create_all(engine)

    def add(name, due_date = None, length_minutes = None, tag = None):
        
        if not name:
            raise ValueError("The name of the task cannot be empty.")
        if len(name) > 50:
            raise ValueError("The name of the task cannot be longer than 50 characters.")
        
        if due_date < date.today():
            raise ValueError("The due date cannot be in the past.")
        
        if length_minutes < 0:
            raise ValueError("The due date cannot be in the past.")
        
        if len(tag) > 50:
            raise ValueError("A tag cannot be longer than 50 characters.")
        
        session.item(item(name = name, due_date = due_date, length_minutes = length_minutes,
                           completion_status = False, tag = tag))
        session.commit()

    def delete(name, due_date, length_minutes, tag):

        session.delete(item(name = name, due_date = due_date, length_minutes = length_minutes,
                           completion_status = False, tag = tag))
        session.commit()