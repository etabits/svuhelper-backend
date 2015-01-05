test:
	./test.sh
preview:
	supervisor -e 'coffee' -i 'node_modules' -x coffee -n error -- server.coffee
