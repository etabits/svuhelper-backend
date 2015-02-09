#!/usr/bin/env coffee
require('../boot')
async = require('async')

m = etabits.models
log = etabits.log


stud = null
removeId = (d)->
  delete d.id
  delete d._id
  return d
programInserter = (p, done)->
  stud.get 'progtermcourse', {pid: parseInt(p.id)}, (err, data)->
    if data.programmes[0].id != p.id
      log.error('NO MATCHE!')
      return done(true)
    p.name = data.programmes[0].code
    p.courses = data.courses.map (c)-> c.id
    #pDoc = new m.Program(p)

    async.parallel {
      insertProgram: (done)-> m.Program.update {_id: p.id}, p, {upsert: true}, done
      insertCourses: (done)->
        log.purple "Inserting #{data.courses.length} courses for program #{p.code}:#{p.name}"
        async.map data.courses, ( (c, done)-> m.Course.update({_id: c.id}, removeId(c), {upsert: true}, done) ), done

    }, done

m.User.findOne {_id: 29643}, (err, doc)->
  etabits.svu.Student.restoreFromDocument doc, (err, s)->
    stud = s
    stud.get 'progtermcourse', {}, (err, data)->
      programmes = data.programmes
      #programmes = data.programmes.slice(0, 1)

      async.parallel {
          ps: (done)-> async.map programmes, programInserter, done
          ts: (done)->
            #console.log data.terms
            done(null)
        },  (err)->
        console.log arguments
        process.exit(0)

      
