require 'sugar'

module.exports = ([rq, rs, nx], db) ->
	{name} = rq.params
	filter = Object.reject rq.params, 'name'
	console.log filter

	datasets = db.getCollection 'datasets'
	console.log datasets.getDynamicView name
	console.log Object.equal null, datasets.getDynamicView name
	dyn = datasets.addDynamicView name if Object.equal null, datasets.getDynamicView name
	dyn.applyFind filter
	db.saveDatabase()

	rs.writeHead 200, {"Content-Type": "application/json"}
	rs.write '{"status": "Filter registered"}'
	rs.end()
	nx()