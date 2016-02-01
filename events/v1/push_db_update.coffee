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

#**Input**: a SocketIO object, a Loki dynamic view

sendView = (socket, dyn, filter) ->
	console.log 'Retrieving the data...'
	socket.filters ?= []
	socket.filters.push filter
	if Object.equal [], dyn.data() then socket.emit 'new data delivery', '[]'
	else socket.emit 'new data delivery', JSON.stringify Object.reject data, 'meta', '$loki' for data in dyn.data()

#Error Catcher
#-------------

#This function logs an error and sends back the error message.

#**Input**: a SocketIO object, an error message

#**Output**: returns nothing. It will log and send the error to the requestor.

errorCatcher = (socket, error) ->
	console.log 'Catch all error handler'
	console.log error
	socket.emit 'new data delivery error', "{\"error\": #{error}}"

#Final Function
#--------------

#This function ends the response and moves on to the next middleware if defined

finalFunction = ->
	console.log 'Ending the response...'

#Route Definition
#----------------

#This will return the dynamic view. If the view is empty, it will return a null array
#

module.exports = (filter, socket, db) ->
	datasets = db.getCollection 'datasets'
	dyn = datasets.getDynamicView filter

	promisedChecks dyn
	.then -> sendView socket, dyn, filter
	.catch (error) -> errorCatcher socket, error
	.finally -> finalFunction()