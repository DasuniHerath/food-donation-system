import requests
import requests

class Organization:
    def __init__(self, token):
            self.token = token
            self.addOrganization()

    def addOrganization(self):
        url = "http://178.128.106.190/add_organization"
        headers = {
            "Authorization": f"Bearer {self.token}"
        }

        response = requests.post(url, headers=headers)

        print(response.status_code)
        print(response.json())

    def addRequest(self, category, amount, comAddress):
        url = "http://178.128.106.190/add_request"
        headers = {
            "Authorization": f"Bearer {self.token}"
        }
        data = {
            "category": category,
            "amount": amount,
            "comAddress": comAddress
        }

        response = requests.post(url, headers=headers, data=data)

        print(response.status_code)
        print(response.json())        

class Donor:
    def __init__(self, token):
            self.token = token
            self.addDonor()

    def addDonor(self):
        url = "http://178.128.106.190/add_donor"
        headers = {
            "Authorization": f"Bearer {self.token}"
        }

        response = requests.post(url, headers=headers)

        print(response.status_code)
        print(response.json())

class Member:
    def __init__(self, token):
            self.token = token
            self.addMember()

    def addMember(self):
        url = "http://178.128.106.190/load_member"
        headers = {
            "Authorization": f"Bearer {self.token}"
        }

        response = requests.post(url, headers=headers)

        print(response.status_code)
        print(response.json())
    
        

    def change_status(self, status: bool):
        url = f"http://178.128.106.190/change_status/?status={status}"
        headers = {
            "Authorization": f"Bearer {self.token}"
        }

        response = requests.put(url, headers=headers)
        print(response.status_code)
        print(response.json())