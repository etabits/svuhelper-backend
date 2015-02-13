test:
	./test.sh login
	./test.sh getLogin
	./test.sh exams
	./test.sh results
	./test.sh classes
	./test.sh explore/S14/BIT
	./test.sh explore/S14/BIT/170
	./test.sh select/BMC 69575
	./test.sh select/BMC/569 69575
preview:
	DEBUG=svuhelper:*,express:* supervisor -e 'coffee,json' -i 'node_modules' -x coffee -n error -- server.coffee
