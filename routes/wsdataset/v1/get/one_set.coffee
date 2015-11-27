require 'sugar'

module.exports = ([rq, rs, nx], db) ->
	rs.writeHead 200, {"Content-Type": "application/json"}
	
	{name} = rq.params
	datasets = db.getCollection 'datasets'
	dyn = datasets.getDynamicView name
	return rs.end '{"error": "View not found"}' if Object.equal dyn, null
	
	if Object.equal [], dyn.data() then rs.end '[]'
	else rs.write JSON.stringify data for data in dyn.data()
	rs.end()
	nx()