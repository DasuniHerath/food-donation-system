from fastapi import FastAPI, Query, WebSocket, Depends,  HTTPException
from fastapi.security import OAuth2PasswordBearer
from datetime import datetime
from models import request_body, member_body, delivery_body, request_item, delivery_item, conversions, flagsDon, flagsOrg, flagsMem, reason
from users import organization, donor, member

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
orgUsers = {
    1: "token1",
    2: "token2",
    3: "token3"
}
donUsers = {
    1: "donor1",
    2: "donor2",
    3: "donor3"
}
memUsers = {
    1: "member1",
    2: "member2",
    3: "member3"
}

organizations = []
donors = {}
members = {}

# A dictionary containing Flags objects key is organization id
orgFlags = {}
donFlags = {}
memFlags = {}


def get_current_user(token: str = Depends(oauth2_scheme)):
    user = None
    for userId, user_token in orgUsers.items():
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



def get_next_id_org(user_id):

    if len(get_organization_by_id(user_id).requests) == 0:
        return 1
    return get_organization_by_id(user_id).requests[-1].id + 1

def get_next_id_don(user_id):
        if len(donors[user_id].requests) == 0:
            return 1
        return donors[user_id].requests[-1].id + 1

def find_the_index(user_id, id):
    for i in range(len(get_organization_by_id(user_id).requests)):
        if get_organization_by_id(user_id).requests[i].id == id:
            return i
    return -1

def find_the_index_donor(user_id, id):
    for i in range(len(donors[user_id].requests)):
        if donors[user_id].requests[i].id == id:
            return i
    return -1

def get_current_donUser(token: str = Depends(oauth2_scheme)):
    user = None
    for userId, user_token in donUsers.items():
        if user_token == token:
            user = userId
            break
    if not user:
        raise HTTPException(status_code=401, detail="Invalid authentication credentials")
    return user

def get_current_memUser(token: str = Depends(oauth2_scheme)):
    user = None
    for userId, user_token in memUsers.items():
        if user_token == token:
            user = userId
            break
    if not user:
        raise HTTPException(status_code=401, detail="Invalid authentication credentials")
    return user


@app.get("/")
async def root():
    return {"message": "The Help - Food Donation System"}

#-------------------------------Organization---------------------------------------------------------------

@app.post("/add_organization/")
async def add_organization(user_id: int = Depends(get_current_user)):
    if user_id in [o.id for o in organizations]:
        return {"message": "Organization already exists"}
    organizations.append(organization(id=user_id, requests=[], history=[], members=[]))
    # Creat a Flags object for the new organization and add it to dictionary with its user_id as a key
    orgFlags[user_id] = flagsOrg()
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
    get_organization_by_id(user_id).requests.append(request_body(id=get_next_id_org(user_id), category=request_item.category, amount=request_item.amount, time=datetime.now()))
    
    orgFlags[user_id].requests_update.set()
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


    # Delete and add the request to history but with status 3
    get_organization_by_id(user_id).requests[find_the_index(user_id, id)].status = 3
    get_organization_by_id(user_id).history.append(get_organization_by_id(user_id).requests[find_the_index(user_id, id)])
    orgFlags[user_id].history_update.set()
    get_organization_by_id(user_id).requests.pop(find_the_index(user_id, id))
    orgFlags[user_id].requests_update.set()
    # Return the all history    
    return {"message": "Request deleted successfully"}

# Connection to send organization's request history
@app.websocket("/orghistory")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    # await until client send a message
    token = await websocket.receive_text()
    user_id = get_current_user(token)
    orgFlags[user_id].history_update.set()
    while True:
        # set the flag up
        await orgFlags[user_id].history_update.wait()
        # Send history as a bytes stream
        await websocket.send_json(conversions().request_to_json(get_organization_by_id(user_id).history))
        orgFlags[user_id].history_update.clear()
    await websocket.close()

# Connection to send organization's current requests
@app.websocket("/orgrequests")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    token = await websocket.receive_text()
    user_id = get_current_user(token)
    orgFlags[user_id].requests_update.set()
    while True:
        await orgFlags[user_id].requests_update.wait()
        # Send requests as a bytes stream
        await websocket.send_json(conversions().request_to_json(get_organization_by_id(user_id).requests))
        orgFlags[user_id].requests_update.clear()
    await websocket.close()

@app.websocket("/orgMembers")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    token = await websocket.receive_text()
    user_id = get_current_user(token)
    orgFlags[user_id].members_update.set()
    while True:
        await orgFlags[user_id].members_update.wait()
        await websocket.send_json(conversions().request_to_json(get_organization_by_id(user_id).members))
        orgFlags[user_id].members_update.clear()
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
    orgFlags[user_id].members_update.set()
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
    orgFlags[user_id].members_update.set()
    # Return the all history
    return {"message": "Member removed successfully"}

#-------------------------------Donor---------------------------------------------------------------
@app.post("/add_donor/")
async def add_donor(user_id: int = Depends(get_current_donUser)):
    if user_id in donors:
        return {"message": "Donor already exists"}
    donors[user_id] = donor(id=user_id, requests=[], history=[])
    donFlags[user_id] = flagsDon()
    return {"message": "Donor added successfully"}

