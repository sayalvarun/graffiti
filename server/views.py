import flask
from server import server

@server.route('/')
@server.route('/index')
def index():
    return "Hello, World!"

@server.route('/doodle')
def sendImage():
    return flask.send_file('file.jpg')

@server.route('/tag')
def logTag():
    return "Hello, World!"
