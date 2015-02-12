_ = require('lodash')

htmlUtils = require('../htmlUtils')

baseUrl = etabits.baseUrl
log = etabits.log

module.exports = {
  params: (stud, opts)->
    {
      url: "#{baseUrl}/std_class_assign.php?pid=#{opts.pid}"
    }
  
  handler: (student, results, cb, opts)->
    targetCid = opts.cid
    $ = results.get_selectable_classes2
    courseIds = $('input[type="hidden"][name="course_id[]"]').map( (i,elem)-> parseInt($(this).attr('value')) ).get()

    selects = $('select.input_s[name="class_id[]"]')
    result = []
    for i in [0..selects.length-1]
      continue unless courseIds[i] == targetCid
      s = selects.eq(i)
      sData = htmlUtils.selectToData(s, 'id')
      console.log sData
      chosenClass = null
      for c in sData
        cInfo = c.label.match(/^\[ (\d+) \/ (\d+) \] C(\d+)-\w+_(\w+)_C\d+_(?:F|S)\d{2}$/i)
        if not cInfo
          chosenClass = c.label.match(/^\w+_\w+_C(\d+)_(?:F|S)\d{2}$/i)[1]
          chosenClass = c.id
          continue

        result.push {
          id: parseInt(c.id)
          totalEnrolled: parseInt(cInfo[1])
          totalCapacity: parseInt(cInfo[2])
          number: parseInt(cInfo[3])
          #course: etabits.data.coursesByCode[cInfo[4]]
          chosen: chosenClass==c.id
        }
      break
      #courseCode = sData[0].label.match(/\[ (\d+) \/ (\d+) \] C(\d+)-\w+_\w+_C\d+_(?:F|S)\d{2}$/i)



    cb(null, _.sortBy(result, 'number'))

}
