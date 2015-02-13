"use strict"
_ = require('lodash')

htmlUtils = require('../htmlUtils')

baseUrl = etabits.baseUrl
log = etabits.log

module.exports = {
  params: (stud, opts)->
    {
      url: "#{baseUrl}/tutor_reports.php" + (if opts.pid then "?pid=#{opts.pid}" else "")
    }
  
  handler: (student, results, cb)->
    $ = results.progtermcourse
    programmes = htmlUtils.selectToData($('select[name="pid"]'), 'id', 'code')
    terms = htmlUtils.selectToData($('select[name="term"]'), 'id', 'code')
    courses = htmlUtils.selectToData($('select[name="course"]'), 'id')
    courses = courses.map (c)->
      match = c.label.match(/^(.+)\[(.+)\]$/)
      return if not match
      {
        code: match[2]
        name: match[1]
        id: c.id
      }

    courses = courses.filter (c)-> !!c
    cb(null, {
      programmes: programmes
      terms: terms
      courses: courses
      })
}
