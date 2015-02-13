"use strict"
_ = require('lodash')

htmlUtils = require('../htmlUtils')

baseUrl = etabits.baseUrl
log = etabits.log

module.exports = {
  params: (stud, opts)->
    {
      url: "#{baseUrl}/std_class_assign.php?pid=#{opts.pid}"
    }
  
  handler: (student, results, cb)->
    $ = results.get_selectable_classes
    selects = $('select.input_s[name="class_id[]"]')
    result = []
    for i in [0..selects.length-1]
      s = selects.eq(i)
      sData = htmlUtils.selectToData(s, 'id')
      courseCode = sData[0].label.match(/\[ \d+ \/ \d+ \] C\d+-\w+_(\w+)_C\d+_(?:F|S)\d{2}$/i)
      chosenClass = 0
      if courseCode 
        courseCode = courseCode[1]
      else
        infos = sData[0].label.match(/^\w+_(\w+)_C(\d+)_(?:F|S)\d{2}$/i)
        courseCode = infos[1]
        chosenClass = parseInt(infos[2])


      result.push {
        totalClasses: sData.length
        course: etabits.data.coursesByCode[courseCode].publicObject
        chosenClass: chosenClass
      }

    cb(null, result)

}
