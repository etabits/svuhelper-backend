test:
	./test.sh login
	./test.sh getLogin
	./test.sh exams
	./test.sh results
	./test.sh classes
	./test.sh explore/S14/BIT
	./test.sh explore/S14/BIT/170
preview:
	DEBUG=svuhelper:* supervisor -e 'coffee,json' -i 'node_modules' -x coffee -n error -- server.coffee
