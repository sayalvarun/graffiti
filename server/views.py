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
            return str(convert(343251)) + str(b) 
    else:
        print("ERROR: file not found")

    return None
    #return flask.send_file('file.jpg')

@server.route('/tag', methods = ['POST'])
def logTag():
    latitude = flask.request.args.get("lat")
    longitude = flask.request.args.get("long")
    
    data = flask.request.get_data()
    print("Received %s bytes" % len(data))
    data = data.replace(" ", "")
    data = data.replace("<", "")
    data = data.replace(">", "")
    filename = "payload" + str(datetime.datetime.now()) + ".txt"
    with open(filename, "wb") as file:
        file.write(data)
    
    print("(%s,%s)" % (latitude, longitude))
    
    try:
        b_data = binascii.unhexlify(data)
        stream = StringIO.StringIO(b_data)
        img = Image.open(stream)
        img.save("a_test.png")
        '''
        img = binascii.a2b_hex(data.strip())
        with open('image.png', 'wb') as image_file:
            image_file.write(img)
        '''
    except Exception, e:
        print("ERROR: " + str(e))
        return "1" #error
    
    print("DATA:" + data)    
    return "0" #ok

def convert(num):
    return re.sub(r'([0-9A-F]{2})',r'\\x\1','%08X' % num)
