"use strict"
_ = require('lodash')

htmlUtils = require('../htmlUtils')

baseUrl = etabits.baseUrl
log = etabits.log

module.exports = {
  params: (student, options)->
    {
      url:  "#{baseUrl}/calendar_ex.php?pid=8&rad=1"
      form: {
        act:  'add_tasktype'
        edate:  ''
        from_page:  '/isis/calendar_ex.php?pid=8&rad=1'
        pid:  ''
        schedule_type:  1
        sdate:  ''
        sid:  student.studentId
        term_id:  '26'
        course: etabits.data.allCoursesIds
      }
      method: 'POST'
    }
  handler: (student, results, cb)->
    table = results.exams('#tt4').eq(0)
    data = htmlUtils.tableToData(table)
    #debug "Got #{data.length} table rows from #{student.studentId} exams result"
    #console.log data
    data = _.chain(data).reject( (e)-> !e.Start ).value()
    #.sortBy(['Date', 'Start']).value()

    data = data.map (c)->
      {
        course: {
          code: c.Course
        }
        date: new Date(c.Date+'T'+c.Start)
        telecenter: {
          name: c.TELECENTER_NAME
        }
      }
    data = _.chain(data).sortBy('date').value()
    cb(null, data)
}
