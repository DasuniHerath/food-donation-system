import time
from fastapi import FastAPI, Query, WebSocket, Depends,  HTTPException, BackgroundTasks, File, UploadFile
from fastapi.security import OAuth2PasswordBearer
from datetime import datetime
from models import *
from users import organization, donor, member
from sqlalchemy.orm import Session
from database import SessionLocal, engine


# Category limit
CATEGORY_LIMIT = 3

# Create all tables
MemberSQL.metadata.create_all(bind=engine)
# Create a session
db = SessionLocal()

app = FastAPI()

# Authentication scheme
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# A dictionary containing membor_body objects key is memberid
members_dict = {}

# A dictionary containing tokens key is organization id 
#TODO : Use databases either only or for loading data to this dictionaries
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

# Data structures to store active users
organizations = []
donors = {}
members = {}

# A dictionary containing Flags objects key is organization id
orgFlags = {}
donFlags = {}
memFlags = {}

# A dictionary with key is donor id and and value is a organitation id and request id pairs
donor_org_requests = {}
# A dictionary with key is member id and value is a tuple of orgnitation id, orgrequest id and donor id and donor request id
member_don_org_requests = {}

# Find donors for a request
def find_donors(orgId: int, request: request_body):
    # add to the requsts in donor objects in donors
    for donor in donors.values():
        # create a new request object from the request and change its id to the donor requests last id + 1
        next_id = get_next_id_don(donor.id)
        # Fetch organization name from db
        tmp_org = db.query(OrganizationSQL).filter(OrganizationSQL.id == orgId).first()
        request = request_body(id=next_id, name= tmp_org.name, category=request.category, amount=request.amount, time=request.time, comAddress=request.comAddress)
        donor.requests.append(request)
        # add the request to the donor_org_requests dictionary
        # if the donor is not in the dictionary add it
        if donor.id not in donor_org_requests:
            donor_org_requests[donor.id] = []
        # add the request to the donor_org_requests dictionary
        donor_org_requests[donor.id].append((next_id, orgId, request.id))
        print(donor_org_requests)
        donFlags[donor.id].requests_update.set()

async def  handle_delivery_update(user_id: int, newState: int): 
    # Update the status of the delivery in organization and donor
    org_index = find_the_index(member_don_org_requests[user_id][0], member_don_org_requests[user_id][1])
    don_index = find_the_index_donor(member_don_org_requests[user_id][2], member_don_org_requests[user_id][3])
    get_organization_by_id(member_don_org_requests[user_id][0]).requests[org_index].status = newState
    donors[member_don_org_requests[user_id][2]].requests[don_index].status = newState
    orgFlags[member_don_org_requests[user_id][0]].requests_update.set()
    donFlags[member_don_org_requests[user_id][2]].requests_update.set()

    if newState != 7:
        return

    # wait for the rating
    await memFlags[user_id].rating_update.wait()

    # Remove from requests
    get_organization_by_id(member_don_org_requests[user_id][0]).requests.pop(org_index)
    donors[member_don_org_requests[user_id][2]].requests.pop(don_index)
    members[user_id].delivery = None
    orgFlags[member_don_org_requests[user_id][0]].requests_update.set()
    donFlags[member_don_org_requests[user_id][2]].requests_update.set()
    memFlags[user_id].delivery_update.set()

    # Clear rating flag
    memFlags[user_id].rating_update.clear()

    # TODO: Remove from member_don_org_requests dictionary and member_don_org_requests dictionary

def handle_rating_update(rate: int, user_id: int):
    new_rating = RatingSQL(
        orgid=get_organization_by_id(member_don_org_requests[user_id][0]).id,
        donid=donors[member_don_org_requests[user_id][2]].id,
        memid=user_id,
        rate=rate
    )
    # Add the new rating to the session
    db.add(new_rating)

    # Commit the transaction
    db.commit()
    memFlags[user_id].rating_update.set()

# Find the id of the current user
def get_current_user(token: str = Depends(oauth2_scheme)):
    user = None
    for userId, user_token in orgUsers.items():
        if user_token == token:
            user = userId
            break
    if not user:
        raise HTTPException(status_code=401, detail="Invalid authentication credentials")
    return user

# Get orgniazation by its id
def get_organization_by_id(org_id: int) -> organization: 
    for org in organizations:
        if org.id == org_id:
            return org
    return None

# Get the next id for a request
def get_next_id_org(user_id):

    if len(get_organization_by_id(user_id).requests) == 0:
        return 1
    return get_organization_by_id(user_id).requests[-1].id + 1

# Get the next id for a donor
def get_next_id_don(user_id):
        if len(donors[user_id].requests) == 0:
            return 1
        return donors[user_id].requests[-1].id + 1

