#!/bin/bash
id=$2

if [ "$id" == "" ]; then
	id=29643
fi
#echo $id; exit 0
password=$(mongo 'svu-helper' --quiet --eval 'db.users.findOne({_id:29643}).password')
token=$(mongo 'svu-helper' --quiet --eval "db.users.findOne({_id:$id}).sessionToken")
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

login() {
	stderr "logging in as $1:***"
	$curl -H "Content-Type: application/json" \
	-d "{\"stud_id\":\"$1\",\"password\":\"$2\"}" \
	$baseURI/login | jq '.'

}

stderr Doing $action
if [ "loginAs" == "$action" ]; then
	login "$2" "$3"
elif [ "login" == "$action" ]; then
	login "hasan_29643" $password
elif [ "results" == "$action" ]; then
	request "student/results"
elif [ "exams" == "$action" ]; then
	request "student/exams"
elif [ "classes" == "$action" ]; then
	request "student/classes"
else
	echo Trying to call $action...
	request "student/$action"
fi
exit 0;
