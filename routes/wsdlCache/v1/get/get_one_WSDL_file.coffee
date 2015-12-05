#
#Get One WSDL File
#=================

#This route is designed to return the contents of a named wsdlFile.

#Requiring Dependencies
#----------------------

#Require the modules we need for this class.
#In addition, this also instantiates the database

require 'sugar'
Promise = require 'bluebird'
{resolve} = require 'path'

#Promised Record
#----------------

#This function returns a promise that will either resolve to the WSDL record, or reject into an error message.

#**Input**: a RESTify request object, the database

#**Output**:
#1. On success, the WSDL record taken from the request object. It must find the record in the database for it to succeed.
#2. On failure, the error message "WSDL #{ws} does not exist". It will reject if the record does not exist in the database.

promisedRecord = (rq, db) ->
	new Promise (resolve, reject) ->
		{ws} = rq.params
		wsdlFiles = db.getCollection 'wsdlFiles'
		records = wsdlFiles.find wsdl: ws
		reject "WSDL #{ws} does not exist" if records.length is 0
		resolve records

#Send WSDL
#---------

#This function logs the received record and sends back the retrieved WSDL to the requestor. It will remove the meta and $loki tags of this record.

#It uses SugarJS to reject these tags, which creates a new object instead of modifying the original. This is important so as not to change the database accidentally.

#**Input**: a RESTify response object, a loki object

#**Output**:
#1. On success, returns nothing. It will log and send the record to the requestor.
#2. On failure, it will only fail on an unexpected error.

sendWSDL = (rs, records) ->
	console.log records
	rs.write JSON.stringify Object.reject record, 'meta', '$loki' for record in records

#Error Catcher
#-------------

#This function logs an error and sends back the error message.

#**Input**: a RESTify response object, an error message

#**Output**: returns nothing. It will log and send the error to the requestor.

errorCatcher = (rs, error) ->
	console.log error
	rs.write "{\"error\": #{error}}"

#Final Function
#--------------

#This function ends the response and moves on to the next middleware if defined

finalFunction = (rs, nx) ->
	rs.end()
	nx()

#Route Definition
#----------------

#This will return the headers with HTTP 200 Status Code, and a JSON content type. Afterwards, it will take collection, iterate over all the stored data, and remove the meta and $loki tags.

module.exports = ([rq, rs, nx], db) ->
	# Set the JSON headers
	rs.writeHead 200, {"Content-Type": "application/json"}

	promisedRecord rq, db
	.then (record) -> sendWSDL rs, record
	.catch (error) -> errorCatcher rs, error
	.finally -> finalFunction rs, nx