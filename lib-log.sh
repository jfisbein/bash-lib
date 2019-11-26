# shellcheck disable=SC2148,SC2034
# COLORS
RED="\e[31m"
RED_LIGHT="\e[91m"
GREEN="\e[32m"
GREEN_LIGHT="\e[92m"
YELLOW="\e[33m"
YELLOW_LIGHT="\e[93m"
BLUE="\e[34m"
BLUE_LIGHT="\e[94m"
MAGENTA="\e[35m"
MAGENTA_LIGHT="\e[95m"
CYAN="\e[36m"
CYAN_LIGHT="\e[96m"
GRAY_LIGHT="\e[37m"
GRAY_DARK="\e[90m"
WHITE="\e[97m"

# Escape codes for messages.
# more at: http://misc.flogisoft.com/bash/tip_colors_and_formatting
ESC_OK=${GREEN}
ESC_ERROR=${RED}
ESC_WARN=${YELLOW}
ESC_RESET="\e[0m"   # Reset

# log message
function log() {
	echo -e "$ESC_OK$*$ESC_RESET"
}

# log error message
function log_error() {
	>&2 echo -e "$ESC_ERROR$*$ESC_RESET"
}

# log warn message
function log_warn() {
	>&2 echo -e "$ESC_WARN$*$ESC_RESET"
}

# log step using $1 as step char, if not defined '.' will be used
function log_step() {
	local STEP_CHAR=${1:-'.'}
	echo -ne "$ESC_OK$STEP_CHAR$ESC_RESET"
}

# Log message using desired color
# Param 1: color
# Param 2: message
function log_color() {
    local COLOR="${1}"
    shift
    echo -e "$COLOR$*$ESC_RESET"
}

# Get the current row of the cursor
function getCursorRow() {
    IFS='[;' read -p $'\e[6n' -d R -rs _ y x _
    printf '%s\n' "$y"
}

# Get the current column of the cursor
function getCursorColumn() {
    IFS='[;' read -p $'\e[6n' -d R -rs _ y x _
    printf '%s\n' "$x"
}

# Get a text repeated N times
# Param 1: Text to repeat
# Param 2: Number of repetitions
function repeat() {
    local TEXT="${1}"
    local NUM=${2}
    local RES=""
    local I
    for I in $(seq 1 $NUM); do
        RES="${RES}${TEXT}"
    done

    echo -n "$RES"
}

# Print message and wait a number of seconds with a countdown
# Param 1: Text message
# Param 2: Number of seconds to wait
function log_wait() {
    local MSG="${1}"
    local SECS=${2}

    local ROW=$(getCursorRow)
    local MAX_MSG="${MSG} ${SECS}"
    local MAX_LEN=${#MAX_MSG}
    local BLANK_TEXT=$(repeat " " ${MAX_LEN})
    local I
    for I in $(seq ${SECS} -1 1); do
        ROW=$(getCursorRow)
        tput cup ${ROW} 0
        echo -n "${BLANK_TEXT}"
        tput cup ${ROW} 0
        echo -n -e "${ESC_OK}${MSG}${ESC_RESET} ${I}"
        sleep 1s
    done
    ROW=$(getCursorRow)
    tput cup ${ROW} 0
    echo -n "${BLANK_TEXT}"
    tput cup ${ROW} 0
    echo -e "${ESC_OK}${MSG}${ESC_RESET}"
}
