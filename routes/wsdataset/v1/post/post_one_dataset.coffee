require 'sugar'
dotize = require 'dotize'
Promise = require 'bluebird'

module.exports = ([rq, rs, nx], db) ->
	# Send the JSON Headers
	rs.writeHead 200, {"Content-Type": "application/json"}

	# Prepare the variables
	{name} = rq.params
	filter = Object.extended dotize.convert Object.reject rq.params, 'name'
	
	# Prepare the database objects
	datasets = db.getCollection 'datasets'
	dyn = datasets.getDynamicView name
	dyn = datasets.addDynamicView name if not dyn?

	# Do initial checks
	new Promise (resolve, reject) ->
		console.log 'Performing initial checks...'
		resolve() if Object.equal [], dyn.filterPipeline
		for item, index in dyn.filterPipeline
			reject 'Filter already registered' if filter.equals item.val
			resolve() if index is dyn.filterPipeline.length - 1

	# If the checks passed, register the filter
	.then ->
		console.log 'Registering the filter...'
		dyn.applyFind filter
		db.saveDatabase()
		rs.write '{"status": "Filter registered"}'

	# Catch any errors
	.catch (error) ->
		console.log 'Catch all error handler'
		console.log "ERROR! #{error}"
		rs.write "{\"error\": #{error}}"

	# End the response at the end
	.finally ->
		console.log 'Ending the response...'
		rs.end()
		nx()