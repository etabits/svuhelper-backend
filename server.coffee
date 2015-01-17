express = require('express')
app = express()
debug = require('debug')('app')

mongoose = require('mongoose')
mongoConnectionString = process.env.MONGO_URL || 'mongodb://localhost/svu-helper'
mongoose.connect(mongoConnectionString)






global.etabits = {
	svu: require('./wrapper/')
	jsonMiddleware: require('body-parser').json()
	express: express
	app: app
}
app.use '/v0', require('./apis/v0')

app.use (err, req, res, next)->
	console.log err, req.url, req.body
	console.log err.stack
	res.status(400)
	res.send {success: false, errorMessage: 'Bad Request'}

process.on 'uncaughtException', (err) ->
  console.error('Caught exception: ' + err)

#setTimeout ( ()-> d() ), 55
app.listen 5757, ()->
	console.log 'Started!'