@app.post("/add_donation/")
async def add_donation(request_item: request_item, user_id: int = Depends(get_current_donUser)):
    if request_item.category < 0 or request_item.category > CATEGORY_LIMIT:
        return {"message": "Invalid category"}
    if request_item.amount < 1:
        return {"message": "Invalid amount"}
    donors[user_id].requests.append(request_body(id=get_next_id_don(user_id), category=request_item.category, amount=request_item.amount, time=datetime.now()))
    donFlags[user_id].requests_update.set()
    return {"message": "Donation added successfully", "id": donors[user_id].requests[-1].id}

@app.get("/get_donations/")
async def get_donations(user_id: int = Depends(get_current_donUser)):
    if len(donors[user_id].requests) == 0:
        return {"message": "No donations"}
    requests_json = []
    for request in donors[user_id].requests:
        requests_json.append(request.dict())
    return {"message": "Donations", "requests": requests_json}

@app.delete("/reject_donation/")
async def reject_donation(id: int, user_id: int = Depends(get_current_donUser)):
    if id < 1:
        return {"message": "Invalid id"}
    donors[user_id].requests[find_the_index_donor(user_id, id)].status = 3
    donors[user_id].history.append(donors[user_id].requests[find_the_index_donor(user_id, id)])
    donors[user_id].requests.pop(find_the_index_donor(user_id, id))
    donFlags[user_id].requests_update.set()
    donFlags[user_id].history_update.set()

    return {"message": "Donation rejected successfully"}

@app.get("/get_donation_history/")
async def get_donation_history(user_id: int = Depends(get_current_donUser)):
    if len(donors[user_id].history) == 0:
        return {"message": "No history"}
    return {"message": "History", "history": donors[user_id].history}

# End point for changing status of a particular donation
@app.put("/accept_donation/")
async def change_status(id: int, user_id: int = Depends(get_current_donUser)):
    # Check if the id is valid
    if id < 1:
        return {"message": "Invalid id"}
    # Change the status of the donation
    donors[user_id].requests[find_the_index_donor(user_id, id)].status = 2
    # Set the flag up
    donFlags[user_id].requests_update.set()
    # Return the all history
    return {"message": "Status changed successfully"}


@app.websocket("/donorrequests")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    token = await websocket.receive_text()
    user_id = get_current_donUser(token)
    donFlags[user_id].requests_update.set()
    while True:
        await donFlags[user_id].requests_update.wait()
        await websocket.send_json(conversions().request_to_json(donors[user_id].requests))
        donFlags[user_id].requests_update.clear()
    await websocket.close()

@app.websocket("/donorhistory")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    token = await websocket.receive_text()
    user_id = get_current_donUser(token)
    donFlags[user_id].history_update.set()
    while True:
        await donFlags[user_id].history_update.wait()
        await websocket.send_json(conversions().request_to_json(donors[user_id].history))
        donFlags[user_id].history_update.clear()
    await websocket.close()

#-------------------------------Member---------------------------------------------------------------
# Add a member to members dictionary
@app.post("/load_member/")
async def load_member(user_id: int = Depends(get_current_memUser)):
    if user_id in members:
        return {"message": "Member already exists"}
    members[user_id] = member(id=user_id, status=False, delivery=None)
    memFlags[user_id] = flagsMem()
    return {"message": "Member added successfully"}


# Assign a delivery to a member
@app.post("/assign_delivery/")
async def assign_delivery(delivery_item: delivery_item, user_id: int = Depends(get_current_memUser)):
    # Check if the category is valid
    if delivery_item.category < 0 or delivery_item.category > CATEGORY_LIMIT:
        return {"message": "Invalid category"}
    # Check if the amount is valid
    if delivery_item.amount < 1:
        return {"message": "Invalid amount"}
    # Add the delivery to the member
    members[user_id].delivery = delivery_body(
        id=delivery_item.id, 
        category=delivery_item.category, 
        amount=delivery_item.amount, 
        time=datetime.now(), 
        donorAddress=delivery_item.donorAddress, 
        communityAddress=delivery_item.communityAddress
    )
    # Return the id of the delivery
    return {"message": "Delivery assigned successfully", "id": delivery_item.id}

# Change the status of a member
@app.put("/change_status/")
async def change_status(status: bool, user_id: int = Depends(get_current_memUser)):
    # Check if the status is valid
    if status not in [True, False]:
        return {"message": "Invalid status"}
    # Change the status of the member
    members[user_id].status = status
    # Return the all history
    return {"message": "Status changed successfully"}

# Get the status of a member
@app.get("/get_status/")
async def get_status(user_id: int = Depends(get_current_memUser)):
    # Return the status of the member
    return {"message": "Status", "status": members[user_id].status}

# Get a message about a reason and areject a delivery
@app.delete("/reject_delivery/")
async def reject_delivery(reason: reason, user_id: int = Depends(get_current_memUser)):
    # Check if the reason is valid
    if reason.reason == "":
        return {"message": "Invalid reason"}
    # Check if the member has a delivery
    if members[user_id].delivery == None:
        return {"message": "No delivery"}
    # Reject the delivery
    members[user_id].delivery = None
    # Return the all history
    # Set the flag up
    memFlags[user_id].delivery_update.set()
    print(reason.reason)
    return {"message": "Delivery rejected successfully"}

@app.websocket("/memberdelivery")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    token = await websocket.receive_text()
    user_id = get_current_memUser(token)
    memFlags[user_id].delivery_update.set()
    while True:
        await memFlags[user_id].delivery_update.wait()
        await websocket.send_json(conversions.request_to_json([] if members[user_id].delivery == None else [members[user_id].delivery]))
        memFlags[user_id].delivery_update.clear()
    await websocket.close()


