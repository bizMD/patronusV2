require 'sugar'
Promise = require 'bluebird'

module.exports = ([rq, rs, nx], db) ->
	# Send the JSON Headers
	rs.writeHead 200, {"Content-Type": "application/json"}
	
	# Prepare variables and database objects
	{name} = rq.params
	datasets = db.getCollection 'datasets'
	dyn = datasets.getDynamicView name

	# Check the view exists
	new Promise (resolve, reject) ->
		console.log 'Performing initial checks...'
		reject 'View now found' if dyn is null
		resolve()

	# Retrieve the data
	.then ->
		console.log 'Retrieving the data...'
		if Object.equal [], dyn.data() then rs.end '[]'
		else rs.write JSON.stringify data for data in dyn.data()

	.catch (error) ->
		console.log 'Catch all error handler'
		console.log "ERROR! #{error}"
		rs.write "{\"error\": #{error}}"

	.finally ->
		console.log 'Ending the response...'
		rs.end()
		nx()