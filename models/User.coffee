mongoose	= require('mongoose')

schema = mongoose.Schema {
	_id:	Number
	sessionToken: String
	stud_id: ''
	password: ''

	mainCookie:	{type: String, default: ''}
	moodleToken:{type: String, default: ''}

	lastLogin: Date
	lastActivity: Date
}

schema.pre 'save', (next)->
	this.lastLogin = new Date() if this.isModified('sessionToken')
	next()

Model = mongoose.model('User', schema)


module.exports = Model