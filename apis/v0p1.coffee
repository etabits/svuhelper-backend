_ = require('lodash')
fs = require('fs')

loadStudentFromToken = (req, res, next)->
	etabits.svu.Student.restoreFromToken req.query.token, (err, stud)->
		return next(err) if err

		#console.log(stud)
		req.studentObject = stud
		#console.log req.studentObject.doc
		req.studentObject.doc.lastActivity = req.studentObject.session.lastActivity = new Date()
		req.on 'end', ()->
			req.studentObject.session.save()
			
			++req.studentObject.doc.actionsCounter
			req.studentObject.doc.save()
		next()
		
studentsRouter = etabits.express.Router()
studentsRouter.use loadStudentFromToken

dataFixers = {
	courses: (c)->
		{
			name: c.Course

		}
}
data = global.etabits.data
log = global.etabits.log

studentsRouter.get '/explore/:term/:program', (req, res)->
	#console.log data.programsByCode[req.params.program].id
	req.studentObject.get 'progtermcourse', {pid: data.programsByCode[req.params.program].id}, (err, data)->
		return next(err) if err

		log.info("Got #{data.courses.length} data array for #{req.studentObject.studentId}"+req.url.split('?')[0])

		res.json({success: true, data: data.courses})

studentsRouter.get '/explore/:term/:program/:courseId', (req, res)->

	opts = {
		pid: data.programsByCode[req.params.program].id
		tid: data.termsByCode[req.params.term].id
		cid: parseInt(req.params.courseId)
	}
	#console.log opts

	req.studentObject.get 'explore_classes', opts, (err, data)->
		return next(err) if err

		log.info("Got #{data.length} data array for #{req.studentObject.studentId}"+req.url.split('?')[0])

		res.json({success: true, data: data})


studentsRouter.get '/:section(exams|results|classes)', (req, res, next)->
	#console.log req.params
	req.studentObject.get req.params.section, {}, (err, data)->
		return next(err) if err
		log.info("Got #{data.length} data array for #{req.studentObject.studentId}/#{req.params.section}")
		#data = data.map(dataFixers[req.params.section])
		res.json({success: true, data: data})

v0 = etabits.express.Router()
v0.post '/login', etabits.jsonMiddleware, (req, res, next)->
	context = {}
	context.deviceType = if 'web'==req.body.app then 'w' else 'a'
	context.description = if 'w' == context.deviceType then 'Web' else "Android App v#{req.query.versionCode}"
	etabits.svu.Student.login req.body.stud_id, req.body.password, context, (err, result)->
		return next(err) if err
		
		result.stud.getLoginRetObject (err, loginResult)->
			res.send(loginResult)

v0.get '/web', loadStudentFromToken, (req, res)->
	res.send {
		success: true
		student: {
			stud_id: req.studentObject.doc.stud_id
			passwordExpired: req.studentObject.doc.passwordExpired
		}
	}

v0.get '/login', loadStudentFromToken, (req, res, next)->
	log.info("Resuming #{req.studentObject.studentId} session...")
	req.studentObject.getLoginRetObject (err, loginResult)->
		res.send(loginResult)


cfg = {}
fs.readFile "cfg.json", 'utf-8', (err, data)->
	try 
		cfg = JSON.parse(data)
		console.log cfg
	catch e
		console.log e
v0.get '/hello', (req, res)->
	message = cfg.messageBase
	
	if parseInt(req.query.versionCode) < cfg.minVersionCode
		message += cfg.messageUpdate
	else
		message += cfg.messageOther

	res.send {
		success: true
		newsHTML: message
		lastVersion: cfg.minVersionCode
	}


v0.use '/student', studentsRouter

module.exports = v0