---
# Waste Food Management and Donation System

## Introduction
This application aims to reduce food waste by enabling restaurants and hotels to donate excess food to NGOs, which then distribute it to those in need.

## Features
- **Donor Management**: Restaurants and hotels can add details about available food, including type, quantity, location, cooking date, expiry date, and real images.
- **NGO Management**: NGOs can submit food requests specifying the type and quantity of food needed. These requests are approved by the donor.
- **Delivery Management**: NGOs can assign employees to transport approved food from donors to the NGO centers.
- **User Notifications**: Push notifications keep users informed about important updates and events related to their donations.
- **Admin Management**: System administrators manage user accounts, approve/reject applications for registration, view donation statistics, and generate reports.

## Technologies Used
- **Flutter**: 3.10.6
- **Uvicorn**: 0.23.1
- **Firebase Messaging Plugin for Flutter**: 14.6.5
- **FastAPI**: 0.100.0
- **MySQL**: For data storage and management

## System Requirements
- **Mobile**: Android 7 or newer
- **Web**: Chromium Browser (Chrome, Edge, etc.)

## Installation

### Prerequisites
- **Flutter**: Install Flutter SDK from [Flutter Official Site](https://flutter.dev/docs/get-started/install).
- **Python**: Install Python 3.8+ from [Python Official Site](https://www.python.org/downloads/).
- **MySQL**: Install MySQL server from [MySQL Official Site](https://dev.mysql.com/downloads/mysql/).

### Steps

1. **Clone the Repository**
   ```
   git clone https://github.com/yourusername/waste-food-management.git
   cd waste-food-management
   ```

2. **Backend Setup**
   - **Create and Activate Virtual Environment**
     ```
     python -m venv env
     source env/bin/activate  # On Windows use `env\Scripts\activate`
     ```
   - **Install Dependencies**
     ```
     pip install -r requirements.txt
     ```
   - **Run the Server**
     ```
     uvicorn main:app --reload
     ```

3. **Frontend Setup**
   - **Navigate to Flutter Directory**
     ```
     cd flutter_app
     ```
   - **Install Dependencies**
     ```
     flutter pub get
     ```
   - **Run the App**
     ```
     flutter run
     ```

4. **Database Setup**
   - **Create a MySQL Database**
     ```
     CREATE DATABASE food_donation;
     ```
   - **Run Migrations**
     Configure the database settings in the `settings.py` file and run the necessary migrations.

## Usage

### Donors
1. **Register/Login**: Donors can register and log in to the application.
2. **Add Food Details**: Enter details about the available food, including type, quantity, location, cooking date, expiry date, and upload real images.
3. **Approve Requests**: Review and approve food requests submitted by NGOs.

### NGOs
1. **Register/Login**: NGOs can register and log in to the application.
2. **Submit Food Requests**: Specify the type and quantity of food needed.
3. **Assign Deliverers**: Assign employees to transport the approved food from donors to NGO centers.

### Deliverers
1. **View Assignments**: Check the assignments for transporting food.
2. **Update Delivery Status**: Update the status of the delivery in the app.

### Admin
1. **Manage Users**: Approve or reject applications for registration.
2. **View Statistics**: Monitor donation statistics and generate usage reports.

## Security and Data Protection
- **Data Encryption**: All sensitive data is encrypted to ensure user privacy and security.
- **Authentication**: Secure authentication mechanisms to prevent unauthorized access.

## License
This project is licensed under the MIT License. See the `LICENSE` file for more details.

---
