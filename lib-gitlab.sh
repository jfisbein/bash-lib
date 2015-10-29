GITLAB_API_URL=""
GITLAB_USER_TOKEN=""

# Init Gitlab library, use it to set user token
# param 1: Gitlab User Token
# param 2: Gitlab api url, optiona, defaults to "https://gitlab.fon.ofi/api/v3"
function lib-gitlab-init() {
	GITLAB_USER_TOKEN="$1"
	GITLAB_API_URL=${2:-"https://gitlab.fon.ofi/api/v3"}
}

# Find a project by name and returns the id
# param 1: Project Name
# return: id of the project, 0 if the project is not found
function getProjectId() {
	local PROJECT_NAME="$1"
	local RESPONSE=`curl --silent --insecure --header "Accept: application/json" --header "Content-type: application/json" --header "PRIVATE-TOKEN: $GITLAB_USER_TOKEN" --request GET "$GITLAB_API_URL/projects/search/$PROJECT_NAME"`
	if [[ $RESPONSE == "[]" ]]; then
		local PROJECT_ID=0
	else
		local PROJECT_NAME=`echo "$RESPONSE" | python -c 'import sys,json;data=json.loads(sys.stdin.read()); print data[0]["name"]' 2> /dev/null`
		if [[ "$PROJECT_NAME" == "$1" ]]; then
			PROJECT_ID=`echo "$RESPONSE" | python -c 'import sys,json;data=json.loads(sys.stdin.read()); print data[0]["id"]' 2> /dev/null`
		else
			PROJECT_ID=0
		fi
	fi

	return $PROJECT_ID
}

# Finds a group by Name and returns the id
# param 1: Group name
# return: Group id
function getGroupId() {
	local GROUP_NAME=$1

	local RESPONSE=`curl --silent --insecure --header "Accept: application/json" --header "Content-type: application/json" --data "$DATA" --header "PRIVATE-TOKEN: $GITLAB_USER_TOKEN" --request GET "$GITLAB_API_URL/groups" | json_pp`

	local GROUP_ID=`echo "$RESPONSE" | grep -A3 "\"name\" : \"$GROUP_NAME\"" | grep '"id" : ' | sed 's/"id" : //' | tr -d ' '`

	return $GROUP_ID
}

# Get the name sof all available groups
function getGroupNames() {
	local RESPONSE=`curl --silent --insecure --header "Accept: application/json" --header "Content-type: application/json" --data "$DATA" --header "PRIVATE-TOKEN: $GITLAB_USER_TOKEN" --request GET "$GITLAB_API_URL/groups"`

	echo "$RESPONSE" | jq -r ".[].name"
}

# Get list of project members
# param 1: Project id
function getProjectMembers() {
	local PROJECT_ID="$1"

	local RESPONSE=`curl --silent --insecure --header "Accept: application/json" --header "Content-type: application/json" --header "PRIVATE-TOKEN: $GITLAB_USER_TOKEN" --request GET "$GITLAB_API_URL/projects/$PROJECT_ID/members"`

	echo "Response: $RESPONSE"
}

# Find a project by name and returns the group id
# param 1: Project id
# return: id of the group, 0 if the project is not found
function getProjectGroupId() {
	local PROJECT_ID="$1"

	local RESPONSE=`curl --silent --insecure --header "Accept: application/json" --header "Content-type: application/json" --header "PRIVATE-TOKEN: $GITLAB_USER_TOKEN" --request GET "$GITLAB_API_URL/projects/$PROJECT_ID"`

	local GROUP_ID=`echo "$RESPONSE" | python -c 'import sys,json;data=json.loads(sys.stdin.read()); print data["owner"]["id"]' 2> /dev/null`

	return $GROUP_ID
}

# Get list of group members
# param 1: Group id
function getGroupMembers() {
	local GROUP_ID="$1"

	local RESPONSE=`curl --silent --insecure --header "Accept: application/json" --header "Content-type: application/json" --header "PRIVATE-TOKEN: $GITLAB_USER_TOKEN" --request GET "$GITLAB_API_URL/groups/$GROUP_ID/members"`

	local RESPONSE=`echo "$RESPONSE" | json_pp`

	echo "$RESPONSE"
}

