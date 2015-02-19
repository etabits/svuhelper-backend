"use strict"
_ = require('lodash')

htmlUtils = require('../htmlUtils')

baseUrl = etabits.baseUrl
log = etabits.log

module.exports = {
  params: (stud, opts)->
    [
      {
        $name: 'time'
        method: 'POST'
        url: "#{baseUrl}/calendar_lec.php?pid="
        form: {
          pid: ''
          course: opts.courses
          term: opts.tid
          act: 'add_tasktype'
          from_page: "/isis/calendar_lec.php?pid="
        }
      }
    ]
  
  handler: (student, results, cb)->
    bigTable = results.time('table[style="border:1px solid #DDD; border-collapse:collapse"]');
    #bigTableData = htmlUtils.tableToData(bigTable, false, true)
    tds = bigTable.find('td.cal_td')
    timeRows = bigTable.find('td.cal_td > table tr')
    currentDay = ''
    classesByTimeTable = []
    courseCodes = []
    for i in [0..tds.length-1]
      td = tds.eq(i)
      text = td.text().trim()
      #console.log '>>', text
      if -1!=['Satarday', 'Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednsday', 'Wednesday', 'Thursday', 'Friday'].indexOf(text)
        text='Wednesday' if 'Wednsday'==text
        text='Saturday' if 'Satarday'==text
        currentDay = text
        #console.log currentDay
      else if text.match(/^C\d+$/)
        classesByTimeTable.push({class: parseInt(text.substr(1)), day: currentDay})
      else if text.length
        courseCodes.push(text)



    for i in [0..timeRows.length-1] # a class
      tr = timeRows.eq(i)
      tds = tr.find('td')
      startDate = 9 * 60;
      for k in [0..tds.length-1] # hours in day
        isHavingClassNow = -1==['#C6DCFC', '#A1C6FC'].indexOf(tds.eq(k).attr('bgcolor'))
        if isHavingClassNow
          if not classesByTimeTable[i]
            log.warning("classesByTimeTable[#{i}] not set", classesByTimeTable)
          classesByTimeTable[i].hour = (new Date((startDate+30*k)*60000)).toGMTString().substr(17, 5);
          break
    for courseCode, i in courseCodes
      classesByTimeTable[i].course = courseCode
    
    
    cb(null, classesByTimeTable)
}