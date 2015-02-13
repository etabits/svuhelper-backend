"use strict"
mongoose	= require('mongoose')

schema = mongoose.Schema {
	email: String
	name: String
}


Model = mongoose.model('Tutor', schema)


module.exports = Model