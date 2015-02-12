mongoose	= require('mongoose')
Session = require('./Session')

schema = mongoose.Schema {
	_id:	Number
	stud_id: ''
	password: ''

	mainCookie:	{type: String, default: ''}
	moodleToken:{type: String, default: ''}

	lastLogin: Date
	lastActivity: Date
	#activeSession: {type: mongoose.Schema.Types.ObjectId, ref: 'Session'}
	actionsCounter: {type: Number, default: 0}
	created:	{type: Date, default: Date.now}

	passwordExpired: {type: Boolean, default: false}

	programs: [{type: Number, ref: 'Program'}]
	# Deprecated
	sessionToken: String
}

schema.pre 'save', (next)->
	this.lastLogin = new Date() if this.isModified('sessionToken')
	next()

Model = mongoose.model('User', schema)


module.exports = Model