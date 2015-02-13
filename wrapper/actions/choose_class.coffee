"use strict"
_ = require('lodash')

htmlUtils = require('../htmlUtils')

baseUrl = etabits.baseUrl
log = etabits.log

module.exports = {
  params: (stud, opts)->
    {
      url: "#{baseUrl}/functions/join_class.php"
      form: {
        class_id: [opts.classId]
        course_id: [opts.cid]
        student_class_id: []
        org_class_id: []
        act:  'join_class'
        edate:  ''
        from_page:  '/isis/std_class_assign.php?pid=' + opts.pid
        program_id:  opts.pid
        term_id:  opts.tid
        student_id: stud.studentId
      }
      method: 'POST'
    }
  
  handler: (student, results, cb, opts)->
    #console.log results.choose_class.html()
    cb(null)

}
