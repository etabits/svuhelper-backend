test:
	./test.sh login
	./test.sh exams
	./test.sh results
preview:
	supervisor -e 'coffee' -i 'node_modules' -x coffee -n error -- server.coffee
