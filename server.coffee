
require('./boot')

express = require('express')
app = express()


global.etabits.app = app
global.etabits.express = express



#console.log global.etabits.data
app.use '/v0',   require('./apis/v0')
app.use '/v0p1', require('./apis/v0p1')
app.use '/dummy', require('./apis/dummy')
mappedErrors = {
	'BAD_STUD_ID_FORMAT': [400, 'BAD_STUD_ID_FORMAT', 'Please use prober format for your student id (Example: name_98765)!']
	'BADLOGIN': [401, 'BADLOGIN', 'Bad username/password!']
	'INVALID_TOKEN': [401, 'INVALID_TOKEN', 'Invalid session!\nPlease login again.']
}
mappedErrors.ETIMEDOUT = mappedErrors.ECONNRESET = mappedErrors.ENOTFOUND = [502, 'CONNERR', 'Connection Error!\nSVU servers are probably having some problem, Please try again in a few minutes...']
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