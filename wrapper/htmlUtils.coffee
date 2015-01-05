_ = require('lodash')
htmlUtils = {}

htmlUtils.tableToData = (table)->
	rows = table.find('tr')
	keys = null
	data = []
	for i in [0..rows.length-1]
		r = rows.eq(i)
		cells = r.find('> td, > th')
		labels = (cells.eq(k).text() for k in [0..cells.length-1])

		if 0==i
			keys = labels
		else
			#console.log labels
			data.push(_.zipObject(keys, labels))
	data



module.exports = htmlUtils