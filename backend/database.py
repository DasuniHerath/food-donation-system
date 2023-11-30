from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Url for mysql database in wamp server
SQLALCHEMY_DATABASE_URL = "mysql+pymysql://root@localhost:3306/foodapp"

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)