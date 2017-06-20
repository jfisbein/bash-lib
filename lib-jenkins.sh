JENKINS_API_URL="http://jenkins.fon.ofi:8080/"
JENKINS=""

# Init Jenkins library, use it to set Jenkins API URL and downloads jenkins-cli.jar
# Param 1: [Optional] Jenkins API URL (defaults to http://jenkins.fon.ofi:8080/)
function jenkins-init() {
	if [ $# -eq 0 ]; then
		JENKINS="java -jar jenkins-cli.jar -s $JENKINS_API_URL/"
		_jenkins-download-cli "$JENKINS_API_URL"
		return 0
	elif [ $# -eq 1 ]; then
		JENKINS_API_URL="$1"
		JENKINS="java -jar jenkins-cli.jar -s $JENKINS_API_URL/"
		_jenkins-download-cli "$JENKINS_API_URL"
		return 0
	else
		return 1
	fi
}

# Downloads if not present jenkins-cli.jar
# Param 1: Jenkins API URL
function _jenkins-download-cli() {
	local JENKINS_API_URL="$1"

	if [ ! -f jenkins-cli.jar ]; then
		wget -q "$JENKINS_API_URL/jnlpJars/jenkins-cli.jar"
	fi
}

# Dumps the job definition XML to stdout.
# Param 1: Job name
function jenkins-get-job() {
	local PROJECT="$1"
	$JENKINS get-job "$PROJECT"
}

# Updates the job definition XML from a file
# Param 1: Job name
# Param 2: Job definition file
function jenkins-update-job() {
	local PROJECT="$1"
	local JOB_FILE="$2"

	cat "$JOB_FILE" | $JENKINS update-job "$PROJECT"
}

# Reload job
# Param 1: Job name
function jenkins-reload-job() {
	local PROJECT="$1"
	$JENKINS reload-job "$PROJECT"
}

# Enables a job.
# Param 1: Job name
function jenkins-enable-job() {
	local PROJECT="$1"
	$JENKINS enable-job "$PROJECT"
}

# Copies a job.
# Param 1: Source job
# Param 1: Destination job
function jenkins-copy-job() {
	local SOURCE="$1"
	local DEST="$2"
	$JENKINS copy-job "$SOURCE" "$DEST"
}

# Modifies a file containing a job definition XML to set the Git URL
# Param 1: Git URL
# Param 2: Job definition file
function jenkins-job-set-git-url() {
	local GIT_URL="$1"
	local JOB_FILE="$2"

	EXIST=$(xmlstarlet sel -t -v "count(/*/scm/userRemoteConfigs/hudson.plugins.git.UserRemoteConfig/url)" "$JOB_FILE")
	if [[ "$EXIST" == "0" ]]; then
		xmlstarlet ed --inplace --pf --subnode "/*/scm/userRemoteConfigs/hudson.plugins.git.UserRemoteConfig" -t elem -n url "$JOB_FILE"
	fi
	xmlstarlet ed --inplace --pf --update '/*/scm/userRemoteConfigs/hudson.plugins.git.UserRemoteConfig/url' --value "$GIT_URL" "$JOB_FILE"
}

# Checks if a job exists in jenkins
# Param 1: Job name
# return 0 if job exists, other value otherwise.
function jenkins-job-exists() {
	local PROJECT="$1"
	jenkins-get-job "$PROJECT" &> /dev/null
	return $?
}

# Lists all jobs in a specific view or item group.
# Param 1: View name (empty for all jobs)
function jenkins-list-jobs() {
	local VIEW_NAME="${1:-''}"
	$JENKINS list-jobs "$VIEW_NAME"
}

# Dumps the view definition XML to stdout.
# Param 1: View name
function jenkins-get-view() {
	local VIEW_NAME="$1"
	$JENKINS get-view "$VIEW_NAME" 2> /dev/null
	return $?
}

# Puts Jenkins into the quiet mode, wait for existing builds to be completed, and then restart Jenkins.
function jenkins-safe-restart() {
	$JENKINS safe-restart
}

# Restart Jenkins.
function jenkins-restart() {
	$JENKINS restart
}
