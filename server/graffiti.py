import base64
import io
import os
import json
import re
import db
import uuid
import binascii
import flask
import datetime
import defines
import sqlite3
import cStringIO as StringIO
from PIL import Image

def logTag(latitude, longitude, data):
    try:
        filepath = defines.IMAGES_DIR + str(uuid.uuid4()) + ".png"
        stream = StringIO.StringIO(data)
        with open("out.txt", "w") as f:
            f.write(data)
        img = Image.open(stream)
        img.save(filepath)

        db.logTag(latitude, longitude, filepath)
    except Exception, e:
        print("Error in logTag(): " + str(e))
        return "1" #error
    
    return "0" #ok

def getDoodles(latitude, longitude, metadata):
    paths = db.getDoodles(latitude, longitude, metadata)
    print("db.getDoodles() returned %s" % paths)
    return formatDoodleJSON(paths)

def formatDoodleJSON(paths):
    json = {'id':len(paths)}
    entries = []
    for tup in paths:
        temp = dict()
        temp['id'] = tup[0]
        temp['payload'] = setPayload("server/" + str(tup[1])) #todo fix?
        entries.append(temp)

    json['entries'] = entries

    return flask.jsonify(json)

def setPayload(filepath):
    if not os.path.isfile(filepath):
        print("Error in setPayload(): file [%s] not found" % filepath)
        return 0

    b = None
    with open(filepath, "rb") as imageFile:
        f = imageFile.read()
        b = bytearray(f)
        #print(binascii.hexlify(b))

    return base64.b64encode(b)

def upvoteDoodle(doodleID):
    try:
        db.upvote(doodleID)
    except Exception, e:
        print("Error in upvoteDoodle(): %s" % str(e))
        return "1: " + str(e)

    return "0"


#return flask.jsonify({'id':str(num), 'payloadLength':len(b),'payload':encoded})
        
def convert(num):
    return re.sub(r'([0-9A-F]{2})',r'\\x\1','%08X' % num)
