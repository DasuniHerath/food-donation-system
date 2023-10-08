from fastapi import FastAPI, Query, WebSocket, Depends,  HTTPException
from fastapi.security import OAuth2PasswordBearer
from datetime import datetime
from models import request_body, member_body, request_item, conversions, Flags
from users import organization

# Category limit
CATEGORY_LIMIT = 3 

app = FastAPI()

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# A dictionary containing membor_body objects key is memberid
members_dict = {
    1: member_body(id=1, name="Siraj", email="dfjdnf@jkd.com", phone='0123456789'),
    2: member_body(id=2, name="Hassan", email="sknv@kfod.com", phone= '03432145')
}

# A dictionary containing tokens key is organization id 
users = {
    1: "token1",
    2: "token2",
    3: "token3"
}

organizations = []

# A dictionary containing Flags objects key is organization id
flags = {}


def get_current_user(token: str = Depends(oauth2_scheme)):
    user = None
    for userId, user_token in users.items():
        if user_token == token:
            user = userId
            break
    if not user:
        raise HTTPException(status_code=401, detail="Invalid authentication credentials")
    return user

def get_organization_by_id(org_id: int):
    for org in organizations:
        # print(org.id)
        if org.id == org_id:
            return org
    return None



def get_next_id(user_id):

    if len(get_organization_by_id(user_id).requests) == 0:
        return 1
    return get_organization_by_id(user_id).requests[-1].id + 1


@app.get("/")
async def root():
    return {"message": "The Help - Food Donation System"}

@app.post("/add_organization/")
async def add_organization(user_id: int = Depends(get_current_user)):
    if user_id in [o.id for o in organizations]:
        return {"message": "Organization already exists"}
    organizations.append(organization(id=user_id, requests=[], history=[], members=[]))
    # Creat a Flags object for the new organization and add it to dictionary with its user_id as a key
    flags[user_id] = Flags()
    return {"message": "Organization added successfully"}

# Post request to add a new request wich get category and amount as query parameters using request body
@app.post("/add_request/")
async def add_request(request_item: request_item, user_id: int = Depends(get_current_user)):
    # Check if the category is valid
    if request_item.category < 0 or request_item.category > CATEGORY_LIMIT:
        return {"message": "Invalid category"}
    # Check if the amount is valid
    if request_item.amount < 1:
        return {"message": "Invalid amount"}
    # Add the request to requests list
    get_organization_by_id(user_id).requests.append(request_body(id=get_next_id(user_id), category=request_item.category, amount=request_item.amount, time=datetime.now()))
    
    flags[user_id].requests_update.set()
    # Return the id of the request
    return {"message": "Request added successfully", "id": get_organization_by_id(user_id).requests[-1].id}

# Get request to get the status of all requests
@app.get("/get_requests/")
async def get_requests(user_id: int = Depends(get_current_user)):
    # Check if there is no requests
    if len(get_organization_by_id(user_id).requests) == 0:
        return {"message": "No requests"}
    # Go through each request and convert it to json
    requests_json = []
    for request in get_organization_by_id(user_id).requests:
        requests_json.append(request.dict())
    # Return the all requests
    return {"message": "Requests", "requests": requests_json}

# Delete request to delete a request using id
@app.delete("/delete_request/")
async def delete_request(id: int, user_id: int = Depends(get_current_user)):
    # Check if the id is valid
    if id < 1:
        return {"message": "Invalid id"}
    

    # TODO: There is a bug here


    # Delete and add the request to history but with status 3
    get_organization_by_id(user_id).requests[id-1].status = 3
    get_organization_by_id(user_id).history.append(get_organization_by_id(user_id).requests[id-1])
    flags[user_id].history_update.set()
    get_organization_by_id(user_id).requests.pop(id-1)
    flags[user_id].requests_update.set()
    # Return the all history    
    return {"message": "Request deleted successfully"}

# Connection to send organization's request history
@app.websocket("/orghistory")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    # await until client send a message
    token = await websocket.receive_text()
    user_id = get_current_user(token)
    flags[user_id].history_update.set()
    while True:
        # set the flag up
        await flags[user_id].history_update.wait()
        # Send history as a bytes stream
        await websocket.send_json(conversions().request_to_json(get_organization_by_id(user_id).history))
        flags[user_id].history_update.clear()
    await websocket.close()

# Connection to send organization's current requests
@app.websocket("/orgrequests")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    token = await websocket.receive_text()
    user_id = get_current_user(token)
    flags[user_id].requests_update.set()
    while True:
        await flags[user_id].requests_update.wait()
        # Send requests as a bytes stream
        await websocket.send_json(conversions().request_to_json(get_organization_by_id(user_id).requests))
        flags[user_id].requests_update.clear()
    await websocket.close()

@app.websocket("/orgMembers")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    token = await websocket.receive_text()
    user_id = get_current_user(token)
    flags[user_id].members_update.set()
    while True:
        await flags[user_id].members_update.wait()
        await websocket.send_json(conversions().request_to_json(get_organization_by_id(user_id).members))
        flags[user_id].members_update.clear()
    await websocket.close()

# Send client history
@app.get("/get_history/")
async def get_history(user_id: int = Depends(get_current_user)):
    # Check if there is no history
    if len(get_organization_by_id(user_id).history) == 0:
        return {"message": "No history"}
    # Return the all history
    return {"message": "History", "history": get_organization_by_id(user_id).history}

# Add a new memberid to members list
@app.post("/add_member/")
async def add_member(memberid: int, user_id: int = Depends(get_current_user)):
    # Check if the memberid is valid
    if memberid < 1:
        return {"message": "Invalid memberid"}
    # Add the memberid to members list
    get_organization_by_id(user_id).members.append(members_dict[memberid])
    # Set the flag up
    flags[user_id].members_update.set()
    # Return the id of the member
    return {"message": "Member added successfully", "id": memberid}


# Remove a member from members list
@app.delete("/remove_member/")
async def remove_member(memberid: int, user_id: int = Depends(get_current_user)):
    # Check if the memberid is valid
    if memberid < 1:
        return {"message": "Invalid memberid"}
    # Check if the memberid is in members list
    if memberid not in members_dict:
        return {"message": "Invalid memberid"}
    # Remove the memberid from members list
    get_organization_by_id(user_id).members.remove(members_dict[memberid])
    # Set the flag up
    flags[user_id].members_update.set()
    # Return the all history
    return {"message": "Member removed successfully"}