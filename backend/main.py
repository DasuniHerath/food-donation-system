from fastapi import FastAPI, Query, WebSocket
from datetime import datetime
from models import request_body, conversions
import asyncio

# Category limit
CATEGORY_LIMIT = 5 

app = FastAPI()



# A data request to store the request_body
requests = []
history = [
    request_body(id=1, name="Pizza Hut", category=1, amount=100, time=datetime.now(), status=1, member=1),
    request_body(id=2, name="Shabab", category=2, amount=200, time=datetime.now(), status=2, member=2),
]
members = []

# A flag to indicate that history list has changed 
history_update = asyncio.Event()


@app.get("/")
async def root():
    return {"message": "I am alive!"}

# Post request to add a new request wich get category and amount as query parameters using request body
@app.post("/add_request/")
async def add_request(category: int, amount: int):
    # Check if the category is valid
    if category < 0 or category > CATEGORY_LIMIT:
        return {"message": "Invalid category"}
    # Check if the amount is valid
    if amount < 1:
        return {"message": "Invalid amount"}
    # Add the request to requests list
    requests.append(request_body(id=len(requests)+1, category=category, amount=amount, time=datetime.now()))
    # Return the id of the request
    return {"message": "Request added successfully", "id": len(requests)}

# Get request to get the status of all requests
@app.get("/get_requests/")
async def get_requests():
    # Check if there is no requests
    if len(requests) == 0:
        return {"message": "No requests"}
    # Go through each request and convert it to json
    requests_json = []
    for request in requests:
        requests_json.append(request.dict())
    # Return the all requests
    return {"message": "Requests", "requests": requests_json}

# Delete request to delete a request using id
@app.delete("/delete_request/")
async def delete_request(id: int):
    # Check if the id is valid
    if id < 1 or id > len(requests):
        return {"message": "Invalid id"}
    # Delete and add the request to history but with status 3
    history.append(requests[id-1])
    history_update.set()
    requests.pop(id-1)
    # Return the all history    
    return {"message": "Request deleted successfully"}

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    history_update.set()
    while True:
        await history_update.wait()
        # Send history as a bytes stream
        await websocket.send_json(conversions().request_to_json(history))
        history_update.clear()
    await websocket.close()

 
# Send client history
@app.get("/get_history/")
async def get_history():
    # Check if there is no history
    if len(history) == 0:
        return {"message": "No history"}
    # Return the all history
    return {"message": "History", "history": history}

# Add a new memberid to members list
@app.post("/add_member/")
async def add_member(memberid: int):
    # Check if the memberid is valid
    if memberid < 1:
        return {"message": "Invalid memberid"}
    # Add the memberid to members list
    members.append(memberid)
    # Return the id of the member
    return {"message": "Member added successfully", "id": memberid}

# Send a request from requests to a client
@app.get("/send_request/")
async def send_request():
    # Check if there is no requests
    if len(requests) == 0:
        return {"message": "No requests"}
    # Check if there is no history
    if len(history) == 0:
        return {"message": "No history"}
    # Send the request
    history.append(requests[0])
    requests.pop(0)
    # Return the all history
    return {"message": "Request sent successfully"}

# Based on the client request, the server change status of the request
@app.post("/change_status/")
async def change_status(id: int, status: int):
    # Check if the id is valid
    if id < 1 or id > len(requests):
        return {"message": "Invalid id"}
    # Check if the status is valid
    if status < 0 or status > 3:
        return {"message": "Invalid status"}
    # Change the status of the request
    requests[id-1].status = status
    # Return the all history
    return {"message": "Status changed successfully"}

# Check if the client is assigned for a request
@app.post("/is_assigned/")
async def is_assigned(id: int, memberid: int):
    # Check if the id is valid
    if id < 1 or id > len(requests):
        return {"message": "Invalid id"}
    # Check if the memberid is valid
    if memberid < 1:
        return {"message": "Invalid memberid"}
    # Check if the memberid is in members list
    if memberid not in members:
        return {"message": "Invalid memberid"}
    # Check if the memberid is assigned for the request
    if requests[id-1].member != memberid:
        return {"message": "Not assigned"}
    # Return the all history
    return {"message": "Assigned"}