# Adds a web hook to a project
# param 1: Project Id
# param 2: web hook url
# param 3: activate push events
# param 4: activate issues events
# param 5: activate merge request events
# param 5: activate tag push events
function createProjectHook() {
	local PROJECT_ID=$1
	local HOOK_URL=$2
	local PUSH_EVENTS=$3
	local ISSUES_EVENTS=$4
	local MERGE_REQUESTS_EVENTS=$5
	local TAG_PUSH_EVENTS=$6

	local DATA="{\"id\": \"$PROJECT_ID\""
	DATA="$DATA,  \"url\": \"$HOOK_URL\""
	if $PUSH_EVENTS; then
		DATA="$DATA,  \"push_events\": \"true\""
	fi

	if $ISSUES_EVENTS; then
		DATA="$DATA,  \"issues_events\": \"true\""
	fi

	if $MERGE_REQUESTS_EVENTS; then
		DATA="$DATA,  \"merge_requests_events\": \"true\""
	fi

	if $TAG_PUSH_EVENTS; then
		DATA="$DATA,  \"tag_push_events\": \"true\""
	fi

	DATA="$DATA}"

	local RESPONSE=`curl --silent --insecure --header "Accept: application/json" --header "Content-type: application/json" --data "$DATA" --header "PRIVATE-TOKEN: $GITLAB_USER_TOKEN" --request POST "$GITLAB_API_URL/projects/$PROJECT_ID/hooks"`

	if [[ "$RESPONSE" != *"message"* ]]; then
		local HOOK_ID=$(echo $RESPONSE | jq ".id")
	fi

	echo "$HOOK_ID"
}

# Creates a project in Gitlab Repo
# param 1: Group name
# param 2: Poject Name
# param 3: Create hook, options, defaults to true
# return: id of the project, 0 if there's any error
function createProject() {
	local GROUP_NAME="$1"
	local PROJECT_NAME="$2"
	local CREATE_HOOK=${3:-true}

	local GROUP_ID=$(getGroupId "$GROUP_NAME")

	local DATA="{\"name\": \"$PROJECT_NAME\""
	DATA="$DATA, \"namespace_id\": \"$GROUP_ID\""
	DATA="$DATA, \"public\":\"true\", \"issues_enabled\":\"false\", \"merge_requests_enabled\":\"true\"}"

	local RESPONSE=`curl --silent --insecure --header "Accept: application/json" --header "Content-type: application/json" --data "$DATA" --header "PRIVATE-TOKEN: $GITLAB_USER_TOKEN" --request POST "$GITLAB_API_URL/projects"`

	local MESSAGE=`echo "$RESPONSE" | python -c 'import sys,json;data=json.loads(sys.stdin.read()); print data["message"]' 2> /dev/null`
	if [[ "$MESSAGE" != "" ]]; then
		echo -e "$ESC_KO Error: $MESSAGE $ESC_DEFAULT"
		local PROJECT_ID=0
	else
		local PROJECT_ID=`echo "$RESPONSE" | python -c 'import sys,json;data=json.loads(sys.stdin.read()); print data["id"]' 2> /dev/null`
		if $CREATE_HOOK; then
			local HOOK_ID=$(createProjectHook $PROJECT_ID "http://jenkins.fon.ofi:8080/gitlab/build_now" true false true true)
			log "Created hook $HOOK_ID for project $PROJECT_NAME"
		fi
	fi

	echo "$PROJECT_ID"
}

# Gets git repository URL
# param 1: project id
# return: git repository URL
function getGitUrl() {
	local PROJECT_ID=$1
	local RESPONSE=`curl --silent --insecure --header "Accept: application/json" --header "Content-type: application/json" --header "PRIVATE-TOKEN: $GITLAB_USER_TOKEN" --request GET "$GITLAB_API_URL/projects/$PROJECT_ID"`
	local MESSAGE=`echo "$RESPONSE" | python -c 'import sys,json;data=json.loads(sys.stdin.read()); if data["message"]:print data["message"]' 2> /dev/null`
	if [[ "$MESSAGE" != "" ]]; then
		echo -e "$ESC_KO Error: $MESSAGE $ESC_DEFAULT"
		local GIT_REPO_URL=""
	else
		local GIT_REPO_URL=`echo "$RESPONSE" | python -c 'import sys,json;data=json.loads(sys.stdin.read()); print data["ssh_url_to_repo"]' 2> /dev/null`
	fi

	echo "$GIT_REPO_URL"
}
