#
#Get All Dynamic Views
#=====================

#This route is designed to return all the dynamic views installed in the database.

#Requiring Dependencies
#----------------------

#Require the modules we need for this class.

require 'sugar'

#Route Definition
#----------------

#This will return the headers with HTTP 200 Status Code, and a JSON content type. Afterwards, it will take collection, get all the dynamic views, and return all of them.

#It uses SugarJS to check if there are no dynamic views, and if there are none, to return an empty array.
#
module.exports = ([rq, rs, nx], db) ->
	rs.writeHead 200, {"Content-Type": "application/json"}

	console.log 'Preparing the collection...'
	datasets = db.getCollection 'datasets'
	
	if Object.equal datasets.DynamicViews, [] then rs.write '[]'
	else rs.write "{\"name\": \"#{name}\", \"view\": \"#{filterPipeline}\"}" for {name, filterPipeline} in datasets.DynamicViews

	console.log 'Ending the reponse...'
	rs.end()
	nx()