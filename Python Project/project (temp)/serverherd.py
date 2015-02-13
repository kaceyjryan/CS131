"""Simple server herd.
run me with twistd -n -y server.py, and then connect with multiple
telnet clients to port 12150
"""
from twisted.internet import protocol, reactor
from twisted.application import service, internet
from twisted.protocols import basic
import server

from datetime import datetime
import time
import logging
import json

logging.basicConfig(filename='herd.log', level=logging.DEBUG)

farmar = 'Farmar'
gasol = 'Gasol'
hill = 'Hill'
meeks = 'Meeks'
young = 'Young'

servers = {}
herd = {}
herd[farmar] = dict(
	name=farmar,
	neighbors=(meeks, young),
)
herd[gasol] = dict(
	name=gasol,
	neighbors=(meeks, young),
)
herd[hill] = dict(
	name=hill,
	neighbors=(meeks,),
)
herd[meeks] = dict(
	name=meeks,
	neighbors=(farmar, gasol, hill),
)
herd[young] = dict(
	name=young,
	neighbors=(farmar, gasol),
)

ports = {}
ports[farmar] = 12150
ports[gasol] = 12151
ports[hill] = 12152
ports[meeks] = 12153
ports[young] = 12154

def constructJSON(rpp, msg):
	resp = {}
	# parse msg to get geocode
	toks = msg.split()
	geocode = toks[4]
	resp['results'] = []
	for i in range(0,rpp):
		# append bogus tweet
		tweet = {}
		tweet["location"] = "Ever"
		tweet["profile_image_url"] = "http://a3.twimg.com/profile_images/524342107/avatar_normal.jpg"
		tweet["created_at"] = "Fri, 16 Nov 2012 07:37:16 +0000"
		tweet["from_user"] = "C_86"
		tweet["to_user_id"] = None
		tweet["text"] = "RT @ionmobile: @SteelCityHacker everywhere but nigeria // LMAO!"
		tweet["id"] = 5704386230
		tweet["from_user_id"] = 34011528
		tweet["geo"] = None
		tweet["iso_language_code"] = "en"
		tweet["source"] = "&lt;a href=&quot;http://socialscope.net&quot; rel=&quot;nofollow&quot;&gt;SocialScope&lt;/a&gt;"
		resp['results'].append(tweet)
	resp['max_id'] = 5704386230
	resp['since_id'] = 5501341295
	resp['refresh_url'] = "?since_id=5704386230&q="
	resp['next_page'] = "?page=2&max_id=5704386230&rpp=%d&geocode=%s&q=" % (rpp, geocode)
	resp['results_per_page'] = rpp
	resp['page'] = 1
	resp['completed_in'] = 0.090181
	resp['warning'] = "adjusted since_id to 5501341295 (2012-11-07 07:00:00 UTC), requested since_id was older than allowed -- since_id removed for pagination."
	resp['query'] = ''

	return json.dumps(resp)

class HerdServer(basic.LineReceiver):
	def connectionMade(self):
		logging.info(
			"%s: Got new client: %s",
			self.factory.info['name'],
			self.transport.client,
		)
		self.factory.clients.append(self)

	def connectionLost(self, reason):
		logging.info(
			"%s: Lost a client: %s",
			self.factory.info['name'],
			self.transport.client,
		)
		self.factory.clients.remove(self)

	def lineReceived(self, line):
		logging.info(
			"%s: Received '%s'",
			self.factory.info['name'],
			line,
		)
		self.processLine(line)

	def message(self, message):
		logging.info(
			"%s: Sent '%s'",
			self.factory.info['name'],
			message,
		)
		self.transport.write(message + '\n')

	def processLine(self, line):
		toks = line.split()
		if toks[0] == 'IAMAT':
			self.doIAMAT(toks)
		elif toks[0] == "AT":
			self.doAT(toks)
		elif toks[0] == "WHATSAT":
			self.doWHATSAT(toks)
		else: # unrecognized
			self.message("? " + line)

	def doAT(self, toks):
		client_id = toks[3]
		msg = toks[:6]
		time = datetime.fromtimestamp(float(toks[6]))
		self.storeMessage(client_id, msg, time)

	def doIAMAT(self, toks):
		try:
			client_id = toks[1]
			latlong = toks[2]
			message_time = datetime.fromtimestamp(float(toks[3]))
		except:
			self.message("Malformed IAMAT command.")
			return

		server_time = datetime.now()
		timedelta = (server_time - message_time).total_seconds()

		msg = (
			"AT",
			self.factory.info['name'],
			("%+f" % (timedelta)), ) + tuple(toks[1:])
		self.message(' '.join(msg),)
		self.storeMessage(client_id, msg, server_time)

	def doWHATSAT(self, toks):
		db = self.factory.users
		try:
			client_id = toks[1]
			assert(client_id in db)
			radius = int(toks[2])
			assert(radius >= 0 and radius <= 100)
			rpp = int(toks[3])
			assert(rpp > 0)
			self.message(self.getData(client_id))
			self.message(constructJSON(rpp,self.getData(client_id)))
		except:
			self.message("Malformed WHATSAT command. Valid client name, radius, and rpp must be provided.")

	def storeMessage(self, client_id, msg, time):
		db = self.factory.users
		# check if there's a more recent msg in the db
		if client_id in db and db[client_id]['time'] >= time:
			return
		db[client_id] = dict(msg=msg, time=time)
		self.flood(msg, time)

	def getData(self, key):
		try:
			return ' '.join(self.factory.users[key]['msg'])
		except:
			return "INVALID DATA"

	def flood(self, msg, time):
		client_factory = HerdClientFactory(' '.join(msg), time)
		client_factory.protocol = HerdClient
		for neighbor in self.factory.info['neighbors']:
			logging.info(
				"%s: sending AT to %s",
				self.factory.info['name'],
				neighbor,
			)
			reactor.connectTCP('localhost', ports[neighbor], client_factory)


class HerdClient(basic.LineReceiver):
	def connectionMade(self):
		t = self.factory.time
		self.sendLine(
			self.factory.message +
			' ' +
			str(time.mktime(t.timetuple()) + t.microsecond * 0.000001)
		)
		self.transport.loseConnection()

class HerdClientFactory(protocol.ClientFactory):
	def __init__(self, message, time):
		self.message = message
		self.time = time

class HerdServerFactory(protocol.ServerFactory):
	protocol = HerdServer
	def __init__(self, info):
		self.clients = []
		self.info = info
		self.users = {}

factory = protocol.ServerFactory()
factory.protocol = HerdServer
factory.clients = []

application = service.Application("herd-server")

servers[farmar] = internet.TCPServer(ports[farmar], HerdServerFactory(herd[farmar]))
servers[farmar].setServiceParent(application)

servers[gasol] = internet.TCPServer(ports[gasol], HerdServerFactory(herd[gasol]))
servers[gasol].setServiceParent(application)

servers[hill] = internet.TCPServer(ports[hill], HerdServerFactory(herd[hill]))
servers[hill].setServiceParent(application)

servers[meeks] = internet.TCPServer(ports[meeks], HerdServerFactory(herd[meeks]))
servers[meeks].setServiceParent(application)

servers[young] = internet.TCPServer(ports[young], HerdServerFactory(herd[young]))
servers[young].setServiceParent(application)
