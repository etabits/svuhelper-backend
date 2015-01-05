request = require('request')
baseRequest = request.defaults({followRedirect: false, encoding: null})
get = baseRequest
post = baseRequest.defaults({method: 'POST'})
async = require 'async'
encoding = require("encoding")
cheerio = require('cheerio')
crypto = require('crypto')

debug = require('debug')('svu')
htmlUtils = require('./htmlUtils')

_ = require('lodash')

Actions = {}
Actions['classes'] = {
	url: ()-> "#{baseUrl}/std_classes.php"
	params: ()-> {}
	
	handler: (student, $, params, cb)->
		table = $('table table table').eq(0)
		data = htmlUtils.tableToData(table)
		cb(null, data)
}
Actions['results'] = {
	url: ()-> "#{baseUrl}/ams.php"
	params: ()-> {}
	
	handler: (student, $, params, cb)->
		table = $('table[border=1]').eq(0)
		data = htmlUtils.tableToData(table)
		data = _.chain(data).select( (e)->'Done'==e.Status && e.Action ).sortBy(['Start Time']).value()
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
				pid:	8
				schedule_type:	1
				sdate:	''
				sid:	student.studentId
				term_id:	'26'
				course: [168, 174, 155, 169, 366, 166, 18, 154, 172, 171, 27, 3, 170, 159, 151, 14, 163, 160, 9, 152, 8, 5, 15, 10, 158, 173, 21, 218, 162, 153, 20, 16, 165, 161, 13, 167]
			}
			method: 'POST'
		}
	handler: (student, $, params, cb)->
		table = $('#tt4').eq(0)
		data = _.chain(htmlUtils.tableToData(table)).reject( (e)-> !e.Start ).sortBy(['Date', 'Start']).value()
		cb(null, data)
}
site = 'mainCookie'
User = require './User'

baseUrl = 'https://www.svuonline.org/isis'

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
		stud.retrieveNewCookie site, (err, cookie)->
			return done(err) if err
			action = Actions.classes
			stud.performRequestWithCookie stud.getRequestParamsFromAction(action), cookie, (err, httpResponse, body)->
				return done(err) if err
				self.applyActionToBody action, body, {}, (err, data)->
					#console.log stud, cookie, httpResponse.headers, data
					stud.getOrCreateDbObject (err, doc)->
						doc.mainCookie = cookie
						doc.stud_id = stud_id
						doc.password = password
						crypto.randomBytes 18, (err, token)->
							doc.sessionToken = token.toString('base64')
							doc.save (err, doc)->
								return done null, {
									classes: data
									doc: doc
								}





	## Instantiation
	constructor: (@opts={}) ->
		console.log @opts
		self = this
		self.stud_id = @opts.stud_id

		self.studentId = parseInt(self.stud_id.match(/(\d+$)/)[0])
		debug "Instantiated for student ##{self.studentId}"

	isResponseAuthd: (httpResponse, body)-> -1 != body.toString().indexOf('Login IP')


	getOrCreateDbObject: (done)->
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
		baseRequest params, (err, httpResponse, body)->
			if err
				return done(err)
			else if not self.isResponseAuthd(httpResponse, body)
				return done({error: 'UNAUTH'})
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
								done(err || true)
					else
						debug "Request succeeded for ##{self.studentId}"
						done(null, {resp: httpResponse, body: body})

		async.retry 2, trial, (err, results)->
			
			debug "Bad Login for ##{self.studentId}" if err

			return done(err, results)
			#console.log results.resp.headers



	applyActionToBody: (action, body, options, cb)->
		body = encoding.convert(body, 'utf8', 'WINDOWS-1256').toString()
		start = body.indexOf('<img src="images/webdev_arena.gif" />')
		end = body.indexOf('<iframe width=199 height=178 name="gToday:normal:agenda.js" id="gToday:normal:agenda.js"')
		compactBody = if -1!=start and -1!=end then body.substring(start, end) else ''

		if !compactBody || !compactBody.length
			compactBody = body

		$ = cheerio.load(compactBody)
		debug "Cheerio complete ##{self.studentId}"

		#console.log rootElement.length, rootElement.find('tr').length
		action.handler self, $, options, cb

	getRequestParamsFromAction: (action, options={})->
		requestParameters = if action.params then action.params(self, options) else {}
		requestParameters.url = action.url(self, options) if action.url

		requestParameters

	get: (actionId, options, cb)->
		debug "Getting #{actionId} for ##{self.studentId}"
		action = Actions[actionId]
		requestParameters = self.getRequestParamsFromAction(action, options)

		self.performRequest requestParameters, (err, results)->
			return cb(err) if err
			self.applyActionToBody(action, results.body, options, cb)





module.exports = {
	Student: Student
}