# Get the next id for a member
def find_the_index(user_id, id):
    for i in range(len(get_organization_by_id(user_id).requests)):
        if get_organization_by_id(user_id).requests[i].id == id:
            return i
    return -1

# Find the index of a a request in a donor
def find_the_index_donor(user_id, id):
    for i in range(len(donors[user_id].requests)):
        if donors[user_id].requests[i].id == id:
            return i
    return -1

# Get the current donor id by its token
def get_current_donUser(token: str = Depends(oauth2_scheme)):
    user = None
    for userId, user_token in donUsers.items():
        if user_token == token:
            user = userId
            break
    if not user:
        raise HTTPException(status_code=401, detail="Invalid authentication credentials")
    return user

# Get the currtent memeber id by its token
def get_current_memUser(token: str = Depends(oauth2_scheme)):
    user = None
    for userId, user_token in memUsers.items():
        if user_token == token:
            user = userId
            break
    if not user:
        raise HTTPException(status_code=401, detail="Invalid authentication credentials")
    return user

# Find wheather not found requests are on the orgaization requests list
def find_not_found_requests(user_id: int):
    for req in get_organization_by_id(user_id).requests:
        if req.status == 0:
            return True
    return False

@app.get("/")
async def root():
    return {"message": "The Help - Food Donation System"}

#-------------------------------Organization---------------------------------------------------------------

# Load an organization into the organization list
@app.post("/add_organization/")
async def add_organization(user_id: int = Depends(get_current_user)):
    if user_id in [o.id for o in organizations]:
        return {"message": "Organization already exists"}
    # TODO: Load histoy from the database
    organizations.append(organization(id=user_id, requests=[], history=[], members=[]))
    # Creat a Flags object for the new organization and add it to dictionary with its user_id as a key
    orgFlags[user_id] = flagsOrg()
    return {"message": "Organization added successfully"}

