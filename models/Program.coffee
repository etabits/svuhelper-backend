"use strict"
mongoose	= require('mongoose')
Schema = mongoose.Schema

schema = mongoose.Schema {
  _id:	Number
  code: {type: String}
  name: {type: String}
  courses: [{type: Number, ref: 'Course'}]
  expose: {type: Boolean, default: false}
}

schema.virtual('publicObject').get ()-> {
  id: this.id
  code: this.code
  name: this.name
}


Model = mongoose.model('Program', schema)


module.exports = Model