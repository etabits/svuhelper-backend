_ = require('lodash')
debug = require('debug')('svu:debug')
error = require('debug')('svu:error')
error.log = console.error.bind(console)

htmlUtils = {}

htmlUtils.tableToData = (table, header_row = true, recursive = false)->
	rows = table.find('> tr')
	keys = null
	data = []
	for i in [0..rows.length-1]
		r = rows.eq(i)
		cells = r.find('> td, > th')
		if header_row==false && recursive == true
			for k in [0..cells.length-1]
				cell = cells.eq(k)
				console.log cell, cell.find('table').length

			return 3
		labels = (cells.eq(k).text() for k in [0..cells.length-1])

		if header_row == false
			data.push(labels)
		else if header_row == true
			if 0==i
				keys = labels
			else
				data.push(_.zipObject(keys, labels))
		else
			keys = header_row

			
	debug("Data extraction from table yielded #{data.length} rows")
	data

htmlUtils.selectToData = (select, valKey='value', labelKey='label')->
	select = select.eq(0)
	result = []
	opts = select.find('option')
	#console.log(opts.length)
	#return
	#console.log opts.html()

	for i in [0..opts.length-1]
		opt = opts.eq(i)
		
		r = {}
		r[valKey] = parseInt(opt.attr('value')) || opt.attr('value')
		continue if not r[valKey]
		r[labelKey] = opt.text().trim()

		result.push(r)

	result

module.exports = htmlUtils