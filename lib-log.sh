# Escape codes for messages.
# more at: http://misc.flogisoft.com/bash/tip_colors_and_formatting
ESC_OK="\e[32m"     # Green
ESC_ERROR="\e[31m"  # Red
ESC_WARN="\e[93m"   # Yellow
ESC_RESET="\e[0m"   # Reset

# log message
function log() {
	echo -e "$ESC_OK$*$ESC_RESET"
}

# log error message
function log_error() {
	echo -e "$ESC_ERROR$*$ESC_RESET"
}

# log warn message
function log_warn() {
	echo -e "$ESC_WARN$*$ESC_RESET"
}

# log step using $1 as step char, if not defined '.' will be used
function log_step() {
	local STEP_CHAR=${1:-'.'}
	echo -ne "$ESC_OK$STEP_CHAR$ESC_RESET"
}
