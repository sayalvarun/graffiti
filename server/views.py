import flask
import io
import os
import re
import binascii
import datetime
import cStringIO as StringIO
from PIL import Image
from server import server

@server.route('/')
@server.route('/index')
def index():
    return "Hello, World!"

@server.route('/doodle')
def sendImage():
    if os.path.isfile("server/file.jpg"):
        print("file present")
        with open("server/file.jpg", "rb") as imageFile:
            f = imageFile.read()
            b = bytearray(f)
            num = str(convert(343251))
            print("343251 is " + num)
            return (num + str(b))
    else:
        print("ERROR: file not found")

    return None
    #return flask.send_file('file.jpg')

@server.route('/tag', methods = ['POST'])
def logTag():
    latitude = flask.request.args.get("lat")
    longitude = flask.request.args.get("long")
    data = flask.request.get_data()
    #print(data)
    #print("Received %s bytes" % len(data))
    #print("(%s,%s)" % (latitude, longitude))
    try:
        #b_data = binascii.unhexlify(data)
        stream = StringIO.StringIO(data)
        img = Image.open(stream)
        img.save("image.png")
    except Exception, e:
        print("ERROR: " + str(e))
        return "1" #error
    
    return "0" #ok

def convert(num):
    return re.sub(r'([0-9A-F]{2})',r'\\x\1','%08X' % num)
