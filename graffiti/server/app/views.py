import flask
from app import app

@app.route('/')
@app.route('/index')
def index():
    return "Hello, World!"

@app.route('/image')
def sendImage():
    return flask.send_file('file.jpg')