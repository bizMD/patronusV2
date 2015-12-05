#
#Create New Dynamic View
#=======================

#This route is designed to insert a new dynamic view that is properly defined.

#Requiring Dependencies
#----------------------

#Require the modules we need for this class.

require 'sugar'
dotize = require 'dotize'
Promise = require 'bluebird'

#Promised Checks
#---------------

#This function returns a promise that will either resolve to a dynamic view, or reject into an error message.

#**Input**: a Loki dataset, name of the dynamic view, the filter that was user-supplied

#**Output**:
#1. On success, nothing. But to pass, it must *not* find that the submitted filter already exists, and it must find the filter actually exists and was submitted.
#2. On failure, the error message returned. If rejected, the promise chain will break.

promisedChecks = (datasets, name, filter) ->
	console.log 'Performing initial checks...'
	new Promise (resolve, reject) ->
		reject 'Filter already exists' if (datasets.getDynamicView name)?
		reject 'No filter submitted' if not Object.isObject filter
		
		dyn = datasets.addDynamicView name
		resolve dyn if Object.equal [], dyn.filterPipeline
		for item in dyn.filterPipeline
			resolve dyn if item is dyn.filterPipeline.last()

#Apply Find
#----------

#This function applies the filter to the collection, creating a dynamic view. It then saves the database.

#**Input**: a Loki dynamic view, a Loki database, the user submitted filter, and a RESTify response

applyFilter = (dyn, db, filter, rs) ->
	console.log dyn
	console.log 'Registering the filter...'
	dyn.applyFind filter
	db.saveDatabase()
	rs.write '{"status": "Filter registered"}'

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
	filter = Object.extended dotize.convert Object.reject rq.params, 'name'
	datasets = db.getCollection 'datasets'

	promisedChecks datasets, name, filter
	.then (dyn) -> applyFilter dyn, db, filter, rs
	.catch (error) -> errorCatcher rs, error
	.finally -> finalFunction rs, nx