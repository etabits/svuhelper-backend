"use strict"
debug = require('debug')
log = {
  verbose:debug('svuhelper:verbose')  # blue
  green:  debug('svuhelper:green')  # green
  warning:debug('svuhelper:warning')  # yellow
  info: debug('svuhelper:info')   # darkblue
  purple: debug('svuhelper:purple') # purple
  error:  debug('svuhelper:error')  # red
}
log.error.log = console.error.bind(console)
log.warning.log = console.error.bind(console)
l(a) for a,l of log

mongoose = require('mongoose')
mongoConnectionString = process.env.MONGO_URL || 'mongodb://localhost/svu-helper'
mongoose.connect(mongoConnectionString)

async = require('async')

global.etabits = {
  baseUrl: 'http://www.svuonline.org/isis'
  log: log
  jsonMiddleware: require('body-parser').json()
  models: {}
  data: {
    terms: [
      {"id": 26, "code": "S14" }
      {"id": 27, "code": "F14" }
    ]
    programs: {}
    allCoursesIds: []
  }
  stats: {
    activeUsers: 0
  }
}

etabits.models[m] = require("./models/#{m}") for m in ['Course', 'Program', 'Session', 'Term', 'Tutor', 'User']

reloadStats = ()->
  dateFrom = new Date(Date.now() - 3600000 * 1.5)
  console.log dateFrom
  etabits.models.User.count {lastActivity: {$gt: dateFrom}}, (err, activeUsers)->
    etabits.stats.activeUsers = activeUsers
    etabits.stats.activeUsers = 29
    log.purple "#{activeUsers} in the past 1.5 hours..."
reloadData = ()->
    async.parallel {
        courses:  (done)-> etabits.models.Course.find done
        programs: (done)-> etabits.models.Program.find().populate('courses').exec done

    }, (err, res)->
      for section, docs of res
        log.green "Loaded #{docs.length} #{section}..."
        etabits.data[section] = docs
        tmp = {}
        tmp[row.code] = row for row in docs
        etabits.data[section+'ByCode'] = tmp

        tmp = {}
        tmp[row.id] = row for row in docs
        etabits.data[section+'ById'] = tmp
      etabits.data.allCoursesIds = etabits.data.courses.map (c)-> c._id
      #console.log etabits.data.allCoursesIds
      


reloadData()
reloadStats()
setInterval(reloadStats, 300*1000) # Every 5 minutes
global.etabits.svu = require('./wrapper/')



for collectionName in ['terms', 'programs']
  collectionData = global.etabits.data[collectionName]
  global.etabits.data[collectionName+'ByCode'] = {}
  global.etabits.data[collectionName+'ByCode'][row.code] = row for row in collectionData