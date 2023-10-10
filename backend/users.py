from models import request_body, member_body, delivery_body
from pydantic import BaseModel
from typing import List, Optional

# A class for a organization
class organization(BaseModel):

    id: int
    requests: List[request_body]
    history: List[request_body]
    members: List[member_body]

class donor(BaseModel):

    id: int
    requests: List[request_body]
    history: List[request_body]

class member(BaseModel):
    id: int
    status: bool
    delivery: Optional[delivery_body]
