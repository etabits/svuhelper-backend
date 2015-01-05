
mongoose = require('mongoose')

mongoConnectionString = process.env.MONGO_URL || 'mongodb://localhost/svu-helper'
mongoose.connect(mongoConnectionString)

User = require('./wrapper/User')

User.findById 29643, ()->
	console.log arguments