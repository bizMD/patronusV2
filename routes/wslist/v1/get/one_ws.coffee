require 'sugar'

module.exports = ([rq, rs, nx], db) ->
	rs.writeHead 200, {"Content-Type": "text/plain"}

	{ws} = rq.params
	wsdlFiles = db.getCollection 'wsdlFiles'
	record = wsdlFiles.find wsdl: ws
	return rs.end '{"error": "No record exists"}' if record.length is 0

	for wsdl in record
		# Important to touch only the clone to preserve the original
		data = Object.reject wsdl, 'meta', '$loki'
		rs.write JSON.stringify data

	rs.end()

	nx()