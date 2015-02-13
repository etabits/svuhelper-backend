"use strict"
_ = require('lodash')
fs = require('fs')
async = require 'async'

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
		req.svu = {}
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

daysOfWeek = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
sortTimedClass = (a, b)->
	"#{daysOfWeek.indexOf(a.time.day)}#{a.time.hour}".localeCompare("#{daysOfWeek.indexOf(b.time.day)}#{b.time.hour}")

studentsRouter.param 'program', (req, res, next)->
	req.svu.program = data.programsByCode[req.params.program]
	next()

studentsRouter.param 'term', (req, res, next)->
	req.svu.term = data.termsByCode[req.params.term]
	next()

studentsRouter.get '/select/:program', (req, res, next)->
	req.studentObject.get 'get_selectable_classes', {pid: req.svu.program.id}, (err, data)->
		return next(err) if err
		res.json({success: true, data: data})

studentsRouter.get '/select/:program/:courseId', (req, res, next)->

	opts= {
		pid: req.svu.program.id,
		cid: parseInt(req.params.courseId)
		tid: 27 #FIXME!
	}
	async.parallel {
		available: (done)->
			req.studentObject.get 'get_selectable_classes2', opts, done
		tutorTime: (done)->
			req.studentObject.get 'explore_classes', opts, done

	}, (err, results)->
		available = _.indexBy(results.available, 'number')
		for tt in results.tutorTime
			_.assign(tt, available[tt.number] || {chosen: false, totalCapacity: 100, totalEnrolled: 100})
		res.json {
			success: true
			data: results.tutorTime.sort(sortTimedClass)
			messages: [
				{
					type: 'info'
					text: 'Classes are now sorted by date (Sunday through Saturday), not by class number.'
				}
			]
		}

studentsRouter.post '/select/:program/:courseId', etabits.jsonMiddleware, (req, res, next)->
	opts= {
		pid: parseInt(req.svu.program.id),
		cid: parseInt(req.params.courseId)
		tid: 27 #FIXME!
		classId: parseInt(req.body.class)
	}
	req.studentObject.get 'choose_class', opts, (err, data)-> res.json({success: true})


studentsRouter.get '/explore/:term/:program', (req, res, next)->
	#console.log data.programsByCode[req.params.program].id
	req.studentObject.get 'progtermcourse', {pid: req.svu.program.id}, (err, data)->
		return next(err) if err

		log.info("Got #{data.courses.length} data array for #{req.studentObject.studentId}"+req.url.split('?')[0])

		res.json({success: true, data: data.courses})

studentsRouter.get '/explore/:term/:program/:courseId', (req, res, next)->

	opts = {
		pid: req.svu.program.id
		tid: req.svu.term.id
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

v0.get '/web', loadStudentFromToken, (req, res, next)->
	res.send {
		success: true
		student: {
			stud_id: req.studentObject.doc.stud_id
			passwordExpired: req.studentObject.doc.passwordExpired
		}
		stats: {
			activeUsers: etabits.stats.activeUsers
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