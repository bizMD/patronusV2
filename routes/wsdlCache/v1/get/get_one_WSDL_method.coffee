#
#Get A Function From A WSDL File
#===============================

#This route is designed to return a named function of a named wsdlFile.

#Requiring Dependencies
#----------------------

#Require the modules we need for this class.
#In addition, this also instantiates the database

require 'sugar'
Promise = require 'bluebird'
{resolve} = require 'path'

#Promised Record
#---------------

#This function returns a promise that will either resolve to the WSDL record, or reject into an error message.

#**Input**: a RESTify request object, the database

#**Output**:
#1. On success, the WSDL record with action taken from the request object. It must find the record in the database for it to succeed.
#2. On failure, the error message "Either #{ws} or #{act} does not exist". It will reject if the record does not exist in the database.

promisedRecord = (rq, db) ->
	new Promise (resolve, reject) ->
		{ws, act} = rq.params
		wsdlFiles = db.getCollection 'wsdlFiles'
		query = [{wsdl: ws}, {action: act}]
		record = (wsdlFiles.find '$and': query)[0]
		reject "Either #{ws} or #{act} does not exist" if not record?
		resolve record

#Send Action
#-----------

#This function logs the received record and sends back the retrieved WSDL to the requestor.

#**Input**: a RESTify response object, a loki object

#**Output**:
#1. On success, returns nothing. It will log and send the record to the requestor.
#2. On failure, it will only fail on an unexpected error.

sendAction = (rs, record) ->
	console.log record
	rs.write JSON.stringify record.io
	rs.end()

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

#This will return the headers with HTTP 200 Status Code, and a JSON content type. Afterwards, it will take collection, take the stored data, and remove the meta and $loki tags.

module.exports = ([rq, rs, nx], db) ->
	rs.writeHead 200, {"Content-Type": "application/json"}

	promisedRecord rq, db
	.then (record) -> sendAction rs, record
	.catch (error) -> errorCatcher rs, error
	.finally -> finalFunction rs, nx