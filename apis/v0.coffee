_ = require('lodash')
debug = require('debug')('svu:debug')
error = require('debug')('svu:error')
error.log = console.error.bind(console)
fs = require('fs')

studentsRouter = etabits.express.Router()
studentsRouter.use (req, res, next)->
  etabits.svu.Student.restoreFromToken req.query.token, (err, stud)->
    return next(err) if err

    #console.log(stud)
    req.studentObject = stud
    #console.log req.studentObject.doc
    req.studentObject.doc.lastActivity = new Date()
    req.on 'end', ()->
      ++req.studentObject.doc.actionsCounter
      req.studentObject.doc.save()
    next()

dataFixers = {
  courses: (c)->
    {
      name: c.Course

    }
}

studentsRouter.get '/explore/classes', (req, res)->
  opts = {
    pid: parseInt(req.query.pid)
    tid: parseInt(req.query.tid)
    cid: parseInt(req.query.cid)
  }

  req.studentObject.get 'explore_classes', opts, (err, data)->
    return next(err) if err

    debug("Got #{data.length} data array for #{req.studentObject.studentId}/explore_classes")

    res.json({success: true, data: data})

studentsRouter.get '/explore/courses', (req, res)->
  req.studentObject.get 'progtermcourse', {pid: parseInt(req.query.pid)}, (err, data)->
    return next(err) if err

    debug("Got #{data.courses.length} data array for #{req.studentObject.studentId}/courses")

    res.json({success: true, data: data.courses})

studentsRouter.get '/explore/progterm', (req, res)->
  req.studentObject.get 'progtermcourse', {}, (err, data)->
    return next(err) if err

    debug("Got #{data.length} data array for #{req.studentObject.studentId}/#{req.params.section}")
    #data = data.map(dataFixers[req.params.section])
    finalData = []
    for t in data.terms
      #console.log t
      continue if not t.code.match(/1(?:4|5)$/)
      for p in data.programmes
        continue if -1==[8, 7].indexOf(p.id)
        finalData.push {
          program: p
          term: t
        }
    res.json({success: true, data: finalData})


studentsRouter.get '/:section(exams|results|classes)', (req, res, next)->
  #console.log req.params
  req.studentObject.get req.params.section, {}, (err, data)->
    return next(err) if err
    debug("Got #{data.length} data array for #{req.studentObject.studentId}/#{req.params.section}")
    #data = data.map(dataFixers[req.params.section])
    if 'exams' == req.params.section

      data.unshift {
        "course": {
          "code": "UPD999"
        },
        "date": "2015-02-01T23:59:59.999Z",
        "telecenter": {
          "name": "UPGRADE NOW! bit.ly/SVUHelper\n (Or use the link in the login screen)"
        }
      }
    res.json({success: true, data: data})

v0 = etabits.express.Router()
v0.post '/login', etabits.jsonMiddleware, (req, res, next)->
  context = {}
  context.deviceType = 'a'
  context.description = "Android App Old (<=v274)"
  etabits.svu.Student.login req.body.stud_id, req.body.password, context, (err, data)->
    console.error(err) if err
    
    return res.send({success: false, errorMessage: 'Bad Login'}) if err
    res.send {
      success: true
      token: data.doc.sessionToken
      classes: data.classes
    }

cfg = {}
fs.readFile "cfg.json", 'utf-8', (err, data)->
  try 
    cfg = JSON.parse(data)
    #console.log cfg
  catch e
    console.log e
v0.get '/hello', (req, res)->
  message = cfg.messageBase
  
  if parseInt(req.query.versionCode) < cfg.minVersionCode
    message += cfg.messageUpdate
  else
    message += cfg.messageOther
  ###
  message += '<br />
  <font color="red">Important Note:<br />When the SVU website is DOWN (NOT AVAILABLE, has errors, etc.), the application will stop working too (of course).</font>'
  ###
  res.send {
    success: true
    newsHTML: message
  }


v0.use '/student', studentsRouter

module.exports = v0