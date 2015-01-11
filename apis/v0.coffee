_ = require('lodash')

studentsRouter = etabits.express.Router()
studentsRouter.use (req, res, next)->
	etabits.svu.Student.restoreFromToken req.query.token, (err, stud)->
		return next(err) if err

		console.log(stud)
		req.studentObject = stud
		next()

dataFixers = {
	courses: (c)->
		{
			name: c.Course

		}
}

studentsRouter.get '/:section(exams|results|classes)', (req, res, next)->
	console.log req.params
	req.studentObject.get req.params.section, {}, (err, data)->
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
	res.send {
		success: true
		newsHTML: message
	}


v0.use '/student', studentsRouter

module.exports = v0