"use strict"
mongoose	= require('mongoose')

schema = mongoose.Schema {
	token: String
	student: {type: Number, ref: 'User'}

	deviceType:   {type: String, enum: ['a', 'm', 'w']} # Android / Web
	description: String


	lastActivity: {type: Date, default: Date.now}
	created: {type: Date, default: Date.now}
}

schema.pre 'save', (next)->
	this.updated = new Date()
	next()

Model = mongoose.model('Session', schema)


module.exports = Model