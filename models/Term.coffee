mongoose	= require('mongoose')

schema = mongoose.Schema {
	_id:	Number
	year: Number
	season: {type: String, enum: ['F', 'S']}
}


Model = mongoose.model('Term', schema)


module.exports = Model