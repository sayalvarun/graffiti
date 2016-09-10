import flask
import io
import os
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
    else:
        print("ERROR: file not found")

    return b
    #return flask.send_file('file.jpg')

@server.route('/tag')
def logTag():
    return "Hello, World!"
