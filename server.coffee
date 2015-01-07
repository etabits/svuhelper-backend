express = require('express')
app = express()
debug = require('debug')('app')

mongoose = require('mongoose')
mongoConnectionString = process.env.MONGO_URL || 'mongodb://localhost/svu-helper'
mongoose.connect(mongoConnectionString)

jsonMiddleware = require('body-parser').json()

svu = require './wrapper/'


studentsRouter = express.Router()
studentsRouter.use (req, res, next)->
	svu.Student.restoreFromToken req.query.token, (err, stud)->
		return next(err) if err

		console.log(stud)
		req.studentObject = stud
		next()

studentsRouter.get '/:section(exams|results)', (req, res, next)->
	console.log req.params
	req.studentObject.get req.params.section, {}, (err, data)->
		res.json({success: true, data: data})

v0 = express.Router()
v0.post '/login', jsonMiddleware, (req, res, next)->
	svu.Student.login req.body.stud_id, req.body.password, (err, data)->
		console.error(err) if err
		
		return res.send({success: false, errorMessage: 'Bad Login'}) if err
		res.send {
			success: true
			token: data.doc.sessionToken
			classes: data.classes
		}

v0.get '/hello', (req, res)->
	res.send {
		success: true
		newsHTML: 'Welcome to SVU Student\'s Helper<br />Use the form below to login.'
	}


v0.use '/student', studentsRouter


app.use '/v0', v0

app.use (err, req, res, next)->
	console.log err, req.url, req.body
	console.log err.stack
	res.status(400)
	res.send {success: false, errorMessage: 'Bad Request'}

app.listen 5757, ()->
	console.log 'Started!'