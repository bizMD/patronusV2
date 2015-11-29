require 'sugar'
dotize = require 'dotize'

module.exports = ([rq, rs, nx], db) ->
	{name} = rq.params
	console.log rq.params.hasOwnProperty
	console.log dotize

	filter = Object.extended Object.reject rq.params, 'name'
	console.log filter
	filter = dotize.convert filter
	console.log filter
	
	datasets = db.getCollection 'datasets'
	console.log datasets.getDynamicView name
	console.log Object.equal null, datasets.getDynamicView name
	dyn = datasets.getDynamicView name
	dyn = datasets.addDynamicView name if Object.equal null, datasets.getDynamicView name

	console.log filter
	dyn.applyFind filter
	db.saveDatabase()

	rs.writeHead 200, {"Content-Type": "application/json"}
	rs.write '{"status": "Filter registered"}'
	rs.end()
	nx()