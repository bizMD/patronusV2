require 'sugar'
del = require 'del'
docco = require 'docco'
globby = require 'globby'
Promise = require 'bluebird'
{exec, spawn} = require 'child_process'
{watch} = require 'chokidar'
{files} = require 'node-dir'
{resolve, sep, dirname, extname, basename} = require 'path'

option '-t', '--test', 'Does nothing'

spinServer = (server) ->
	if server?
		console.log "Server [pid #{server.pid}] is shutting down"
		process.kill server.pid, 'SIGTERM'
	server = spawn 'node' , ['node_modules/coffee-script/bin/coffee' , 'server.coffee']
	console.log "Server [pid #{server.pid}] is starting up"
	server.on 'error', (err) -> throw err if err?
	server.stdout.on 'data', (data) -> console.log data.toString()
	server.stderr.on 'data', (data) -> console.log data.toString()
	server.on 'exit', -> console.log "Server [pid #{server.pid}] has shut down"
	server

task 'docs', 'Create documentation for the source code', ->
	docco_cmd = "node node_modules/docco/bin/docco --layout linear"
	globby ['routes/**/*.coffee', 'helper/*.coffee', 'Cakefile', 'server.coffee']
	.then (paths) ->
		for path in paths
			pathDir = dirname path
			docco_cmd += " -o docs/#{pathDir} #{path}"
		exec docco_cmd, (error, a, b) ->
			reject error if error?
			console.log a
			console.log b
	.catch (error) ->
		console.log 'ERROR! Could not generate documents'
		console.log error

task 'clean', 'Reset the database and clear out files', ->
	del ['db/*', '!db/.gitkeep', 'wsdl/*', '!wsdl/.gitkeep']
	.then (paths) ->
		console.log 'Deleted files: ' + paths.join ', '
	.catch (error) ->
		console.log 'ERROR! Could not generate documents'
		console.log error

task 'watch', 'Reset the server on file change', ->
	server = spinServer()
	reboot = (path) ->
		console.log "Change detected in #{path}"
		server = spinServer server
	eyes = watch ['routes', 'helper', 'server.coffee']
	eyes.on 'change', (path) -> reboot 'server.coffee'