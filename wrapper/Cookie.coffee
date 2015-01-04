mongoose	= require('mongoose')

schema = mongoose.Schema {
	_id:	Number
	main:	{type: String, default: ''}
	moodle:	{type: String, default: ''}
}


Model = mongoose.model('Cookie', schema)


module.exports = Model