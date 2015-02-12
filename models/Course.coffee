mongoose	= require('mongoose')

schema = mongoose.Schema {
	_id:	Number
	code: String
	name: String
}

schema.virtual('publicObject').get ()-> {
  id: this.id
  code: this.code
  name: this.name
}


Model = mongoose.model('Course', schema)


module.exports = Model