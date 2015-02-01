mongoose	= require('mongoose')

schema = mongoose.Schema {
	_id:	Number
	code: String
	name: String
}


Model = mongoose.model('Program', schema)


module.exports = Model