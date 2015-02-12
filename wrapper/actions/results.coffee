_ = require('lodash')

htmlUtils = require('../htmlUtils')

baseUrl = etabits.baseUrl
log = etabits.log

FourMonths = 4 * 30 * 86400 * 1000
module.exports = {
  params: ()-> [
      {url: "#{baseUrl}/ams.php", $name: 'main'}
    ]
  
  handler: (student, results, cb)->
    table = results.main('table[border=1]').eq(0)
    data = htmlUtils.tableToData(table)
    #data = _.chain(data).select( (e)->'Done'==e.Status && e.Action ).sortBy(['Start Time']).value()
    data = data.map (r)->
      if (!r.Assessment)
        log.error('Error at results processing routine: r')
        console.error(r)
        log.error('Error at results processing routine: data')
        console.error(data)
      details = r.Assessment.match(/^(.{2,4})_(.{2,7})_(?:(?:(?:F|S)\d{2})?(?:(?:C|c)\d+_)?)+((?:F|S)\d{2})_(.+)_\d{4}-\d{2}-\d{2}/)
      if not details
        log.warning("Could not match assessment", r.Assessment, r)
        details = {}
      {
        #orig: r
        grade: if r.Action == '' then null else parseFloat(r.Action)
        date: new Date(r['Start Time'].replace(' ', 'T'))
        status: r.Status
        label: htmlUtils.toTitleCase(details[4])
        course: {
          program: details[1]
          code: details[2]
        }
        term: {
          code: details[3]
        }
      }
    #console.log(data)
    now = new Date()
    data = _.chain(data)
      .select( (e)-> ('Done'==e.status || 'S14'==e.term.code || ((now-e.date)< FourMonths))  && ('number' == typeof e.grade) && !isNaN(e.grade))
      .sortBy('date').value().reverse()
    cb(null, data)
}