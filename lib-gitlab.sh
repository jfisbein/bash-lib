GITLAB_API_URL=""
GITLAB_USER_TOKEN=""

CURL="/usr/bin/curl --silent --insecure --header 'Accept: application/json' --header 'Content-type: application/json'"

# Init Gitlab library, use it to set user token
# 2 options:
# Option 1 by user token:
#   param 1: Gitlab User Token
#   param 2: Gitlab api url, optional, defaults to "https://gitlab.fon.ofi/api/v3"
#
# Option 2 by username and password:
#   param 1: username
#   param 2: password
#   param 3: Gitlab api url
function gitlab-init() {
	if [ $# -le 2 ]; then
		GITLAB_USER_TOKEN="$1"
		GITLAB_API_URL=${2:-"https://gitlab.fon.ofi/api/v3"}
	elif [ $# -eq 3 ]; then
		local USERNAME="$1"
		local PASSWORD="$2"
		GITLAB_API_URL="$3"
		GITLAB_USER_TOKEN=$(gitlab-get-token-for-credentials "$USERNAME" "$PASSWORD")
	fi
}

# Find a project by name and returns the id
# param 1: Project Name
# return: id of the project, 0 if the project is not found
function gitlab-get-project-id-by-name() {
	local PROJECT_NAME="$1"
	local RESPONSE=$($CURL --header "PRIVATE-TOKEN: $GITLAB_USER_TOKEN" --request GET "$GITLAB_API_URL/projects/search/$PROJECT_NAME")
	if [[ $RESPONSE == "[]" ]]; then
		local PROJECT_ID=0
	else
		PROJECT_ID=$(echo "$RESPONSE" | jq ".[0].id")
	fi

	echo $PROJECT_ID
}

# Finds a group by Name and returns the id
# param 1: Group name
# return: Group id
function gitlab-get-group-id-by-name() {
	local GROUP_NAME=$1

	local RESPONSE=$($CURL --header "PRIVATE-TOKEN: $GITLAB_USER_TOKEN" --request GET "$GITLAB_API_URL/groups")

	local GROUP_ID=$(echo "$RESPONSE" |  jq ".[] | select (.name==\"$GROUP_NAME\") | .id")

	echo $GROUP_ID
}

# Get the name sof all available groups
function gitlab-get-group-names() {
	local RESPONSE=$($CURL --header "PRIVATE-TOKEN: $GITLAB_USER_TOKEN" --request GET "$GITLAB_API_URL/groups")

	echo "$RESPONSE" | jq -r ".[].name"
}

# Get list of project members
# param 1: Project id
function gitlab-get-project-members() {
	local PROJECT_ID="$1"

	local RESPONSE=$($CURL --header "PRIVATE-TOKEN: $GITLAB_USER_TOKEN" --request GET "$GITLAB_API_URL/projects/$PROJECT_ID/members")

	echo "$RESPONSE"
}

# Find a project by name and returns the group id
# param 1: Project id
# return: id of the group, 0 if the project is not found
function gitlab-get-group-id-by-project-id() {
	local PROJECT_ID="$1"

	local RESPONSE=$($CURL --header "PRIVATE-TOKEN: $GITLAB_USER_TOKEN" --request GET "$GITLAB_API_URL/projects/$PROJECT_ID")

	local GROUP_ID=$(echo "$RESPONSE" | jq ".namespace.id")

	return $GROUP_ID
}

# Get list of group members
# param 1: Group id
function gitlab-get-group-members() {
	local GROUP_ID="$1"

	local RESPONSE=$($CURL --header "PRIVATE-TOKEN: $GITLAB_USER_TOKEN" --request GET "$GITLAB_API_URL/groups/$GROUP_ID/members")

	echo "$RESPONSE" | jq "."
}

# Adds a web hook to a project
# param 1: Project Id
# param 2: web hook url
# param 3: activate push events, defaults to true
# param 4: activate issues events, defaults to false
# param 5: activate merge request events, defaults to true
# param 6: activate tag push events, defaults to true
# param 7: activate note events, defaults to false
# param 8: enable ssl verification, defaults to false
function gitlab-create-project-hook() {
	local PROJECT_ID=$1
	local URL=$2
	local PUSH_EVENTS=${3:-true}
	local ISSUES_EVENTS=${4:-false}
	local MERGE_REQUESTS_EVENTS=${5:-true}
	local TAG_PUSH_EVENTS=${6:-true}
	local NOTE_EVENTS=${7:-false}
	local ENABLE_SSL_VERIFICATION=${8:-false}

	local RESPONSE=$($CURL --header "PRIVATE-TOKEN: $GITLAB_USER_TOKEN" \
	--data-urlencode "url=${URL}" \
	--data-urlencode "push_events=${PUSH_EVENTS}" \
	--data-urlencode "issues_events=${ISSUES_EVENTS}" \
	--data-urlencode "merge_requests_events=${MERGE_REQUESTS_EVENTS}" \
	--data-urlencode "tag_push_events=${TAG_PUSH_EVENTS}" \
	--data-urlencode "note_events=${NOTE_EVENTS}" \
	--data-urlencode "enable_ssl_verification=${ENABLE_SSL_VERIFICATION}" --request POST "$GITLAB_API_URL/projects/$PROJECT_ID/hooks")


	if [[ "$RESPONSE" != *"message"* ]]; then
		local HOOK_ID=$(echo $RESPONSE | jq ".id")
	fi

	echo "$HOOK_ID"
}

# Creates a project in Gitlab Repo
# param 1: Group name
# param 2: Poject Name
# param 3: is public project, defaults to true
# param 4: enable issues management, defaults to false
# param 5: enable merge request, defaults to true
# return: id of the project, 0 if there's any error
function gitlab-create-project() {
	local GROUP_NAME="$1"
	local PROJECT_NAME="$2"
	local PUBLIC=${3:-true}
	local ISSUES=${4:-false}
	local MERGE_REQUESTS=${5:-true}
	local PROJECT_ID=0

	local GROUP_ID=$(gitlab-get-group-id-by-name "$GROUP_NAME")

	if [[ "$GROUP_ID" != "" ]]; then

		local RESPONSE=$($CURL --header "PRIVATE-TOKEN: $GITLAB_USER_TOKEN" \
		--data-urlencode "name=${PROJECT_NAME}" \
		--data-urlencode "namespace_id=${GROUP_ID}" \
		--data-urlencode "username=${USERNAME}" \
		--data-urlencode "public=${PUBLIC}" \
		--data-urlencode "issues_enabled=${ISSUES}" \
		--data-urlencode "merge_requests_enabled=${MERGE_REQUESTS}" --request POST "$GITLAB_API_URL/projects")


		local MESSAGE=$(echo "$RESPONSE" | jq ".message")
		if [[ "$MESSAGE" != "" ]]; then
			log_error "$(echo "$MESSAGE" | jq -r "if . | length > 1 then .name[0] else . end")"
			PROJECT_ID=0
		else
			PROJECT_ID=$(echo "$RESPONSE" | jq ".id")
		fi
	else
		log_error "Group $GROUP_NAME does not exist"
	fi

	return "$PROJECT_ID"
}

function gitlab-add-project-hook() {
	local PROJECT_ID=$1
	local URL=$2
	local PUSH_EVENTS=${3:-true}
	local ISSUES_EVENTS=${4:-false}
	local MERGE_REQUESTS_EVENTS=${5:-true}
	local TAG_PUSH_EVENTS=${6:-true}
	local NOTE_EVENTS=${7:-false}
	local ENABLE_SSL_VERIFICATION=${8:-false}


		local HOOK_ID=$(gitlab-create-project-hook $PROJECT_ID "http://jenkins.fon.ofi:8080/gitlab/build_now" true false true true)
		log "Created hook $HOOK_ID for project $PROJECT_NAME"

}

# Gets git repository URL
# param 1: project id
# return: git repository URL
function gitlab-get-git-url() {
	local PROJECT_ID=$1
	local RESPONSE=$($CURL --header "PRIVATE-TOKEN: $GITLAB_USER_TOKEN" --request GET "$GITLAB_API_URL/projects/$PROJECT_ID")

	echo $(echo "$RESPONSE" | jq -r ".ssh_url_to_repo")
}

# Moves project to group
# param 1: project id
# param 2: group id
# return: 0 for Error, 1 for OK
function gitlab-move-project() {
	local PROJECT_ID=$1
	local GROUP_ID=$2

	local RESPONSE=$($CURL --header "PRIVATE-TOKEN: $GITLAB_USER_TOKEN" --request POST "$GITLAB_API_URL/groups/$GROUP_ID/projects/$PROJECT_ID")
	local MESSAGE=$(echo "$RESPONSE" | jq ".message")
	if [[ "$MESSAGE" != "" ]]; then
		log_error "$(echo "$MESSAGE" | jq -r "if . | length > 1 then .name[0] else . end")"
		local RES=0
	else
		local RES=1
	fi

	return $RES
}

# Creates and user
# param 1: User email
# param 2: User password
# param 3: User username
# param 4: User full name
function gitlab-create-user() {
	local EMAIL="$1"
	local PASSWORD="$2"
	local USERNAME="$3"
	local NAME="$4"
	local CONFIRM="false"

	local RESPONSE=$($CURL --header "PRIVATE-TOKEN: $GITLAB_USER_TOKEN" \
	--data-urlencode "password=${PASSWORD}" \
	--data-urlencode "email=${EMAIL}" \
	--data-urlencode "&username=${USERNAME}" \
	--data-urlencode "name=${NAME}" \
	--data-urlencode "confirm=${CONFIRM}" --request POST "$GITLAB_API_URL/users")

	echo "$RESPONSE" | jq -r ".id"
}

function gitlab-get-token-for-credentials() {
	local USERNAME="$1"
	local PASSWORD="$2"

	local RESPONSE=$($CURL --data-urlencode "password=${PASSWORD}" --data-urlencode "login=${USERNAME}" --request POST "$GITLAB_API_URL/session")
	echo "$RESPONSE" | jq -r ".private_token"
}

function gitlab-settings() {
	local SIGNUP_ENABLED=${1,,}
	local TWITTER_SHARING_ENABLED=${2,,}

	local RESPONSE=$($CURL --header "PRIVATE-TOKEN: $GITLAB_USER_TOKEN" \
	--data-urlencode "signup_enabled=${SIGNUP_ENABLED}" \
	--data-urlencode "twitter_sharing_enabled=${TWITTER_SHARING_ENABLED}" \
	--request PUT "$GITLAB_API_URL/application/settings")
}

function gitlab-get-path() {
	local PATH=$1
	$CURL --header "PRIVATE-TOKEN: $GITLAB_USER_TOKEN" --request GET "${GITLAB_API_URL}${PATH}"
}

function get-user-id-by-user-name() {
	local USERNAME="$1"
	gitlab-get-path "/users?search=$USERNAME" | jq -r ".[].id"
}

function gitlab-update-user-password() {
	local USERNAME=$1
	local NEW_PASSOWRD="$2"
	local USER_ID=$(get-user-id-by-user-name "$USERNAME")

	local RESPONSE=$($CURL --header "PRIVATE-TOKEN: $GITLAB_USER_TOKEN" \
	--data-urlencode "password=${NEW_PASSOWRD}" \
	--request PUT "$GITLAB_API_URL/users/$USER_ID")
}
