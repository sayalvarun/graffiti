import sqlite3
import defines
import os

#todo add more columns (direction, orientation, gyro info) in metadata
tables = ["Create table if not exists metadata(id INTEGER PRIMARY KEY, latitude REAL NOT NULL, longitude REAL NOT NULL);", "Create table if not exists doodles(id INTEGER PRIMARY KEY, creation_date DATETIME NOT NULL, metadata_id INTEGER NOT NULL, votes INTEGER NOT NULL, path TEXT NOT NULL, FOREIGN KEY(metadata_id) REFERENCES metadata(id));"]

def getConn():
    return sqlite3.connect(defines.DB_NAME)

def initDB():
    conn = getConn()
    cursor = conn.cursor()

    cursor = conn.cursor()
    for table in tables:
        cursor.execute(table)

    conn.commit()
    conn.close()

    if not os.path.exists(defines.IMAGES_DIR):
        os.makedirs(defines.IMAGES_DIR)


def logTag(latitude, longitude, filepath):
    conn = getConn()
    cursor = conn.cursor()

    sql = "Insert into metadata(latitude, longitude) values (%s,%s);" % (latitude, longitude)
    cursor = conn.cursor()
    cursor.execute(sql)
    conn.commit()

    metaID = int(cursor.lastrowid)
    sql = "Insert into doodles(creation_date, metadata_id, votes, path) values (datetime('now', 'localtime'), %s, 0, '%s');" % (metaID, filepath)
    cursor = conn.cursor()
    cursor.execute(sql)
    conn.commit()

    conn.close()

def getDoodles(latitude, longitude, metadata):
    conn = getConn()
    cursor = conn.cursor()

    sql = "Select id from metadata where abs(latitude-%s) < %s and abs(longitude-%s) < %s;" % (defines.PRECISION % latitude, defines.FUDGE, defines.PRECISION % longitude, defines.FUDGE)
    print(sql)
    cursor.execute(sql)
    res = cursor.fetchall()
    #print("RES: " + str(res))
    arr = []
    for row in res:
        arr.append(row[0]) #append IDs

    paths = []
    for ID in arr:
        sql = "Select path from doodles where id=%s" % ID
        cursor.execute(sql)
        res = cursor.fetchone()[0]
        paths.append((ID,res))

    return paths

def upvote(doodleID):
    conn = getConn()
    cursor = conn.cursor()

    sql = "Update doodles set votes = votes + 1 where id=%s" % doodleID
    cursor.execute(sql)
    conn.commit()
    conn.close()

#TODO get votes, add vote

def testData():
    logTag(39.9516, -75.1909, "tags/1.png")
    logTag(39.9516, -75.1909, "tags/2.png")
    logTag(39.9515, -75.1910, "tags/3.png")
    logTag(39.9515, -75.1910, "tags/4.png")
    logTag(39.9517, -75.1911, "tags/5.png")

initDB()
#testData()
#print(getDoodles(39.9515315495,-75.1909825159, None))



