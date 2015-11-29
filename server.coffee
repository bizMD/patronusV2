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

# Require the adapter
adapter = require resolve process.cwd(), 'helper', 'adapter'

# Activate the domain
d = domain.create()

dbFile = resolve process.cwd(), 'db', 'loki.json'
db = new loki dbFile,
	autosave: true
	autosaveInterval: 1000

wsdlFiles = db.getCollection 'wsdlFiles'
wsdlFiles = db.addCollection 'wsdlFiles' if Object.equal wsdlFiles, null
datasets = db.getCollection 'datasets'
datasets = db.addCollection 'datasets' if Object.equal datasets, null
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
	
	# Define REST API: wslist
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
	
	# Define REST API: wsdataset
	server.get '/resource/1/wsdataset', (args...) -> routes.wsdataset.v1.get.all args, db
	server.get '/resource/1/wsdataset/:name', (args...) -> routes.wsdataset.v1.get.one_set args, db

	server.post '/resource/1/wsdataset/:name', (args...) -> routes.wsdataset.v1.post.one_set args, db

	server.put '/resource/1/wsdataset/:name', (args...) -> routes.wsdataset.v1.put.one_set args, db

	server.del '/resource/1/wsdataset', (args...) -> routes.wsdataset.v1.del.all args, db
	server.del '/resource/1/wsdataset/:name', (args...) -> routes.wsdataset.v1.del.one_set args, db

	# For the timer to trigger a polling
	# Disadvantage is this approach does not let us have two instances running
	# Or else the same queries will be redundantly made to Remedy
	coffeeBin = 'node_modules/coffee-script/bin/coffee'
	coffeeTimer = resolve process.cwd(), 'helper', 'timer.coffee'
	pollInterval = 5000 # 5 seconds for dev mode
	
	timer = spawn process.execPath, [coffeeBin, coffeeTimer, pollInterval], cwd: process.cwd()
	timer.on 'error', (error) -> util.log error
	timer.stdout.on 'data', -> adapter pollInterval, db
	timer.stderr.on 'data', (data) -> util.log data
	timer.on 'exit', -> util.log "Timer [#{timer.pid}] has shut down"

	# Listening on each operation
	server.on 'after', (req, res, route, error) ->
		console.log "======= After call ======="
		console.log "Error: #{error}"
		console.log "=========================="

	# Log when the web server starts up
	server.listen 80, -> console.log "#{server.name}[#{process.pid}] online: #{server.url}"
	console.log "#{server.name} is starting..."