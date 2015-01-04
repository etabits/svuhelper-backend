request = require('request')
baseRequest = request.defaults({followRedirect: false})
get = baseRequest
post = baseRequest.defaults({method: 'POST'})
async = require 'async'

debug = require('debug')('svu')

Actions = {}
Actions['exams'] = {
	handler: (student, opts, cb)->


}

Cookie = require './Cookie'

baseUrl = 'https://www.svuonline.org/isis'

class Student
	self = null
	#debug = ()->

	## Instantiation
	constructor: (@opts={}) ->
		self = this
		self.stud_id = @opts.stud_id
		self.studentId = parseInt(self.stud_id.match(/(\d+$)/)[0])
		debug "Instantiated for student ##{self.studentId}"

	login: (site, cb)->

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
			return cb(err) if err
			cookie = httpResponse1.headers['set-cookie'][0].split('; ')[0]
			console.log cookie
			# check if we really were logged in
			
			

	checkCookie: (site, cookie, cb)->
		debug "Checking cookie validity for ##{self.studentId}"
		get {
			url: "#{baseUrl}/index.php"
			headers: {
				'Cookie': cookie
			}
		}, (err, httpResponse, body)->
			cb(null, -1 != body.indexOf('Login IP'))


	getAuthdRequest: (site, cb)->
		debug "Getting AuthdRequest for ##{self.studentId}"

		async.auto {
			# Check if we have one
			cookie_doc: (done)->
				debug "Getting cookie for ##{self.studentId}"
				Cookie.findById self.studentId, (err, doc)->
					return done(null, doc) if doc
					doc = new Cookie({_id: self.studentId})
					doc.save (err, res)->
						done(null, doc)

			cookie_value: ['cookie_doc', (done, results)->
				return done(null, results.cookie_doc[site])
			]

			###
			cookie_valid: ['cookie_value', (done, results)->
				self.checkCookie(site, results.cookie_value, done)
			]
			
			authdRequest: ['cookie_valid', (done, results)->
				if results.cookie_valid
					return get.defaults({
						headers: {
							'Cookie': results.cookie_value
						}
					})
				else
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
						return cb(err) if err
						cookie = httpResponse1.headers['set-cookie'][0].split('; ')[0]
						self.checkCookie site, cookie, done)
						console.log cookie
						# check if we really were logged in

				console.log results
				return


				authenticatedRequest = get.defaults({
					headers: {
						'Cookie': results
					}

				})
			
			]
			###

		}, ()->
			console.log arguments





	get: (action, {}, cb)->
		async.series [
			# get cookie
			(next)->
				self.getAuthdRequest 'main', ()->



		], ()->


module.exports = {
	Student: Student
}