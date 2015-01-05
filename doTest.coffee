
mongoose = require('mongoose')

mongoConnectionString = process.env.MONGO_URL || 'mongodb://localhost/svu-helper'
mongoose.connect(mongoConnectionString)


svu = require './wrapper/'


###
3 cases to check:
bad login
no doc
bad cookie
###

if false

	stud = new svu.Student({
		stud_id: 'hasan_29643'
		password: ''
	})

	stud.get 'exams', {}, (err, data)->
		console.log err, data
		process.exit(0)
	
else
	svu.Student.login 'hasan_29643', '', (err, data)->
		console.log err, data
		process.exit(0)
