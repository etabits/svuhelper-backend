_ = require('lodash')
debug = require('debug')('svu:debug')
error = require('debug')('svu:error')
error.log = console.error.bind(console)

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
	debug("Data extraction from table yielded #{data.length} rows")
	data



module.exports = htmlUtils