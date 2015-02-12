_ = require('lodash')

htmlUtils = require('../htmlUtils')

baseUrl = etabits.baseUrl
log = etabits.log

module.exports = {
  params: (stud, opts)->
    [
      {
        $name: 'tutors'
        url: "#{baseUrl}/search_ajax/tutor_report.php?q=#{opts.pid},#{opts.cid},#{opts.tid}"
      }
      {
        $name: 'time'
        method: 'POST'
        url: "#{baseUrl}/calendar_lec.php?pid=#{opts.pid}"
        form: {
          pid: opts.pid
          'course[]': opts.cid
          term: opts.tid
          act: 'add_tasktype'
          from_page: "/isis/calendar_lec.php?pid=#{opts.pid}"
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
    for i in [0..tds.length-1]
      td = tds.eq(i)
      text = td.text()
      #console.log '>>', text
      if -1!=['Satarday', 'Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednsday', 'Wednesday', 'Thursday', 'Friday'].indexOf(text)
        text='Wednesday' if 'Wednsday'==text
        text='Saturday' if 'Satarday'==text
        currentDay = text
        #console.log currentDay
      if text.match(/^C\d+$/)
        classesByTimeTable.push({class: parseInt(text.substr(1)), day: currentDay})



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



    tutorsInfo = htmlUtils.tableToData(results.tutors('table table table').eq(0), false)
    classes = []
    for ti in tutorsInfo
      details = ti[0].match(/^(.{2,4})_(.{2,7})_C(\d+)_((?:F|S)\d{2})$/)
      if not details
        log.warning("Could not match tutorInfo details", ti[0], ti)
        #console.log c
      classNumber = parseInt(details[3])
      classes[classNumber]= {
        class: classNumber
        number: classNumber
        percentage: parseInt(ti[2])
        tutor: {
          name: ti[1]
        }
        term: {
          code: ti[3]
        }
        course: {
          program: details[1] || ''
          code: details[2] || ''
        }
      }

    for c in classesByTimeTable
      classes[c.class].time = {
        day: c.day
        hour: c.hour
      }
    classes = classes.filter (c)-> !!c
    cb(null, classes)
}