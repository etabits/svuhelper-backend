express = require('express')
app = express()

mongoose = require('mongoose')
mongoConnectionString = process.env.MONGO_URL || 'mongodb://localhost/svu-helpers'
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

studentsRouter.get '/exams', (req, res, next)->
	console.log('ABC')
	req.studentObject.get 'exams', {}, (err, data)->
		res.json({success: true, data: data})

v0 = express.Router()
v0.post '/login', jsonMiddleware, (req, res, next)->
	svu.Student.login req.body.stud_id, req.body.password, (err, data)->
		return res.send({success: false, errorMessage: 'Bad Login'}) if err
		res.send {
			success: true
			token: data.doc.sessionToken
			classes: data.classes
		}


v0.use '/student', studentsRouter


app.use '/v0', v0

app.use (err, req, res, next)->
	console.log err, req.body
	res.status(400)
	res.send {success: false, errorMessage: 'Bad Request'}

app.listen(3000);