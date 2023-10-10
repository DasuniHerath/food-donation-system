from datetime import datetime
from pydantic import BaseModel
import asyncio

# Request should have a body with the following fields
        # A unique id for each request
        # A string to indicate the name of donor (by default it is anonymous)
        # An integer to indicate a category
        # An integer to indicate amount
        # Time and date of request
        # An integer to indicate the status of request (by default it is 0)
class request_body(BaseModel):
    id: int
    name: str = "Searching for donor"
    category: int
    amount: int
    time: datetime = datetime.now()
    status: int = 0
    member: int = 0

    # Convert datetime to string in ISO 8601 format
    def dict(self):
        return {
            **super().model_dump(),
            "time": self.time.isoformat() # Convert datetime to string in ISO 8601 format
        }
    
class delivery_body(BaseModel):
    id: int
    name: str = "Restaurant"
    category: int
    amount: int
    time: datetime = datetime.now()
    status: int = 0
    donorAddress: str
    communityAddress: str

    # Convert datetime to string in ISO 8601 format
    def dict(self):
        return {
            **super().model_dump(),
            "time": self.time.isoformat() # Convert datetime to string in ISO 8601 format
        }

class member_body(BaseModel):
    id: int
    name: str
    email: str
    phone: str
    status: int = 0

class request_item(BaseModel):
    category: int
    amount: int

class delivery_item(BaseModel):
    id: int
    category: int
    amount: int
    donorAddress: str
    communityAddress: str

class reason(BaseModel):
    reason: str

# Convert a request_body to json
class conversions:
    @staticmethod
    def request_to_json(requests):
        # return json.dumps([request.dict() for request in requests])
        requests_json = []
        if isinstance(requests, tuple):
            requests = [requests]
        for request in requests:
            requests_json.append(request.dict())
        return requests_json
    
# A class containing three asuncio events
class flagsOrg():
    def __init__(self):
        self.history_update = asyncio.Event()
        self.requests_update = asyncio.Event()
        self.members_update = asyncio.Event()
    
    history_update: asyncio.Event
    requests_update: asyncio.Event
    members_update: asyncio.Event

class flagsDon():
    def __init__(self):
        self.history_update = asyncio.Event()
        self.requests_update = asyncio.Event()

    history_update: asyncio.Event
    requests_update: asyncio.Event

class flagsMem():
    def __init__(self):
        self.delivery_update = asyncio.Event()
    
    delivery_update: asyncio.Event