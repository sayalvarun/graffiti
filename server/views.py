import flask
import graffiti
import logging
from server import server

logging.basicConfig(filename='log.txt',level=logging.DEBUG)
logger = logging.getLogger('')
ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(asctime)s - %(message)s')
ch.setFormatter(formatter)
logger.addHandler(ch)

# add formatter to ch
ch.setFormatter(formatter)

# add ch to logger
logger.addHandler(ch)

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
    logging.debug("Fetching Doodles for (%s,%s), direction: %s" % (latitude, longitude, direction))

    json = graffiti.getDoodles(latitude, longitude, direction) #no metadata for now
    return json

#Uploads a tag to the server
@server.route('/tag', methods = ['POST'])
def tag():
    latitude = float(flask.request.args.get("lat"))
    longitude = float(flask.request.args.get("long"))
    direction = float(flask.request.args.get("direction"))
    data = flask.request.get_data()
    logging.debug("Tag request from (%s,%s), direction: %s, payload: %s bytes" % (latitude, longitude, direction, len(data)))
    return graffiti.logTag(latitude, longitude, direction, data)
    #print(data)

#Upvotes a doodle
@server.route('/upvote')
def upvote():
    doodleID = int(flask.request.args.get("id"))
    logging.debug("Upvote request for id %s" % doodleID)
    
    return graffiti.upvoteDoodle(doodleID)

#Upvotes a doodle
@server.route('/downvote')
def downvote():
    doodleID = int(flask.request.args.get("id"))
    logging.debug("Downvote request for id %s" % doodleID)
    
    return graffiti.downvoteDoodle(doodleID)
