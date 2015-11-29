# Require the dependencies
require 'sugar'
soap = require 'soap'
globby = require 'globby'
Promise = require 'bluebird'
{resolve, sep} = require 'path'

module.exports = ([rq, rs, nx], db) ->
	# Set the JSON headers
	rs.writeHead 200, {"Content-Type": "application/json"}

	# Set the variables
	{ws, act} = rq.params
	dataset = Object.reject rq.params, 'ws', 'act'
	wsdlFiles = db.getCollection 'wsdlFiles'
	record = (wsdlFiles.find '$and': [{wsdl: ws}, {action: act}])[0]
	
	# Perform initial checks
	new Promise (resolve, reject) ->
		console.log 'Performing initial checks...'
		reject 'No record exists' if not record?
		reject 'Duplicate exists' if (record.datasets?.find dataset)?
		
		register = for item of record.io.input
			blacklist = ['targetnamespace', 'targetnsalias']
			i = item.replace /\[\]$/, ''
			i if item.toLowerCase() not in blacklist
		input = Object.keys dataset
		reject 'Input in bad format' if not Object.equal input, register
		
		resolve()

	# Then, if the checks pass, get the path to the WSDL file
	.then ->
		console.log 'Preparing the path to the WSDL file...'
		Promise.resolve globby "wsdl#{sep}#{ws}*"

	# Then, create a SOAP client
	.then (path) ->
		console.log 'Loading the WSDL file...'
		new Promise (resolve, reject) ->
			soap.createClient path[0], (error, client) ->
				reject error if error?
				try client.describe()
				catch error then reject error
				resolve client

	# Then, if the WSDL is loaded successfully, make a test request
	.then (client) ->
		console.log 'Testing the input data...'
		new Promise (resolve, reject) ->
			client.addSoapHeader record.credentials if record.credentials?
			client[act] dataset, (error, results) ->
				reject error if error?
				resolve results

	# Then, if the test request was successful, store the requested data set
	.then (results) ->
		console.log 'Inserting data into database...'
		rs.write JSON.stringify result for result in results
		record.datasets ?= []
		record.datasets.push dataset
		wsdlFiles.update record
		console.log wsdlFiles.data

	# Catch any errors or exceptions
	.catch (error) ->
		console.log 'Catch all error handler'
		console.log "ERROR! #{error}"
		rs.write "{\"error\": \"#{error}\"}"

	# Finally, end the response
	.finally ->
		console.log 'Ending response...'
		rs.end()
		nx()