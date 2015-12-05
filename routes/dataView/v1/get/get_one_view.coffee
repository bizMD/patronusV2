#
#Get Dynamic View
#================

#This route is designed to return a named dynamic view

#Requiring Dependencies
#----------------------

#Require the modules we need for this class.
#In addition, this also instantiates the database

require 'sugar'
Promise = require 'bluebird'

#Promised Checks
#---------------

#This function returns a promise that will either resolve to nothing, or reject into an error message.

#**Input**: a Loki dynamic view

#**Output**:
#1. On success, nothing. But it must detect a dynamic view is present for success.
#2. On failure, the error message returned. If rejected, the promise chain will break.

promisedChecks = (dyn) ->
	new Promise (resolve, reject) ->
		console.log 'Performing initial checks...'
		reject 'View now found' if dyn is null
		resolve()

#Send View
#---------

#This function sends either an empty array if the dynamic view has no data yet, or it will stream the data into the response object.

#**Input**: a Loki dynamic view

sendView = (rs, dyn) ->
	console.log 'Retrieving the data...'
	if Object.equal [], dyn.data() then rs.end '[]'
	else rs.write JSON.stringify Object.reject data, 'meta', '$loki' for data in dyn.data()

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
	console.log 'Ending the response...'
	rs.end()
	nx()

#Route Definition
#----------------

#This will return the headers with HTTP 200 Status Code, and a JSON content type. Afterwards, it will take the dynamic view and return that. If the view is empty, it will return a null array
#

module.exports = ([rq, rs, nx], db) ->
	rs.writeHead 200, {"Content-Type": "application/json"}
	
	{name} = rq.params
	datasets = db.getCollection 'datasets'
	dyn = datasets.getDynamicView name

	promisedChecks dyn
	.then -> sendView rs, dyn
	.catch (error) -> errorCatcher rs, error
	.finally -> finalFunction rs, nx