# Post request to add a new request wich get category and amount as query parameters using request body
@app.post("/add_request/")
async def add_request(request_item: request_item, background_tasks: BackgroundTasks, user_id: int = Depends(get_current_user),):
    # Check weather a member is in the organization
    if len(get_organization_by_id(user_id).members) == 0:
        return {"message": "No members"}
    # Check if the category is valid
    if request_item.category < 0 or request_item.category > CATEGORY_LIMIT:
        return {"message": "Invalid category"}
    # Check if the amount is valid
    if request_item.amount < 1:
        return {"message": "Invalid amount"}
    
    # Get the correct delivery address
    if request_item.comAddress == 'default':
        org = db.query(OrganizationSQL).filter(OrganizationSQL.id == user_id).first()
        request_item.comAddress = org.Address
        
    # create a request object
    newReq = request_body(
        id=get_next_id_org(user_id),
        category=request_item.category, 
        amount=request_item.amount, 
        time=datetime.now(),
        comAddress= request_item.comAddress)

    # Add the request to requests list
    get_organization_by_id(user_id).requests.append(newReq)
    orgFlags[user_id].requests_update.set()


    # Find donors for the request
    background_tasks.add_task(find_donors, user_id, newReq)

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

    # delete the request from the donor_org_requests dictionary and all donors
    for key, value in donor_org_requests.items():
        for req in value:
            if req[2] == id:
                index = find_the_index_donor(key, req[0])
                donors[key].requests[index].status = 3
                donors[key].history.append(donors[key].requests[index])
                donors[key].requests.pop(index)
                donFlags[key].requests_update.set()
                donFlags[key].history_update.set()
                donor_org_requests[key].remove(req)



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
    # Fetch the member from db
    tmp_member = db.query(MemberSQL).filter(MemberSQL.id == memberid).first()
    # if the member is not in db return error
    if tmp_member == None:
        return {"message": "Invalid memberid"}
    # Check wheather the member is loaded
    if memberid not in members:
        return {"message": "Member is not loaded"}
    # Check wheather the member is already in the members list
    if memberid in [member.id for member in get_organization_by_id(user_id).members]:
        return {"message": "Member already exists"}
    # convert the member to member_body
    member = member_body(id=tmp_member.id, name=tmp_member.name, email=tmp_member.email, phone=tmp_member.phone)
    # Add the memberid to members list
    get_organization_by_id(user_id).members.append(member)
    # Add the memberid to members dictionary
    members_dict[memberid] = member
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
    temp_org = get_organization_by_id(user_id)
    if members[memberid].delivery != None:
        return {"message": "A delivery is assigned to the member"}
    print(find_not_found_requests(user_id))
    print(len(temp_org.members))
    if find_not_found_requests(user_id) and len(temp_org.members) == 1:
        return {"message": "Not found requests are in the list"}
    temp_org.members.remove(members_dict[memberid])
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

    # delete the request from the donor_org_requests dictionary by its id
    for req_id in donor_org_requests[user_id]:
        if req_id[0] == id:
            donor_org_requests[user_id].remove(req_id)
            break
    print(donor_org_requests)

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

    # get the organization id and request id from donor_org_requests dictionary
    org_id = None
    req_id = None
    for key, value in donor_org_requests.items():
        if key == user_id:
            for req in value:
                if req[0] == id:
                    org_id = req[1]
                    req_id = req[2]
                    break

    # Change the status of the request in the organization
    index = find_the_index(org_id, req_id)
    get_organization_by_id(org_id).requests[index].status = 2
    # fetch donor name from db
    tmp_donor = db.query(DonorSQL).filter(DonorSQL.id == user_id).first()
    get_organization_by_id(org_id).requests[index].name = tmp_donor.name

    # Set org flag up    
    orgFlags[org_id].requests_update.set()

    for key, value in donor_org_requests.items():
        if key != user_id:
            for req in value:
                if req[2] == req_id:
                    # Remove from donor
                    donors[key].requests.pop(find_the_index_donor(key, req[0]))
                    donFlags[key].requests_update.set()
                    donor_org_requests[key].remove(req)
                    break           

    # Get an available member from the organization and assign the delivery to him
    for member in get_organization_by_id(org_id).members:
        if members[member.id].status == 1 and members[member.id].delivery == None:
            members[member.id].delivery = delivery_body(
                id=id, 
                category=donors[user_id].requests[find_the_index_donor(user_id, id)].category, 
                amount=donors[user_id].requests[find_the_index_donor(user_id, id)].amount, 
                time=datetime.now(), 
                donorAddress=tmp_donor.Address, 
                communityAddress=donors[user_id].requests[find_the_index_donor(user_id, id)].comAddress,
                status=4
            )
            # Update member in request_body for both organization and donor
            get_organization_by_id(org_id).requests[find_the_index(org_id, req_id)].member = member.id
            donors[user_id].requests[find_the_index_donor(user_id, id)].member = member.id
            # Set the flags up
            orgFlags[org_id].requests_update.set()
            donFlags[user_id].requests_update.set()
            memFlags[member.id].delivery_update.set()
            break
    # TODO: If there is no available member
    

    # Add to member_don_org_requests dictionary
    member_don_org_requests[member.id] = (org_id, req_id, user_id, id)

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

    memFlags[user_id].delivery_update.set()
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

    # Find the indexes of requests
    org_index = find_the_index(member_don_org_requests[user_id][0], member_don_org_requests[user_id][1])
    don_index = find_the_index_donor(member_don_org_requests[user_id][2], member_don_org_requests[user_id][3])
    # Change status in organization and donor
    get_organization_by_id(member_don_org_requests[user_id][0]).requests[org_index].status = 3
    donors[member_don_org_requests[user_id][2]].requests[don_index].status = 3
    # Add to history
    get_organization_by_id(member_don_org_requests[user_id][0]).history.append(get_organization_by_id(member_don_org_requests[user_id][0]).requests[org_index])
    donors[member_don_org_requests[user_id][2]].history.append(donors[member_don_org_requests[user_id][2]].requests[don_index])
    # Remove from requests
    get_organization_by_id(member_don_org_requests[user_id][0]).requests.pop(org_index)
    donors[member_don_org_requests[user_id][2]].requests.pop(don_index)

    return {"message": "Delivery rejected successfully"}

# Update the status of a delivery
@app.put("/update_delivery/")
async def update_delivery(newState: int, background_tasks: BackgroundTasks, user_id: int = Depends(get_current_memUser)):
    # Check if the new state is valid
    if newState not in [1, 2, 3, 4, 5, 6, 7]:
        return {"message": "Invalid state"}
    # Check if the member has a delivery
    if members[user_id].delivery == None:
        return {"message": "No delivery"}
    # Update the status of the delivery
    members[user_id].delivery.status = newState
    # Set the flag up
    memFlags[user_id].delivery_update.set()
    background_tasks.add_task(handle_delivery_update, user_id, newState)
    return {"message": "Delivery updated successfully"}

# Add ratings to a particular delivery
@app.put("/add_rating/")
async def add_rating(rate: int, background_tasks: BackgroundTasks, user_id: int = Depends(get_current_memUser)):
    # Ratings are between 1 and 5
    if rate <1 or rate >5:
        return {"message": "Ratings should be between 1 and 5"}
    # Reject ratings given before finishing delivery
    if members[user_id].delivery.status != 7:
        return {"message": "Cannot rate at this point"}
    background_tasks.add_task(handle_rating_update, rate, user_id)
    return {"message": "Your rate added to the donor"}
    

# Connection to send member's delivery to the client
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

    