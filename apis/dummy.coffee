_ = require('lodash')
fs = require('fs')

dummyData = {
  exams: [
    {
      "course": {
        "code": "MGT325"
      },
      "date": "2015-02-05T09:30:00.000Z",
      "telecenter": {
        "name": "Damascus-Mazzeh/ Damascus"
      }
    }
  ]
  results: [
    {
      "grade": 88,
      "date": "2015-02-03T11:00:00.000Z",
      "status": "Archive",
      "label": "Final",
      "course": {
        "program": "BIT",
        "code": "MGT250"
      },
      "term": {
        "code": "S14"
      }
    }
    {
      "grade": 0,
      "date": "2015-02-03T11:00:00.000Z",
      "status": "Archive",
      "label": "Final",
      "course": {
        "program": "BIT",
        "code": "MGT250"
      },
      "term": {
        "code": "S14"
      }
    }
  ]

}

studentsRouter = etabits.express.Router()
studentsRouter.get '/:section(exams|results|classes)', (req, res)->
  res.send {
    success: true
    data: dummyData[req.params.section]
  }



dummy = etabits.express.Router()

dummy.get '/web', (req, res)->
  res.send {
    success: true
    student: {
      stud_id: 'hasan_29643'
    }
  }

dummy.use '/student', studentsRouter

module.exports = dummy