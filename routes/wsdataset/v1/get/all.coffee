require 'sugar'

module.exports = ([rq, rs, nx], db) ->
	datasets = db.getCollection 'datasets'
	
	rs.writeHead 200, {"Content-Type": "application/json"}
	if Object.equal datasets.DynamicViews, [] then rs.write '[]'
	else rs.write JSON.stringify datasets.DynamicViews
	rs.end()
	
	nx()