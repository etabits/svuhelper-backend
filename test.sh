#!/bin/bash
password=$(mongo 'svu-helper' --quiet --eval 'db.users.findOne({_id:29643}).password')
token=$(mongo 'svu-helper' --quiet --eval 'db.users.findOne({_id:29643}).sessionToken')
baseURI='http://127.0.0.1:5757/v0'
curl='curl --silent'

stderr() {
	echo $@ > /dev/stderr
}
request() {
	stderr $curl -G "$baseURI/$1" --data-urlencode "token=$token"
	$curl -G "$baseURI/$1" --data-urlencode "token=$token"
}
request "student/results" | jq '.data'; exit 0;
token=$($curl -H "Content-Type: application/json" \
	-d "{\"stud_id\":\"hasan_29643\",\"password\":\"$password\"}" \
	$baseURI/login | jq -r '.token')

echo $token

echo Exams
request "student/exams"
