import flask
import graffiti
from server import server

@server.route('/')
@server.route('/index')
def index():
    return "Hello, World!"

#Gets doodles in an area
@server.route('/doodle')
def doodle():
    latitude = float(flask.request.args.get("lat"))
    longitude = float(flask.request.args.get("long"))
    direction = float(flask.request.args.get("direction"))
    #orientation = float(flask.request.args.get("orientation"))
    print("Fetching Doodles for (%s,%s)" % (latitude, longitude))

    json = graffiti.getDoodles(latitude, longitude, direction) #no metadata for now
    return json

#Uploads a tag to the server
@server.route('/tag', methods = ['POST'])
def tag():
    latitude = float(flask.request.args.get("lat"))
    longitude = float(flask.request.args.get("long"))
    direction = float(flask.request.args.get("direction"))
    data = flask.request.get_data()
    print("Tag request from (%s,%s), payload: %s bytes" % (latitude, longitude, len(data)))
    return graffiti.logTag(latitude, longitude, direction, data)
    #print(data)

#Upvotes a doodle
@server.route('/upvote')
def upvote():
    doodleID = int(flask.request.args.get("id"))
    print("Upvote request for id %s" % doodleID)
    
    return graffiti.upvoteDoodle(doodleID)

#Upvotes a doodle
@server.route('/downvote')
def downvote():
    doodleID = int(flask.request.args.get("id"))
    print("Downvote request for id %s" % doodleID)
    
    return graffiti.downvoteDoodle(doodleID)
