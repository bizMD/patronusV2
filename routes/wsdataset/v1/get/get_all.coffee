require 'sugar'

module.exports = ([rq, rs, nx], db) ->
	# Return JSON Header and prepare collection
	rs.writeHead 200, {"Content-Type": "application/json"}

	# Prepare the variables
	console.log 'Preparing the collection...'
	datasets = db.getCollection 'datasets'
	
	# Check if the requested name exists and return those results
	if Object.equal datasets.DynamicViews, [] then rs.write '[]'
	else rs.write "{\"name\": \"#{name}\", \"view\": \"#{filterPipeline}\"}" for {name, filterPipeline} in datasets.DynamicViews

	# End the response
	console.log 'Ending the reponse...'
	rs.end()
	nx()