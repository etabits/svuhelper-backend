mongoose	= require('mongoose')

schema = mongoose.Schema {
	year: Number
	season: {type: String, enum: ['F', 'S']}
}


Model = mongoose.model('Tutor', schema)


module.exports = Model