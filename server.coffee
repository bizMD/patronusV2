# Require the dependencies
require 'sugar'
util = require 'util'
loki = require 'lokijs'
domain = require 'domain'
restify = require 'restify'
{resolve} = require 'path'
{spawn} = require 'child_process'

# Require the routes directory
requireDir = require 'require-dir'
require('coffee-script/register')
routes = requireDir 'routes', recurse: true

dbFile = resolve process.cwd(), 'db', 'loki.json'
db = new loki dbFile,
	autosave: true
	autosaveInterval: 1000

wsdlFiles = db.getCollection 'wsdlFiles'
wsdlFiles = db.addCollection 'wsdlFiles' if Object.equal wsdlFiles, null
# db.saveDatabase()

db.loadDatabase {}, ->
	# Ensure that the database is always up to date
	(-> db.loadDatabase()).every 5000
	(-> db.saveDatabase()).every 1000

	# Create the web server and use middleware
	server = restify.createServer name: 'PatronusV2'
	server.use restify.bodyParser()
	server.pre restify.pre.sanitizePath()
	server.use restify.CORS()
	server.use restify.fullResponse()
	
	# Define REST API
	server.get '/resource/1/wslist', (args...) -> routes.wslist.v1.get.all args, db
	server.get '/resource/1/wslist/:ws', (args...) -> routes.wslist.v1.get.one_ws args, db
	server.get '/resource/1/wslist/:ws/:act', (args...) -> routes.wslist.v1.get.one_ws_action args, db

	server.post '/resource/1/wslist/:ws', (args...) -> routes.wslist.v1.post.one_ws args, db
	server.post '/resource/1/wslist/:ws/:act', (args...) -> routes.wslist.v1.post.one_ws_action args, db

	server.put '/resource/1/wslist/:ws', (args...) -> routes.wslist.v1.put.one_ws args, db
	server.put '/resource/1/wslist/:ws/:act', (args...) -> routes.wslist.v1.put.one_ws_action args, db

	server.del '/resource/1/wslist', (args...) -> routes.wslist.v1.del.all args, db
	server.del '/resource/1/wslist/:ws', (args...) -> routes.wslist.v1.del.one_ws args, db
	server.del '/resource/1/wslist/:ws/:act', (args...) -> routes.wslist.v1.del.one_ws_action args, db
	
	# For the timer to trigger a polling
	coffeeBin = 'node_modules/coffee-script/bin/coffee'
	coffeeTimer = resolve process.cwd(), 'helper', 'timer.coffee'
	pollInterval = 5000 # 5 seconds for dev mode
	timer = spawn process.execPath, [coffeeBin, coffeeTimer, pollInterval], cwd: process.cwd()
	timer.on 'error', (error) -> util.log error
	timer.stdout.on 'data', (data) -> util.log data
	timer.stderr.on 'data', (data) -> util.log data
	timer.on 'exit', -> util.log "Timer [#{timer.pid}] has shut down"

	# Listening on each operation
	server.on 'after', (a,b) -> console.log "== After call =="

	# Log when the web server starts up
	server.listen 80, -> console.log "#{server.name}[#{process.pid}] online: #{server.url}"
	console.log "#{server.name} is starting..."