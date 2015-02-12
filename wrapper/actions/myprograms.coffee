_ = require('lodash')

htmlUtils = require('../htmlUtils')

baseUrl = etabits.baseUrl
log = etabits.log

module.exports = {
  params: (stud, opts)->
    {
      url: "#{baseUrl}/std_class_assign.php"
    }
  
  handler: (student, results, cb)->
    $ = results.myprograms
    programmes = htmlUtils.selectToData($('select[name="pid"]'), 'id', 'code')
    cb(null, programmes)
}
