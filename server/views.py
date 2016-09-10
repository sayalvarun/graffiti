import flask
import io
import os
import binascii
import datetime
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
            return str(dump(343251)).replace('\'', '') + str(b) #jank af
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
    #print(data)
    try:
        img = binascii.a2b_hex(data.strip())
        with open('image.png', 'wb') as image_file:
            image_file.write(img)
    except Exception, e:
        print("ERROR: " + str(e))
        return "1" #error

    return "0" #ok

def dump(n): 
    s = '%x' % n
    if len(s) & 1:
        s = '0' + s

    decoded = s.decode('hex')
    while len(decoded) != 4:
        decoded = ('\x00' + decoded)

    return repr(decoded)
