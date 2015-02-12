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

updateBuggers = {
  exams: {
    "course": {
      "code": "UPD999"
    },
    "date": "2015-02-01T23:59:59.999Z",
    "telecenter": {
      "name": "UPGRADE NOW! bit.ly/SVUHelper\n(Or use the link in the login screen)"
    }
  }
  results: {
    "grade": 0,
    "date": "2015-02-01T23:59:59.999Z",
    "status": "Archive",
    "label": "bit.ly/SVUHelper\n(Or use the link in the login screen)",
    "course": {
      "program": "SVU",
      "code": "UPGRADE NOW!"
    },
    "term": {
      "code": "S14"
    }
  }
  classes: {
    "class": 0,
    "number": 0,
    "tutor": {
      "name": "",
      "email": ""
    },
    "term": {
      "code": "S99"
    },
    "course": {
      "program": "SVU",
      "code": "UPD999",
      "name": "UPGRADE NOW! bit.ly/SVUHelper\n(Or use the link in the login screen)\n"
    }
  }
}
studentsRouter.get '/:section(exams|results|classes)', (req, res, next)->
  #console.log req.params
  req.studentObject.get req.params.section, {}, (err, data)->
    return next(err) if err
    debug("Got #{data.length} data array for #{req.studentObject.studentId}/#{req.params.section}")
    #data = data.map(dataFixers[req.params.section])
    #console.log data[0]
    data.unshift updateBuggers[req.params.section] for a in[1..5]
    data.push updateBuggers[req.params.section] for a in[1..5]

    res.json({success: true, data: data})

v0 = etabits.express.Router()
v0.post '/login', etabits.jsonMiddleware, (req, res, next)->
  context = {}
  context.deviceType = 'a'
  context.description = "Android App Old (<=v274)"
  etabits.svu.Student.login req.body.stud_id, req.body.password, context, (err, data)->
    console.error(err) if err
    
    return res.send({success: false, errorMessage: 'Bad Login'}) if err

    data.classes.unshift updateBuggers['classes']
    data.classes.push updateBuggers['classes']
    res.send {
      success: true
      token: data.stud.session.token
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
    newsHTML: "<font color=\"#990000\">ATTENTION!</font><br /><font color=\"#990000\">THIS VERSION WILL STOP FUNCTIONING VERY SOON. UPGRADE NOW!</font><br /><a href=\"http://www.etabits.com/beta/com.etabits.svu.helper.apk?via=app_note_20150212\">Click Here to Download Last Version</a>.<br />The new version shortcut is labeled <font color=\"blue\">SVU Helper</font>, while the old (this) one is labeled <font color=\"blue\">Login</font>.<br /><i>For technical reasons, the new version does not replace this one. Instead, you will have to un-install this one.</i><br /><a href=\"http://www.etabits.com/beta/com.etabits.svu.helper.apk?via=app_note_20150212\">Download Last Version</a>
    <br /><font size=\"50pt\"><a href=\"http://www.etabits.com/beta/com.etabits.svu.helper.apk?via=app_note_20150212\">Download Last Version</a></font>
    "
  }


v0.use '/student', studentsRouter

module.exports = v0