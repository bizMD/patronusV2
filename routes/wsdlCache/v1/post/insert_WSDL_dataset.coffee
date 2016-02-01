#
#Upload One WSDL File
#=================

#This route is designed to return the contents of a named wsdlFile.

#Requiring Dependencies
#----------------------

#Require the modules we need for this class.
#In addition, this also instantiates the database

require 'sugar'
soap = require 'soap'
globby = require 'globby'
Promise = require 'bluebird'
{resolve, sep} = require 'path'

#Blacklist
#---------

#When creating a register, it should not contain certain values. These values are all stored in this variable.

blacklist = ['targetnamespace', 'targetnsalias']

#Promised Checks
#---------------

#Do preliminary checks and reject immediately on failure.

#**Input**: a Loki resultset, a dataset containing the request details, an array of blacklisted values in lowercase

#**Output**:
#1. On success, return nothing. But, there must be a valid record passed in for it to succeed. The Loki record must also have a child named dataset. Finally, the dataset and the record's keys must match exactly.
#2. On failure, the error message appropriate to the error. If it throws an error, the promise chain is broken.

promisedChecks = (record, dataset, blacklist) ->
	console.log 'Performing initial checks...'
	new Promise (resolve, reject) ->
		reject 'No record exists' if not record?
		reject 'Duplicate exists' if (record.datasets?.find dataset)?
		
		register = for item of record.io.input
			i = item.replace /\[\]$/, ''
			i if item.toLowerCase() not in blacklist
		register = register.filter (item) -> !!item
		input = Object.keys dataset
		reject 'Input in bad format' if not Object.equal input, register
		
		resolve()

#Promised SOAP
#-------------

#Check if the file is a proper WSDL by loading it with the SOAP library, and describing the resulting file.

#**Input**: the WSDL file location

#**Output**:
#1. On success, the client object. To pass, it should not generate an error while loading the WSDL file and when describing the services from that file.
#2. On failure, the error message appropriate to the error. If it throws an error, the promise chain is broken.

promisedSOAP = (wsdlPath) ->
	console.log 'Parsing the WSDL file...'
	new Promise (resolve, reject) ->
		soap.createClient wsdlPath, (error, client) ->
			reject error if error?
			try client.describe()
			catch error then reject error
			resolve client

#Promised Results
#----------------

#Check that the WSDL file, method, and arguments all work when put in a query by using all of them together. Include the credentials if it has credentials.

#**Input**: the SOAP client object, the action name, the input dataset, and the database record

#**Output**:
#1. On success, return the client object and WS description. To pass, it should not generate an error while loading the WSDL file and when describing the services from that file.
#2. On failure, the error message appropriate to the error. If it throws an error, the promise chain is broken.

promisedResults = (client, act, dataset, record) ->
	console.log 'Testing the input data...'
	new Promise (resolve, reject) ->
		client.addSoapHeader JSON.parse record.credentials if record.credentials?
		client[act] dataset, (error, results) ->
			reject error if error?
			resolve results

#Update Database
#---------------

#Insert into the database an extra field called "dataset" which is an array containing all of the datasets given by the requestors. It creates this child if it doesn't exist yet and updates the database.

#**Input**: a RESTify request object, the collection, the database record, the dataset, an object with the results of the test call

#**Output**:
#1. On success, insert the object into the database, as well as return the JSON through a stream to the requestor.
#2. On failure, throw an error. This only fails due to an unexpected error.

updateDatabase = (rs, wsdlFiles, record, dataset, results) ->
	console.log 'Inserting data into database...'
	rs.write JSON.stringify results[item] for item of results
	record.datasets ?= []
	record.datasets.push dataset
	wsdlFiles.update record
	console.log wsdlFiles.data

#Error Catcher
#-------------

#This function logs an error and sends back the error message.

#**Input**: a RESTify response object, an error message

#**Output**: returns nothing. It will log and send the error to the requestor.

errorCatcher = (rs, error) ->
	console.log 'Catch all error handler'
	console.log error
	rs.write "{\"error\": #{error}}"

#Final Function
#--------------

#This function ends the response and moves on to the next middleware if defined

finalFunction = (rs, nx) ->
	console.log 'Ending response...'
	rs.end()
	nx()

#Route Definition
#----------------

#This will return the headers with HTTP 200 Status Code, and a JSON content type. It will define some variables before taking action. It will then execute a promise chain that will end with inserting WSDL action arguments to the database if successful. Iff successful, the next refresh cycle, *this* WSDL action will be triggered with the given arguments.

#It tries to validate everything, first by ensuring the data submitted is in a valid format, and then by actually testing the passed in arguments with a real web service call.

#Only when all checks pass does it insert to the database. At the end, it sends back the result of the test database call to let the requestor know what it would look like for them once requested.

module.exports = ([rq, rs, nx], db) ->
	rs.writeHead 200, {"Content-Type": "application/json"}
	{ws, act} = rq.params
	dataset = Object.reject rq.params, 'ws', 'act'
	wsdlFiles = db.getCollection 'wsdlFiles'
	record = (wsdlFiles.find '$and': [{wsdl: ws}, {action: act}])[0]
	
	promisedChecks record, dataset, blacklist
	.then ->
		console.log 'Preparing the path to the WSDL file...'
		Promise.resolve globby "wsdl#{sep}#{ws}*"
	.then (wsdlPath) -> promisedSOAP wsdlPath[0]
	.then (client) -> promisedResults client, act, dataset, record
	.then (results) -> updateDatabase rs, wsdlFiles, record, dataset, results
	.catch (error) -> errorCatcher rs, error
	.finally -> finalFunction rs, nx