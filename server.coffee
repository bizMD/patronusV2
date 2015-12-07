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
adapter = require resolve process.cwd(), 'adapters', 'remedyWS'

# Activate the domain
d = domain.create()
d.on 'error', (error) -> console.log error

# Database
DB = require resolve process.cwd(), 'DB', 'DB.coffee'
db = new DB

# Create the web server and use middleware
server = restify.createServer name: 'PatronusV2'
server.use restify.bodyParser()
server.pre restify.pre.sanitizePath()
server.use restify.CORS()
server.use restify.fullResponse()

# Define REST API: wsdlCache
# TODO: Document the API here
server.get '/resource/1/wsdlCache', (args...) -> routes.wsdlCache.v1.get.get_all_WSDL_files args, db
server.get '/resource/1/wsdlCache/:ws', (args...) -> routes.wsdlCache.v1.get.get_one_WSDL_file args, db
server.get '/resource/1/wsdlCache/:ws/:act', (args...) -> routes.wsdlCache.v1.get.get_one_WSDL_method args, db
server.post '/resource/1/wsdlCache/:ws', (args...) -> routes.wsdlCache.v1.post.upload_WSDL_file args, db
server.post '/resource/1/wsdlCache/:ws/:act', (args...) -> routes.wsdlCache.v1.post.insert_WSDL_dataset args, db
server.put '/resource/1/wsdlCache/:ws', (args...) -> routes.wsdlCache.v1.put.put_one_ws args, db
server.put '/resource/1/wsdlCache/:ws/:act', (args...) -> routes.wsdlCache.v1.put.put_one_ws_action args, db
server.del '/resource/1/wsdlCache', (args...) -> routes.wsdlCache.v1.del.delete_all args, db
server.del '/resource/1/wsdlCache/:ws', (args...) -> routes.wsdlCache.v1.del.delete_one_ws args, db
server.del '/resource/1/wsdlCache/:ws/:act', (args...) -> routes.wsdlCache.v1.del.delete_one_ws_action args, db

# Define REST API: dataView
# TODO: Document the API here
server.get '/resource/1/dataView', (args...) -> routes.dataView.v1.get.get_all_views args, db
server.get '/resource/1/dataView/:name', (args...) -> routes.dataView.v1.get.get_one_view args, db
server.post '/resource/1/dataView/:name', (args...) -> routes.dataView.v1.post.post_one_view args, db
server.put '/resource/1/dataView/:name', (args...) -> routes.dataView.v1.put.put_one_dataset args, db
server.del '/resource/1/dataView', (args...) -> routes.dataView.v1.del.delete_all args, db
server.del '/resource/1/dataView/:name', (args...) -> routes.dataView.v1.del.delete_one_dataset args, db

# This section triggers the polling process.
# The disadvantage of this approach is we can't let two instances run
# or else the same queries will be redundantly made to Remedy
coffeeBin = resolve 'node_modules', 'coffee-script', 'bin', 'coffee'
coffeeTimer = resolve process.cwd(), 'helper', 'timer.coffee'
pollInterval = 5000 # 5 seconds for dev mode

timer = spawn process.execPath, [coffeeBin, coffeeTimer, pollInterval], cwd: process.cwd()
timer.on 'error', (error) -> util.log error
timer.stdout.on 'data', -> adapter pollInterval, db
timer.stderr.on 'data', (data) -> util.log data
timer.on 'exit', -> util.log "Timer [#{timer.pid}] has shut down"

# After each operation, log if there was an error
server.on 'after', (req, res, route, error) ->
	console.log "======= After call ======="
	console.log "Error: #{error}"
	console.log "=========================="

# Run the server under an active domain
d.run ->
	# Log when the web server starts up
	server.listen 7777, -> console.log "#{server.name}[#{process.pid}] online: #{server.url}"
	console.log "#{server.name} is starting..."