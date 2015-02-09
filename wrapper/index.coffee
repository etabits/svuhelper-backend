request = require('request')
moodleRequest = request.defaults({json: true})
baseRequest = request.defaults({followRedirect: false, encoding: null})
get = baseRequest
post = baseRequest.defaults({method: 'POST'})
async = require 'async'
encoding = require("encoding")
cheerio = require('cheerio')
crypto = require('crypto')
_ = require('lodash')
fs = require('fs')



site = 'mainCookie'
User = require '../models/User'
Session = require '../models/Session'

baseUrl = global.etabits.baseUrl
#baseUrl = 'https://www.svuonline.org1/isis'


###
###

Actions = require('./actions/')
log = global.etabits.log


class Student
	self = null
	@restoreFromDocument: (doc, done)->
		stud = new Student({
			stud_id: doc.stud_id
			password: doc.password
		})
		stud.doc = doc
		done(null, stud)

	@restoreFromToken: (token, done)->
		Session.findOne {token: token}, (err, session)->
			return done(err) if err
			return done({code: 'INVALID_TOKEN'}) unless session
			User.findOne {_id: session.student}, (err, doc)->
				return done(err) if err
				return done({code: 'INVALID_TOKEN'}) unless doc
				stud = new Student({
						stud_id: doc.stud_id
						password: doc.password
					})
				stud.session = session
				stud.doc = doc
				done(null, stud)



	@login: (stud_id, password, context, done)->
		stud = new Student({stud_id: stud_id, password: password})
		stud.getOrCreateDbObject (err, doc)->
			return done(err) if err

			async.parallel {
				token: (done)-> crypto.randomBytes 18, done
				classes: (done)->
					stud.retrieveNewCookie site, (err, cookie)->
						log.info("getting new cookie for #{stud_id}:#{password} yielded #{cookie}")
						return done(err) if err
						action = Actions.classes
						stud.performRequestWithCookie action.params(), cookie, (err, httpResponse, body)->
							log.info("cookied request failed") if err
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
				session = new Session({
						token: results.token.toString('base64')
						student: stud.studentId
						deviceType: context.deviceType || 'a'
						description: context.description || ''
					})
				session.save ()->

					#doc.activeSession = session

					doc.stud_id = stud_id
					doc.password = password
					doc.moodleToken = results.moodle.token
					doc.save (err)->
						stud.session = session
						done(err, {classes: results.classes, doc: doc, stud: stud})
				





	## Instantiation
	constructor: (@opts={}) ->
		#console.log @opts
		self = this
		self.stud_id = @opts.stud_id

		self.studentId = parseInt(self.stud_id.match(/(\d+$)/)[0])
		log.info("Instantiated for student ##{self.studentId}")

	isResponseAuthd: (httpResponse, body)->
		body = body.toString()

		self.doc.passwordExpired = -1 != body.indexOf('change_pass.php?type=expiredPass')
		log.purple("Password for ##{self.studentId} has expired!") if self.doc.passwordExpired

		if 0 == body.indexOf('<!DOCTYPE HTML') # Full document
			# We want the Login IP mentioned here
			return -1 != body.indexOf('Login IP')
		else
			# We do not want this image present!
			return -1 == body.indexOf('<img src="images/icon/group_ge.gif" align="left" />Login')


	getOrCreateDbObject: (done)->
		return done(null, self.doc) if self.doc
		log.info("Getting db object for ##{self.studentId}")
		User.findById self.studentId, (err, doc)->
			self.doc = doc
			return done(null, self.doc) if doc
			self.doc = new User({_id: self.studentId})
			self.doc.save (err, res)->
				done(null, self.doc)

	retrieveNewCookie: (site, done)->
		log.info("Retrieving New Cookie for ##{self.studentId}")
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
		#self ?= this
		#console.log(this, self)
		params.headers = {Cookie: cookie}
		log.info("Performing request on behalf of ##{self.studentId}", params.url)
		#console.log params
		baseRequest params, (err, httpResponse, body)->
			if err
				return done(err)
			else if not self.isResponseAuthd(httpResponse, body)
				#console.log body.toString()
				return done({code: 'BADLOGIN'})
			else # Everything is fine, do the callback
				###
				async.parallel [
					(done)-> # If password is expired, save the doc first...
						return done(null) if not self.doc.passwordExpired
						self.doc.save ()-> done(null)
				], ()-> # now we return!
				###
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
						log.info("Request succeeded for ##{self.studentId}")
						done(null, {resp: httpResponse, body: body})

		async.retry 2, trial, (err, results)->
			
			log.info("Bad Login for ##{self.studentId}") if err

			return done(err, results)
			#console.log results.resp.headers


	getLoginRetObject: (done)->
		#self.doc.populate 'activeSession', ()->
		retObj = {
			success: true
			token: self.session.token
			student: {
				id: self.studentId
				username: self.stud_id
			}
			terms: global.etabits.data.terms
			programs: _.select(etabits.data.programs, {expose: true})
			htmlHomeTop: ''
			htmlHomeBottom: ''
		}
		retObj.htmlHomeTop = 'Got any question? Send us a message to <a href="http://www.facebook.com/SVUHelper">our Facebook page</a>. Your feedback is highly appreciated!'
		if self.doc.actionsCounter > 10
			retObj.htmlHomeBottom = '<a href="http://www.facebook.com/SVUHelper">fb.com/SVUHelper</a>: App Facebook page'
		if self.doc.passwordExpired
			retObj.htmlHomeTop = '<font color=\"#990000\">PASSWORD EXPIRED!</font><br /><p>Please <a href="https://svuonline.org/isis/">login to your account at svuonline.org</a> and change it NOW!</p>'
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
		log.verbose("Cheerio complete ##{self.studentId}")

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
						body: res.body
					})
		else
			done(500)


	get: (actionId, options, cb)->
		log.info("Getting #{actionId} for ##{self.studentId}")
		action = Actions[actionId]
		requestParameters = action.params(self, options)
		if not Array.isArray(requestParameters)
			requestParameters.$name = actionId
			requestParameters = [requestParameters]

		#console.log requestParameters
		async.map requestParameters, self.performAnyRequest, (err, results)->
			if err
				console.log '>>>',err
				return cb(err)
			resObj = {}
			resObj[i.name] = i.$ || i.json for i in results

			try
				action.handler(self, resObj, cb)
			catch e
				log.error(e)
				for r in results
					fs.writeFile("/tmp/svuhelper-err-#{Date.now()}-#{r.name}", r.body)





module.exports = {
	Student: Student
}