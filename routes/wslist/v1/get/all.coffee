module.exports = ([rq, rs, nx], db) ->
	rs.writeHead 200, {"Content-Type": "text/plain"}
	wsdlFiles = db.getCollection 'wsdlFiles'

	console.log wsdlFiles.data
	for wsdl in wsdlFiles.data
		# Important to touch only the clone to preserve the original
		data = Object.reject wsdl, 'meta', '$loki'
		rs.write JSON.stringify data
	
	rs.end()
	nx()