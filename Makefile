test:
	./test.sh login
	./test.sh exams
	./test.sh results
	./test.sh classes
preview:
	supervisor -e 'coffee' -i 'node_modules' -x coffee -n error -- server.coffee
