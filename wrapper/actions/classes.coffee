"use strict"
_ = require('lodash')

htmlUtils = require('../htmlUtils')

baseUrl = etabits.baseUrl
log = etabits.log

module.exports = {
  params: ()-> {url: "#{baseUrl}/std_classes.php"}
  
  handler: (student, results, cb)->
    table = results.classes('table table table').eq(0)
    data = htmlUtils.tableToData(table)
    data = data.map (c)->
      details = c.Class.match(/^(.{2,4})_(.{2,7}).+(?:D|C)(\d+)_/)
      if not details
        log.warning("Could not match class", c.Class, c)
        #console.log c
        details={}
      {
        #orig: c
        class: parseInt(details[3]) || 0
        number: parseInt(details[3]) || 0
        tutor: {
          name: c.Tutor
          email: c['Tutor mail']
        }
        term: {
          code: c.Term
        }
        course: {
          program: details[1] || ''
          code: details[2] || ''
          name: c.Course
        }
      }

    cb(null, data)
}