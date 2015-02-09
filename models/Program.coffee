mongoose	= require('mongoose')
Schema = mongoose.Schema

schema = mongoose.Schema {
  _id:	Number
  code: {type: String}
  name: {type: String}
  courses: [{type: Number, ref: 'Course'}]
  expose: {type: Boolean, default: false}
}


Model = mongoose.model('Program', schema)


module.exports = Model