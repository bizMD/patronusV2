#
#Get All WSDL Files
#==================

#This route is designed to take all the contents of the wsdlFiles collection.

#Requiring Dependencies
#----------------------

#Require the modules we need for this class.
#In addition, this also instantiates the database

require 'sugar'
{resolve} = require 'path'

#Route Definition
#----------------

#This will return the headers with HTTP 200 Status Code, and a JSON content type. Afterwards, it will take collection, iterate over all the stored data, and remove the meta and $loki tags.

#It uses SugarJS to reject these tags, which creates a new object instead of modifying the original. This is important so as not to change the database accidentally.
#
module.exports = ([rq, rs, nx], db) ->
	rs.writeHead 200, {"Content-Type": "application/json"}

	wsdlFiles = db.getCollection 'wsdlFiles'
	console.log wsdlFiles.data
	
	rs.write JSON.stringify Object.reject wsdl, 'meta', '$loki' for wsdl in wsdlFiles.data
	
	rs.end()
	nx()