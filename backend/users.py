from models import request_body, member_body
from pydantic import BaseModel
from typing import List
import asyncio

# A class for a organization
class organization(BaseModel):

    id: int
    requests: List[request_body]
    history: List[request_body]
    members: List[member_body]