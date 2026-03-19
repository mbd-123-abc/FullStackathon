#Mahika Bagri
#March 10 2026

from pydantic import BaseModel

class ArenaPy(BaseModel):
    name: str
    goal: str
    theme_key: str = "FORREST"
    completion_status: bool = False