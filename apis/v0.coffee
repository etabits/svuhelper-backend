_ = require('lodash')
debug = require('debug')('svu:debug')
error = require('debug')('svu:error')
error.log = console.error.bind(console)


studentsRouter = etabits.express.Router()
studentsRouter.use (req, res, next)->
	etabits.svu.Student.restoreFromToken req.query.token, (err, stud)->
		return next(err) if err

		#console.log(stud)
		req.studentObject = stud
		#console.log req.studentObject.doc
		req.studentObject.doc.lastActivity = new Date()
		req.on 'end', ()->
			req.studentObject.doc.save()
		next()

dataFixers = {
	courses: (c)->
		{
			name: c.Course

		}
}

studentsRouter.get '/:section(exams|results|classes)', (req, res, next)->
	#console.log req.params
	req.studentObject.get req.params.section, {}, (err, data)->
		return next(err) if err
		debug("Got #{data.length} data array for #{req.studentObject.studentId}/#{req.params.section}")
		#data = data.map(dataFixers[req.params.section])
		res.json({success: true, data: data})

v0 = etabits.express.Router()
v0.post '/login', etabits.jsonMiddleware, (req, res, next)->
	etabits.svu.Student.login req.body.stud_id, req.body.password, (err, data)->
		console.error(err) if err
		
		return res.send({success: false, errorMessage: 'Bad Login'}) if err
		res.send {
			success: true
			token: data.doc.sessionToken
			classes: data.classes
		}

v0.get '/hello', (req, res)->
	message = 'Welcome to SVU Student\'s Helper<br />Use the form below to login.'
	minVersionCode = 149
	if parseInt(req.query.versionCode) < minVersionCode
		message = '<font color="red">New Version Available!</font> <a href="http://www.etabits.com/beta/com.etabits.svu.helper.apk?vc='+minVersionCode+'">Click here</a> to download.<br >
		App functions will probably <u>NOT</u> work without updating.'
	message += '<br />
	<font color="red">Important Node:<br />When the SVU website is DOWN (NOT AVAILABLE, has errors, etc.), the application will stop working too (of course).</font>'
	res.send {
		success: true
		newsHTML: message
	}


v0.use '/student', studentsRouter

module.exports = v0