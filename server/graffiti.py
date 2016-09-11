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
import logging
import cStringIO as StringIO
from PIL import Image

logger = logging.getLogger('')

def logTag(latitude, longitude, direction, orientation, data):
    try:
        filepath = defines.IMAGES_DIR + str(uuid.uuid4()) + ".png"
        stream = StringIO.StringIO(data)
        with open("out.txt", "w") as f:
            f.write(data)
        img = Image.open(stream)
        img.save(filepath)

        db.logTag(latitude, longitude, direction, convertOrientation(orientation), filepath)
    except Exception, e:
        print("Error in logTag(): " + str(e))
        return "1" #error
    
    return "0" #ok

def getDoodles(latitude, longitude, direction, orientation):
    paths = db.getDoodles(latitude, longitude, direction, convertOrientation(orientation))
    logging.warning("paths: %s" % str(paths))
    #print("db.getDoodles() returned %s" % paths)
    return formatDoodleJSON(paths)

def formatDoodleJSON(paths):
    json = {'id':len(paths)}
    entries = []
    for tup in paths:
        temp = dict()
        temp['id'] = tup[0]
        temp['payload'] = setPayload(str(tup[1]))
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

def downvoteDoodle(doodleID):
    try:
        db.downvote(doodleID)
    except Exception, e:
        print("Error in downvoteDoodle(): %s" % str(e))
        return "1: " + str(e)

    return "0"

def convertOrientation(orientation):
    if orientation > -2.0 and orientation < 0.2:
        return -1.0 #floor

    if orientation >= 0.2 and orientation < 0.6:
        return 1.0 #ceiling

    return 0.0 #wall

#return flask.jsonify({'id':str(num), 'payloadLength':len(b),'payload':encoded})
        
def convert(num):
    return re.sub(r'([0-9A-F]{2})',r'\\x\1','%08X' % num)
