PUSHBULLET_API_URL="https://api.pushbullet.com/v2/"
PUSHBULLET=""

function pushbullet-init() {
	if [ $# -eq 1 ]; then
		PUSHBULLET_USER_TOKEN="$1"
	elif [ $# -eq 2 ]; then
		PUSHBULLET_USER_TOKEN="$1"
		PUSHBULLET_API_URL="$2"
	else
		exit 1
	fi

	PUSHBULLET="curl --verbose --header Access-Token:$PUSHBULLET_USER_TOKEN"
}

function _pushbullet-send-get() {
	local URL="${PUSHBULLET_API_URL}${1}"
	${PUSHBULLET} --url "$URL"
}

function _pushbullet-send-post() {
	local URL="${PUSHBULLET_API_URL}${1}"
	local DATA="$2"
	${PUSHBULLET} --url "$URL" --request POST --header 'Content-Type: application/json' --data-binary "$DATA"
}

function pushbullet-send-push() {
	local TITLE=$1
	local BODY=$2

	local DATA=$(printf '{"title":"%s", "body":"%s", "type":"note"}' "$TITLE" "$BODY")
	_pushbullet-send-post "pushes" "$DATA"
}
