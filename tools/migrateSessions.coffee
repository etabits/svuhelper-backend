#!/usr/bin/env coffee
mongoose = require('mongoose')
async = require('async')

mongoConnectionString = process.env.MONGO_URL || 'mongodb://localhost/svu-helper'
mongoose.connect(mongoConnectionString)

User = require('../models/User')
Session = require('../models/Session')

cb = (stud, done)->
	sessionDocument = {
		token: stud.sessionToken
		student: stud._id
		deviceType: 'm'
		description: "Migrated Session for #{stud.stud_id}"
	}
	Session.update {student: stud._id, type: 'm'}, sessionDocument, {upsert: true}, done

User.find {}, (err, students)->
	async.map students, cb, (err, docs)->
		console.log 'Error:', err
		console.log "Upserted #{docs.length} documents"
		process.exit(0)
