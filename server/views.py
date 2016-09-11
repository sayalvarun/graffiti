import flask
import graffiti
from server import server

@server.route('/')
@server.route('/index')
def index():
    return "Hello, World!"

@server.route('/doodle')
def doodle():
    latitude = float(flask.request.args.get("lat"))
    longitude = float(flask.request.args.get("long"))
    print("Fetching Doodles for (%s,%s)" % (latitude, longitude))

    json = graffiti.getDoodles(latitude, longitude, None) #no metadata for now
    return json

@server.route('/tag', methods = ['POST'])
def tag():
    latitude = float(flask.request.args.get("lat"))
    longitude = float(lask.request.args.get("long"))
    data = flask.request.get_data()
    print("Tag request from (%s,%s), payload: %s bytes" % (latitude, longitude, len(data)))
    #print(data)
    
    return graffiti.logTag(latitude, longitude, data)
