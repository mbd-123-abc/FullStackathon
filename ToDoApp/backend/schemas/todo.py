#Mahika Bagri
#March 10 2026

from pydantic import BaseModel
from datetime import date

class TodosPy(BaseModel):
    name: str
    due_date: date = None
    length_minutes: int = None
    completion_status: bool = False
    tag: str = None
    arena_key: int = None