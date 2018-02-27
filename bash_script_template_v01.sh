#!/usr/bin/env bash
SCRIPT_VERSION=1.0

# Description : This is a script template which can be reused for any script to be deployed
# Date 	      : 26/Feb/2018
# Contact     : Vikas Pandey

DEBUG=false   

[[ "${DEBUG}" == 'true' ]] && set -o errexit
[[ "${DEBUG}" == 'true' ]] && set -o pipefail
[[ "${DEBUG}" == 'true' ]] && set -o xtrace

# -----------------------------DECLARE GLOBAL VARIABLES------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_FILE="${SCRIPT_DIR}/$(basename "${BASH_SOURCE[0]}")"
SCRIPT_NAME="$(basename ${SCRIPT_FILE} .sh)"
TIME_STAMP=$(date +'%Y%m%d-%H%M') #For Logname
HOSTNAME=$( hostname -s)
USERNAME=$(whoami)

#Global Constants

readonly LOG_DIR="${SCRIPT_DIR}"
readonly LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}${TIME_STAMP}.log" 

#Params

PARAM_1="${1:-}"
PARAM_2="${2:-}"
PARAM_3="${3:-}"
PARAM_4="${4:-}"

#For User Interface

BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
LIME_YELLOW=$(tput setaf 190)
POWDER_BLUE=$(tput setaf 153)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
BRIGHT=$(tput bold)
NORMAL=$(tput sgr0)
BLINK=$(tput blink)
REVERSE=$(tput smso)
UNDERLINE=$(tput smul)

# -----------------------------FUNCTIONS LIBRARY{{STARTS HERE}}------------------------------------------

ADD_HEADER(){
#Cant Keep Space due to EOF thing. search more info
tee -a ${LOG_FILE} <<EOF 
-----------------------------------
Execution of ${This} started
----------------------------------
Hostname        : ${HOSTNAME}
UserName        : ${USER}
-----------------------------------  
EOF

}

WRITE_LOG(){
  local msg=$1 #Param
  datestring=$(date +'%Y-%m-%d %H:%M:%S')
  echo -e "[$datestring] : ${msg}" >> ${LOG_FILE}
}

TAKES_TIME(){ echo "${GREEN}This will take some time. One moment please...${NORMAL}"; }

ERROR_EXIT(){
  #USAGE : ERROR_EXIT "${LINENO}: An error has occurred."
  datestring=$(date +'%Y-%m-%d %H:%M:%S')
  echo "[$datestring] : ${SCRIPT_NAME}: ${1:-"Unknown Error"}" >> ${LOG_FILE}
  echo "${RED}${SCRIPT_NAME}: ${1:-"Unknown Error"}${NORMAL}" 1>&2
  exit 1
}

###########
#  CUSTOM FUNCTIONS  - Write All Your Custom functions below this Section. No Modification on above functions suggested.
#			           Use Lowercase function names to differentiate from Lib functions
###########


# -----------------------------FUNCTIONS LIBRARY{{ENDS HERE}}------------------------------------------



# -----------------------------{{MAIN FUNCTION}}-------------------------------------------------------

ADD_HEADER
TAKES_TIME

main(){

  WRITE_LOG "This is the coming from Template Script"
  WRITE_LOG "This script is running on server : ${HOSTNAME}"
  ERROR_EXIT "An error has occurred. at Line No: ${LINENO}"

}

################### Execution of Main Script--------- PLEASE DO NOT MODIFY ANYTHING BELOW THIS LINE-------------

main
