import sqlite3

DB_NAME = "graffiti.db"

#todo add more columns (direction, orientation, gyro info) in metadata
tables = ["Create table if not exists metadata(id INTEGER PRIMARY KEY, latitude REAL NOT NULL, longitude REAL NOT NULL);", "Create table if not exists doodles(id INTEGER PRIMARY KEY, creation_date DATETIME NOT NULL, metadata_id INTEGER NOT NULL, votes INTEGER NOT NULL, FOREIGN KEY(metadata_id) REFERENCES metadata(id));"]

def initDB():
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    for table in tables:
        cursor.execute(table)

    conn.commit()
    conn.close()

initDB()