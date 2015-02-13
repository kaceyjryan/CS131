from twisted.application import service, internet
from twisted.internet import protocol, reactor
from twisted.protocols import basic
from datetime import datetime
import time
import logging
import re
import urllib
import json

#Place API Key Here!! The below key is only to be used on lnxsrv02.seas.ucla.edu

PlacesKey = "AIzaSyB7AuZdbrf-AMCDXscr7r2orgo_mud5fdE"

# Start Log

logging.basicConfig(filename='serverherd.log', level=logging.DEBUG)

#Dictionary for the entire server herd

serverherd = {}

serverherd['Alford'] = dict(
	ID = 'Alford',
	port = 12500,
	neighbors = ('Parker', 'Powell')
)

serverherd['Bolden'] = dict(
	ID = 'Bolden',
	port = 12501,
	neighbors = ('Parker', 'Powell')
)

serverherd['Hamilton'] = dict(
	ID = 'Hamilton',
	port = 12502,
	neighbors = ('Parker',)
)

serverherd['Parker'] = dict(
	ID = 'Parker',
	port = 12503,
	neighbors = ('Alford', 'Bolden', 'Hamilton')
)

serverherd['Powell'] = dict(
	ID = 'Powell',
	port = 12504,
	neighbors = ('Alford', 'Bolden')
)

#Create the URL and collect the body from the webpage to return on WHATSAT

def createPlacesQuery(numResults, r, message):
	# parse message to get coords and place a comma in between lat and long
	tokens = message.split()
	coords = re.split("([\+\-])", tokens[4])
	coords.insert(3, ',')

	url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location="
	url += ''.join(coords)
	url += "&radius="
	url += str(r)
	url += "&key="
	url += PlacesKey
	url += "&sensor=false"

	# Access url body
	response = urllib.urlopen(url)

	json_raw = response.read()
	json_data = json.loads(json_raw)

	#eliminate extra results

	if len(json_data['results']) > numResults:
		json_data['results'] = json_data['results'][0:numResults]
	
	#Print formatted json message
	return '\n' + json.dumps(json_data, sort_keys=True, indent=3, separators=(',', ' : ')) + '\n'

	# Read URL body into body string (difficult to eliminate results so it was not used)
#	body = ""
#	for line in response:
#		body += line
#	body += "\n"
#	return body;

#Main ServerHerd Class derived from MyChat

