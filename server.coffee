debug = require('debug')
log = {
	verbose:debug('svuhelper:verbose')	# blue
	green:	debug('svuhelper:green')	# green
	warning:debug('svuhelper:warning')	# yellow
	info:	debug('svuhelper:info')		# darkblue
	purple:	debug('svuhelper:purple')	# purple
	error:	debug('svuhelper:error')	# red
}
log.error.log = console.error.bind(console)
log.warning.log = console.error.bind(console)

l(a) for a,l of log

express = require('express')
app = express()

mongoose = require('mongoose')
mongoConnectionString = process.env.MONGO_URL || 'mongodb://localhost/svu-helper'
mongoose.connect(mongoConnectionString)






global.etabits = {
	baseUrl: 'https://www.svuonline.org/isis'
	log: log
	jsonMiddleware: require('body-parser').json()
	express: express
	app: app
	data: {
		terms: [
			{"id": 26, "code": "S14" }
			{"id": 27, "code": "F14" }
		]
		programs: [
			{"id": 2, "code": "ISE" }
			{"id": 7, "code": "ENG" }
			{"id": 8, "code": "BIT" }
			{"id": 21, "code": "BL" }
		]
	}
}
global.etabits.svu = require('./wrapper/')

for collectionName in ['terms', 'programs']
	collectionData = global.etabits.data[collectionName]
	global.etabits.data[collectionName+'ByCode'] = {}
	global.etabits.data[collectionName+'ByCode'][row.code] = row for row in collectionData

#console.log global.etabits.data
app.use '/v0',   require('./apis/v0')
app.use '/v0p1', require('./apis/v0p1')
app.use '/dummy', require('./apis/dummy')
mappedErrors = {
	'BADLOGIN': [401, 'BADLOGIN', 'Bad username/password!']
	'INVALID_TOKEN': [401, 'INVALID_TOKEN', 'Invalid session!\nPlease login again.']
}
mappedErrors.ECONNRESET = mappedErrors.ENOTFOUND = [502, 'CONNERR', 'Connection Error!\nSVU servers are probably having some problem, Please try again in a few minutes...']
app.use (err, req, res, next)->
	console.log err, err.code, req.url, req.body
	console.log err.stack
	result = {
		success: false
		errorCode: 'OTHER'
		errorMessage: 'Unspecified Error Occurred.\nPlease try again later. If the error persisted, contact us.'
	}
	if mappedErrors[err.code]
		res.status(mappedErrors[err.code][0])
		result.errorCode = mappedErrors[err.code][1]
		result.errorMessage = mappedErrors[err.code][2]
	else
		res.status(500)
	res.send result

process.on 'uncaughtException', (err) ->
  console.error('Caught exception: ' + err)
  console.log(err.stack)

#setTimeout ( ()-> d() ), 55
app.listen 5757, ()->
	console.log 'Started!'