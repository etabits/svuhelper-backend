#!/bin/bash
password=$(mongo 'svu-helper' --quiet --eval 'db.users.findOne({_id:29643}).password')
token=$(mongo 'svu-helper' --quiet --eval 'db.users.findOne({_id:29643}).sessionToken')
baseURI='http://127.0.0.1:5757/v0'
curl='curl --silent'
action=$1

stderr() {
	echo $@ > /dev/stderr
}
request() {
	stderr $curl -G "$baseURI/$1" --data-urlencode "token=$token"
	$curl -G "$baseURI/$1" --data-urlencode "token=$token" | jq '.'
}

stderr Doing $action
if [ "login" == "$action" ]; then
	$curl -H "Content-Type: application/json" \
	-d "{\"stud_id\":\"hasan_29643\",\"password\":\"$password\"}" \
	$baseURI/login | jq '.'
elif [ "results" == "$action" ]; then
	request "student/results"
elif [ "exams" == "$action" ]; then
	request "student/exams"
elif [ "classes" == "$action" ]; then
	request "student/classes"
else
	stderr No such action
	exit 1
fi
exit 0;