class ServerHerd(basic.LineReceiver):
	def connectionMade(self):
		# Log Connection Made
		logging.info(
			"%s added a %s to Clients",
			self.factory.data['ID'],
			self.transport.client,
		)

		#Add Client
		self.factory.clients.append(self)

	def connectionLost(self, reason):
		#Log connection lost
		logging.info(
			"%s lost %s from Clients",
			self.factory.data['ID'],
			self.transport.client,
		)

		#Remove Client
		self.factory.clients.remove(self)

	def lineReceived(self, line):
		#Log received line
		logging.info(
			"%s received the line: %s",
			self.factory.data['ID'],
			line,
		)

		#Handle received line based on command
		tokens = line.split()
		if tokens[0] == 'IAMAT':
			self.handleIAMAT(tokens)
		elif tokens[0] == "AT":
			self.handleAT(tokens)
		elif tokens[0] == "WHATSAT":
			self.handleWHATSAT(tokens)
		#The command was invalid
		else:
			self.message("? " + line)		

	def message(self, message):
		#Log messages
		logging.info(
			"%s sent the message: %s",
			self.factory.data['ID'],
			message,
		)
		#Write Message
		self.transport.write(message + '\n')

	def handleAT(self, tokens):
		#If AT is received we need to store the information on the server
		clientID = tokens[3]
		message = tokens[:6]
		sentTime = datetime.fromtimestamp(float(tokens[6]))
		self.saveMessageInDatabase(clientID, message, sentTime)

	def handleIAMAT(self, tokens):
		#If IAMAT store tokens
		try:
			clientID = tokens[1]
			coords = tokens[2]
			clientTime = datetime.fromtimestamp(float(tokens[3]))
		except:
			self.message("Invalid IAMAT: FORMAT(IAMAT <client ID> <location> <sent time>)")
			return

		#Find time difference for AT response
		serverTime = datetime.now()
		diffTime = (serverTime - clientTime).total_seconds()

		#create AT response
		message = (
			"AT",
			self.factory.data['ID'],
			("%+f" % (diffTime)), ) + tuple(tokens[1:])
		#Join parts of AT response list
		self.message(' '.join(message),)
		self.saveMessageInDatabase(clientID, message, serverTime)

	def handleWHATSAT(self, tokens):
		clientDatabase = self.factory.savedClients
		# Check input parameters and if valid return AT with URL appended
		try:
			clientID = tokens[1]
			assert(clientID in clientDatabase)
			r = int(tokens[2])
			assert(r >= 0 and r <= 50)
			numResults = int(tokens[3])
			assert(numResults > 0 and numResults <= 20)
			self.message(' '.join(self.factory.savedClients[clientID]['message']) + createPlacesQuery(numResults, r, ' '.join(self.factory.savedClients[clientID]['message'])))
		except:
			self.message("Invalid WHATSAT: FORMAT(WHATSAT <client ID> <radius> <numberOfResults>)")
	
	def floodServers(self, message, time):
		#forwards all client IAMAT commands to neighbors
		clientFactory = ClientFactory(' '.join(message), time)
		clientFactory.protocol = Client
		for neighbor in self.factory.data['neighbors']:
			#Log the flooding of neighbors
			logging.info(
				"%s forwarding AT to neighbor %s",
				self.factory.data['ID'],
				neighbor,
			)
			reactor.connectTCP('localhost', serverherd[neighbor]['port'], clientFactory)

	def saveMessageInDatabase(self, clientID, message, time):
		clientDatabase = self.factory.savedClients
		# Make sure there isnt a later message
		if clientID in clientDatabase and clientDatabase[clientID]['clientTime'] >= time:
			return
		clientDatabase[clientID] = dict(
			message=message, 
			clientTime=time
		)
		self.floodServers(message, time)

#Client Class

class Client(basic.LineReceiver):
	def connectionMade(self):
		clientTime = self.factory.time
		tupleTime = time.mktime(clientTime.timetuple())
		self.sendLine(
			self.factory.message + ' ' +
			str( tupleTime + clientTime.microsecond * 0.000001)
		)
		self.transport.loseConnection()

#Client Factory

class ClientFactory(protocol.ClientFactory):
	def __init__(self, message, time):
		self.message = message
		self.time = time

#ServerHerd Factory

class ServerHerdFactory(protocol.ServerFactory):
	protocol = ServerHerd
	def __init__(self, data):
		#dont think I need this clients set but I took it from the chatserver.py
		self.clients = []
		#database clients
		self.savedClients = {}
		self.data = data

#define Application like chatserver.py

application = service.Application("serverherd")

#Dictionary od all of the servers

servers = {}

servers['Alford'] = internet.TCPServer(serverherd['Alford']['port'], ServerHerdFactory(serverherd['Alford'])).setServiceParent(application)
servers['Bolden'] = internet.TCPServer(serverherd['Bolden']['port'], ServerHerdFactory(serverherd['Bolden'])).setServiceParent(application)
servers['Hamilton'] = internet.TCPServer(serverherd['Hamilton']['port'], ServerHerdFactory(serverherd['Hamilton'])).setServiceParent(application)
servers['Parker'] = internet.TCPServer(serverherd['Parker']['port'], ServerHerdFactory(serverherd['Parker'])).setServiceParent(application)
servers['Powell'] = internet.TCPServer(serverherd['Powell']['port'], ServerHerdFactory(serverherd['Powell'])).setServiceParent(application)
