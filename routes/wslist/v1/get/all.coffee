module.exports = ([rq, rs, nx], db) ->
	rs.writeHead 200, {"Content-Type": "application/json"}
	wsdlFiles = db.getCollection 'wsdlFiles'
	console.log wsdlFiles.data
	
	# Important to touch only the clone to preserve the original
	rs.write JSON.stringify Object.reject wsdl, 'meta', '$loki' for wsdl in wsdlFiles.data		
	
	rs.end()
	nx()