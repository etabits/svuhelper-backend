mongoose	= require('mongoose')

schema = mongoose.Schema {
	_id:	Number
	sessionToken: String
	stud_id: ''
	password: ''

	mainCookie:	{type: String, default: ''}
	moodleCookie:	{type: String, default: ''}
}


Model = mongoose.model('User', schema)


module.exports = Model