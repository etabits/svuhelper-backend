_ = require('lodash')

htmlUtils = require('../htmlUtils')

baseUrl = global.etabits.baseUrl
log = global.etabits.log

Actions = {}
Actions['explore_classes'] = {
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
					classesByTimeTable[i].hour = (new Date((startDate+30*k)*60000)).toGMTString().substr(17, 5);
					break



		tutorsInfo = htmlUtils.tableToData(results.tutors('table table table').eq(0), false)
		classes = []
		for ti in tutorsInfo
			details = ti[0].match(/^(.{2,4})_(.{2,7})_C(\d+)_((?:F|S)\d{2})$/)
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
Actions['progtermcourse'] = {
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
Actions['classes'] = {
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
FourMonths = 4 * 30 * 86400 * 1000
Actions['results'] = {
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
			.select( (e)->('Done'==e.status || 'S14'==e.term.code || ((now-e.date)< FourMonths))  && e.grade!=null )
			.sortBy('date').value().reverse()
		cb(null, data)
}
Actions['exams'] = {
	params: (student, options)->
		{
			url:	"#{baseUrl}/calendar_ex.php?pid=8&rad=1"
			form: {
				act:	'add_tasktype'
				edate:	''
				from_page:	'/isis/calendar_ex.php?pid=8&rad=1'
				pid:	''
				schedule_type:	1
				sdate:	''
				sid:	student.studentId
				term_id:	'26'
				course: [168, 174, 155, 169, 366, 166, 18, 154, 172, 171, 27, 3, 170, 159, 151, 14, 163, 160, 9, 152, 8, 5, 15, 10, 158, 173, 21, 218, 162, 153, 20, 16, 165, 161, 13, 167,
						399,356,236,556,586,232,552,582,508,233,553,583,234,554,584,123,235,555,585]
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

module.exports = Actions