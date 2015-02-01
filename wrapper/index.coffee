request = require('request')
moodleRequest = request.defaults({json: true})
baseRequest = request.defaults({followRedirect: false, encoding: null})
get = baseRequest
post = baseRequest.defaults({method: 'POST'})
async = require 'async'
encoding = require("encoding")
cheerio = require('cheerio')
crypto = require('crypto')

htmlUtils = require('./htmlUtils')
debug = require('debug')('svu:debug')
error = require('debug')('svu:error')
error.log = console.error.bind(console)


_ = require('lodash')


site = 'mainCookie'
User = require '../models/User'

baseUrl = 'https://www.svuonline.org/isis'
#baseUrl = 'https://www.svuonline.org1/isis'


toTitleCase = (str)-> if str then str.replace(/_/g, ' ').replace /(?:^|_)[a-z]/g, (m) -> m.replace(/^_/, ' ').toUpperCase() else ''
Actions = {}
###
###
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
				error("Could not match class", c.Class, c)
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
			details = r.Assessment.match(/^(.{2,4})_(.{2,7})_(?:(?:(?:F|S)\d{2})?(?:(?:C|c)\d+_)?)+((?:F|S)\d{2})_(.+)_\d{4}-\d{2}-\d{2}/)
			if not details
				error("Could not match assessment", r.Assessment, r)
				details = {}
			{
				#orig: r
				grade: if r.Action == '' then null else parseFloat(r.Action)
				date: new Date(r['Start Time'].replace(' ', 'T'))
				status: r.Status
				label: toTitleCase(details[4])
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

class Student
	self = null
	@restoreFromToken: (token, done)->
		User.findOne {sessionToken: token}, (err, doc)->
			return done(err) if err
			return done({error: 'INVALID'}) unless doc
			stud = new Student({
					stud_id: doc.stud_id
					password: doc.password
				})
			stud.doc = doc
			done(null, stud)


	#debug = ()->

	@login: (stud_id, password, done)->
		stud = new Student({stud_id: stud_id, password: password})
		stud.getOrCreateDbObject (err, doc)->
			return done(err) if err

			async.parallel {
				token: (done)-> crypto.randomBytes 18, done
				classes: (done)->
					stud.retrieveNewCookie site, (err, cookie)->
						debug("getting new cookie for #{stud_id}:#{password} yielded #{cookie}")
						return done(err) if err
						action = Actions.classes
						stud.performRequestWithCookie action.params(), cookie, (err, httpResponse, body)->
							debug("cookied request failed") if err
							return done(err) if err
							doc.mainCookie = cookie
							self.getSelector body, (err, $)->
								action.handler stud, {classes: $}, done
				moodle: (done)->
					moodleRequest "https://moodle.svuonline.org/login/token.php?username=#{stud_id}&password=#{password}&service=moodle_mobile_app", (err, resp, json)->
						done(err, json)

			}, (err, results)->
				return done(err) if err
				#console.log(doc)
				doc.sessionToken = results.token.toString('base64')

				doc.stud_id = stud_id
				doc.password = password
				doc.moodleToken = results.moodle.token
				doc.save (err)->
					done(err, {classes: results.classes, doc: doc, stud: stud})
				





	## Instantiation
	constructor: (@opts={}) ->
		#console.log @opts
		self = this
		self.stud_id = @opts.stud_id

		self.studentId = parseInt(self.stud_id.match(/(\d+$)/)[0])
		debug "Instantiated for student ##{self.studentId}"

	isResponseAuthd: (httpResponse, body)->
		#-1 != body.toString().indexOf('Login IP')
		-1 == body.toString().indexOf('<img src="images/icon/group_ge.gif" align="left" />Login')


	getOrCreateDbObject: (done)->
		return done(null, self.doc) if self.doc
		debug "Getting db object for ##{self.studentId}"
		User.findById self.studentId, (err, doc)->
			self.doc = doc
			return done(null, self.doc) if doc
			self.doc = new User({_id: self.studentId})
			self.doc.save (err, res)->
				done(null, self.doc)

	retrieveNewCookie: (site, done)->
		debug "Retrieving New Cookie for ##{self.studentId}"
		data = {
			from_page:	'/isis/index.php'
			user_name:	self.stud_id
			user_otp:	''
			user_pass:	self.opts.password
		}
		post {
			url: "#{baseUrl}/login.php"
			form: data
			followRedirect: false

		}, (err, httpResponse1, body)->
			return done(err) if err
			cookie = httpResponse1.headers['set-cookie'][0].split('; ')[0]
			return done(null, cookie)
			#self.checkCookie(site, cookie, done)

	performRequestWithCookie: (params, cookie, done)->
		params.headers = {Cookie: cookie}
		debug "Performing request on behalf of ##{self.studentId}", params.url
		#console.log params
		baseRequest params, (err, httpResponse, body)->
			if err
				return done(err)
			else if not self.isResponseAuthd(httpResponse, body)
				#console.log body.toString()
				return done({code: 'BADLOGIN'})
			else
				return done(null, httpResponse, body)


	performRequest: (params, done)->
		trial = (done, results)->
			self.getOrCreateDbObject (err, cookie)->
				self.performRequestWithCookie params, cookie[site], (err, httpResponse, body)->
					if err # Try doing login again
						self.retrieveNewCookie site, (err2, cookie)->
							updatedDoc = {}
							self.doc[site]=cookie
							self.doc.save (err, doc)->
								done(err || {code: 'BADLOGIN'})
					else
						debug "Request succeeded for ##{self.studentId}"
						done(null, {resp: httpResponse, body: body})

		async.retry 2, trial, (err, results)->
			
			debug "Bad Login for ##{self.studentId}" if err

			return done(err, results)
			#console.log results.resp.headers


	getLoginRetObject: (done)->
		retObj = {
			success: true
			token: self.doc.sessionToken
			student: {
				id: self.studentId
				username: self.stud_id
			}
			terms: global.etabits.data.terms
			programs: global.etabits.data.programs
			htmlHomeTop: ""
			htmlHomeBottom: ""
		}
		done(null, retObj)

	getSelector: (body, cb)->
		body = encoding.convert(body, 'utf8', 'WINDOWS-1256').toString()
		start = body.indexOf('<img src="images/webdev_arena.gif" />')
		end = body.indexOf('<iframe width=199 height=178 name="gToday:normal:agenda.js" id="gToday:normal:agenda.js"')
		compactBody = if -1!=start and -1!=end then body.substring(start, end) else ''

		if !compactBody || !compactBody.length
			compactBody = body

		compactBody = compactBody.replace(/\s+/g, ' ');

		$ = cheerio.load(compactBody)
		debug "Cheerio complete ##{self.studentId}"

		#console.log rootElement.length, rootElement.find('tr').length
		cb(null, $)


	performAnyRequest: (requestParameters, done)->
		name = requestParameters.$name
		delete requestParameters.$name
		if requestParameters.url
			self.performRequest requestParameters, (err, res)->
				return done(err) if err
				self.getSelector res.body, (err, $)->
					return done(err, {
						$: $
						name: name
					})
		else
			done(500)


	get: (actionId, options, cb)->
		debug "Getting #{actionId} for ##{self.studentId}"
		action = Actions[actionId]
		requestParameters = action.params(self, options)
		if not Array.isArray(requestParameters)
			requestParameters.$name = actionId
			requestParameters = [requestParameters]

		async.map requestParameters, self.performAnyRequest, (err, results)->
			if err
				console.log '>>>',err
				return cb(err)
			resObj = {}
			resObj[i.name] = i.$ || i.json for i in results
			
			action.handler(self, resObj, cb)





module.exports = {
	Student: Student
}