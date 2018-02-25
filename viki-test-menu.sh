#!/bin/bash
VERSION=2.7

#API=146.89.148.137     # First
API=146.89.148.138      # Second

# prevent Control-C
trap '' 2

# To display the last number of stacks
STACK_nr=15
STACK_nr2=40

# yaml files location
YAML=/home/heatuser/patterns/latest

# create a temp dir in /tmp
DIR=/tmp/tmp.$$
mkdir ${DIR} &>/dev/null

HOSTNAME=$( hostname -s)

HEAT_ST="nl03ico951ccpra"
HEAT_ET="nl03ico851ccpra"
HEAT_PR="nl03ico051ccpra"
[ ${HOSTNAME} = ${HEAT_ST} ] && { ENV="HEAT ST" ;  DB2="nl03ico971ccpra"; }
[ ${HOSTNAME} = ${HEAT_ET} ] && { ENV="HEAT ET" ;  DB2="nl03ico871ccpra"; }
[ ${HOSTNAME} = ${HEAT_PR} ] && { ENV="HEAT PR" ;  DB2="nl03ico081ccpra"; }

TERM=xterm

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

INPUT_PARAM=$1

if [[ ${INPUT_PARAM} -gt 10 ]] && [[ ${INPUT_PARAM} -le 99 ]] ; then
  INTERACTIVE="YES"
  SEL=${INPUT_PARAM}
  EXTRA_PARAM=$2
else
  INTERACTIVE="NO"
  SEL=x
fi

ready() {
  if [[ ${INTERACTIVE} = "NO" ]] ; then
    read -p "${YELLOW}------ Press <${BRIGHT}${YELLOW}ENTER${NORMAL}${YELLOW}> -----${NORMAL} " SEL
    [[ ${SEL} == "" ]] && SEL=x
  else
    SEL=99
  fi
}

LINE() { echo "------------------------------------------------------------------" ; }

TAKES_TIME(){ echo "${GREEN}This will take some time. One moment please...${NORMAL}"; }

STRIP_OUTPUT() {
  COMMAND=$1
  FILE=${DIR}/output.$$
  exec $1 | cut -c40- > ${FILE}
  # locate position of the word parent in the file
  POSITION=$( cat ${FILE} | head -2 | tail -1 | grep -aob 'parent' | awk -F: '{print $1}' )
  POSITION=$(( POSITION - 1 ))
  cat ${FILE} | cut -c-${POSITION}
  rm -f ${FILE}
}

IP_address(){
  NAME=$( echo $1 | awk -F. '{print $1}' )
  nslookup ${NAME}.adm.ab3.abn.ssm.sdc.gts.ibm.com &>/dev/null
  if [[ $? == 0 ]] ; then
    IP_man=$( nslookup ${NAME}.adm.ab3.abn.ssm.sdc.gts.ibm.com | grep ^Address | tail -1 | awk '{print $2}' )
    IP_cus=$( nslookup ${NAME}.solon.prd | grep ^Address | tail -1 | awk '{print $2}' )
    THIRD=$( echo ${IP_cus} | awk -F. '{print $3}' )
    # PR  0 - 27
    # ET 28 - 39
    # ST 40 - 51
    [[ ${THIRD} -ge  0 ]] && [[ ${THIRD} -le 27 ]] && ENV2="PR"
    [[ ${THIRD} -ge 28 ]] && [[ ${THIRD} -le 39 ]] && ENV2="ET"
    [[ ${THIRD} -ge 40 ]] && [[ ${THIRD} -le 51 ]] && ENV2="ST"
    [[ ${THIRD} -ge 52 ]] && ENV2="Unknown"
    echo "${NAME} - ${IP_man} / ${IP_cus} (${CYAN}${ENV2}${NORMAL})"
  else
    echo "${NAME} - ${RED}Not yet in CMS DNS${NORMAL}"
  fi
}

HOST_name(){
  STACK=$1
  FILE=${DIR}/HOST_name.$$
  #for HOST in $( heat output-show $STACK --all | tac | grep output_ | awk -F: '{print $2}' | tr "\n" " " | tr "," "\n" | tr -d "\"" | grep _host_name | awk '{print $2}' )
  heat stack-show $STACK | grep hostname | grep -v Command | grep -v _stem | awk '{print $4}' | awk -F"\"" '{print $2}' > ${FILE}
  # if this does not give any results, try this one...
  [ ! -s ${FILE} ] && heat output-show $STACK --all | tac | grep -v domain | grep -oh "\w*.solon.prd" >> ${FILE}
  for HOST in $( cat ${FILE} | awk -F. '{print $1}' | sort -u )
  do
    IP_address ${HOST}
  done
  rm -f ${FILE}
}

CURL() {
  # used for REST API to CMS - output in json style
  # make JSON output look better, by updating the JULIAN time stamp into normal time stamp.
  # and by removing more than 2 empty lines and by removing some characters
  # replacing the : into tab, so it can be expanded
  CMD=$1
  curl -X GET https://${API}/abnapi/v1/rest/${CMD} --insecure -u HEAT.CMS@AB3_CBM:S=G=25/. -i -H "ACCEPT:application/json" -H "Content-Type: application/json" 2>/dev/null | tail -1 | python -m json.tool |\
  #tr -d ',{}][\"' | tr ':' '\t' | awk '!NF {if (++n <= 1) print ; next}; {n=0;print}' | while read -r line
  tr -d '{}][\"' | tr ':' '\t' | awk '!NF {if (++n <= 1) print ; next}; {n=0;print}' | sed 's/^,//g'|sed 's/,$//g' | while read -r line
  do
    if [[ "$line" =~ ^(.+\ )([0-9]{13})$ ]]
    then
      JUL_DAT=${BASH_REMATCH[2]::-3}
      BB=$( date --date "@$JUL_DAT" +"%d %b %Y %T %Z" )
      echo "${BASH_REMATCH[1]}$BB"
    else
      echo "$line"
    fi
  done | expand --tabs=30
}

check() {
  curl -s GET https://${IP}/abnapi/v1/rest/users/self --insecure -u HEAT.CMS@AB3_CBM:S=G=25/. -i -H "ACCEPT:application/json" -H "Content-Type: application/json"| grep
 ^HTTP
}


# ======================================================== BEGIN ==================

#SEL=x
while true
do
  TIME=$( date | awk '{print $1,$2,$3,$4,$5}' )

  if [[ ${INTERACTIVE} == "NO" ]] ; then
    tput clear

    echo "---------------------------------------------------------- ${BRIGHT}${GREEN}V ${VERSION}${NORMAL} -"
    echo -e "Hostname: ${BRIGHT}${CYAN}${HOSTNAME} ${BRIGHT}${GREEN}(${ENV})${NORMAL}  Time: ${BRIGHT}${YELLOW}${TIME}${NORMAL}"
    echo ""

    echo "-- ${BRIGHT}${CYAN}DB2${NORMAL} -----------------------------------------------------------"
    echo "${BRIGHT}${YELLOW}  1 ${NORMAL} Connect to DB2 ${BRIGHT}${GREEN}${DB2}${NORMAL}"
    echo ""

    echo "-- ${BRIGHT}${CYAN}STACK${NORMAL} ---------------------------------------------------------"
    echo "${BRIGHT}${YELLOW} 11 ${NORMAL} Show last ${BRIGHT}${GREEN}${STACK_nr}${NORMAL} STACKs                 ${BRIGHT}${YELLOW} 91 ${NORMAL} Including sub-stacks"
    echo "${BRIGHT}${YELLOW} 12 ${NORMAL} Show last ${BRIGHT}${GREEN}${STACK_nr2}${NORMAL} STACKs                 ${BRIGHT}${YELLOW} 92 ${NORMAL} Including sub-stacks"
    echo "${BRIGHT}${YELLOW} 13 ${NORMAL} Search in STACK IDs and Instances"
    echo ""
    echo "${BRIGHT}${YELLOW} 15 ${NORMAL} Shows ${BRIGHT}${GREEN}HOSTNAME + IP${NORMAL} of a STACK ID"
    echo "${BRIGHT}${YELLOW} 16 ${NORMAL} Shows ${BRIGHT}${GREEN}HOSTNAMES + IPs${NORMAL} of the last ${BRIGHT}${GREEN}${STACK_nr2}${NORMAL} STACKs"
    echo "${BRIGHT}${YELLOW} 17 ${NORMAL} Shows ${BRIGHT}${GREEN}Driver Version${NORMAL} of the last ${BRIGHT}${GREEN}${STACK_nr2}${NORMAL} STACKs"
    echo ""
    echo "${BRIGHT}${YELLOW} 21 ${NORMAL} Detailed stack info           ${BRIGHT}${YELLOW} 22 ${NORMAL} More detailed info"
    echo "${BRIGHT}${YELLOW} 23 ${NORMAL} Stack-id for a stack          ${BRIGHT}${YELLOW} 24 ${NORMAL} HEAT parameters"
    echo "${BRIGHT}${YELLOW} 25 ${NORMAL} ${BRIGHT}${GREEN}SR numbers${NORMAL} for last ${BRIGHT}${GREEN}${STACK_nr}${NORMAL} stacks ${BRIGHT}${YELLOW} 26 ${NORMAL} Same for ${BRIGHT}${GREEN}${STACK_nr2} stacks"
    echo ""

    echo "-- ${BRIGHT}${CYAN}CMS API${NORMAL} -------------------------------------------------------"
    echo "${BRIGHT}${YELLOW} 71 ${NORMAL} ${BRIGHT}${GREEN}VM${NORMAL} status according to CMS   ${BRIGHT}${YELLOW} 72 ${NORMAL} More detailed info"
    echo "${BRIGHT}${YELLOW} 73 ${NORMAL} ${BRIGHT}${GREEN}SR${NORMAL} status according to CMS   ${BRIGHT}${YELLOW} 74 ${NORMAL} Shows CMS hostname"
    echo "${BRIGHT}${YELLOW} 79 ${NORMAL} Check ${BRIGHT}${GREEN}WebSeal${NORMAL} proxy status"
    LINE
  fi
  [[ ${SEL} == "x" ]] && read -p "${YELLOW}Select ${BRIGHT}number${NORMAL}${YELLOW} and press <enter>, any other key to exit ${CYAN}" SEL
  echo "${NORMAL}"
  case $SEL in

        1) echo "To unlock the database: ${GREEN}db2 "UPDATE requestlock SET locked  = 0 WHERE id = 1"${NORMAL}"
           ssh abndbusr@${DB2}.ssm.sdc.gts.ibm.com
           ready ;;

        11) echo "${CYAN}heat stack-list -l ${STACK_nr}${NORMAL}"
            heat stack-list -l ${STACK_nr} | cut -c40- ; ready ;;
        12) echo "${CYAN}heat stack-list -l ${STACK_nr2}${NORMAL}"
            heat stack-list -l ${STACK_nr2} | cut -c40- ; ready ;;
        13) if [[ ${INTERACTIVE} == "YES" ]] ; then
              SEARCH=${EXTRA_PARAM}
            else
              read -p "Search string: " SEARCH
            fi
            if [[ ! $SEARCH == "" ]] ; then
              TAKES_TIME
              echo "${CYAN}heat stack-list -n | grep ${SEARCH}${NORMAL}"
              STRIP_OUTPUT "heat stack-list -n" | grep ${SEARCH} ; ready
            fi
            ;;
        15) if [[ ${INTERACTIVE} == "YES" ]] ; then
              STACK=${EXTRA_PARAM}
            else
              read -p "${CYAN}STACK ID: ${NORMAL}" STACK
            fi
            [[ ! $STACK == "" ]] && HOST_name ${STACK}
            ready ;;
        16) heat stack-list -l ${STACK_nr2} -n | awk '{print $4,$6,$8}' | tail -n +4 | head -n -1 | while read STACK STATUS DATE
            do
              DATE2=$( echo ${DATE} | tr 'T' ' ' | tr -d 'Z' )
              echo "${CYAN}STACK: ${BRIGHT}${GREEN}${STACK}${NORMAL} - ${YELLOW}${STATUS}${NORMAL} - ${CYAN}${DATE2}${NORMAL}"
              HOST_name ${STACK}
            done
            ready ;;
        17) echo "${BRIGHT}${GREEN}Stack                                          ${YELLOW}Status             ${CYAN}Creation Date       ${BRIGHT}${GREEN}Driver Version${NORMAL}"
            echo "${BRIGHT}${GREEN}---------------------------------------------- ${YELLOW}------------------ ${CYAN}------------------- ${BRIGHT}${GREEN}--------------${NORMAL}"
            heat stack-list -l ${STACK_nr2} | awk '{print $4,$6,$8}' | tail -n +4 | head -n -1 | while read STACK STATUS DATE
            do
              DATE2=$( echo ${DATE} | tr 'T' ' ' | tr -d 'Z' )
              DRIVER=$( heat stack-show ${STACK} | grep driver_ | awk -F: '{print $2}' | awk -F\" '{print $2}' )
              printf "${BRIGHT}${GREEN}%-46s ${YELLOW}%-18s ${CYAN}%-19s ${BRIGHT}${GREEN}%s${NORMAL}\n" ${STACK} ${STATUS} "${DATE2}" ${DRIVER}
            done
            ready ;;

        21) if [[ ${INTERACTIVE} == "YES" ]] ; then
              STACK=${EXTRA_PARAM}
            else
              read -p "STACK: " STACK
            fi
            if [[ ! $STACK == "" ]] ; then
              echo ""
              echo "${CYAN}heat resource-list $STACK${NORMAL}"
              heat resource-list $STACK
              echo ""
              echo "${CYAN}heat event-list $STACK${NORMAL}"
              heat event-list $STACK
            fi
            ready ;;
        22) if [[ ${INTERACTIVE} == "YES" ]] ; then
              STACK=${EXTRA_PARAM}
            else
              read -p "STACK: " STACK
            fi
            if [[ ! $STACK == "" ]] ; then
              echo "${CYAN}heat stack-show $STACK${NORMAL}"
              heat stack-show $STACK
            fi
            ready ;;
        23) if [[ ${INTERACTIVE} == "YES" ]] ; then
              STACK=${EXTRA_PARAM}
            else
              read -p "STACK: " STACK
            fi
            if [[ ! $STACK == "" ]] ; then
              heat stack-show $STACK | grep stack_id | awk '{print $4}' | awk -F"\"" '{print "Stack-id: " $2}'
            fi
            ready ;;
        24) if [[ ${INTERACTIVE} == "YES" ]] ; then
              STACK=${EXTRA_PARAM}
            else
              read -p "STACK: " STACK
            fi
            if [[ ! $STACK == "" ]] ; then
              echo "${CYAN}heat stack-show $STACK${NORMAL} - ${BRIGHT}${YELLOW}HEAT PARAMETERS ONLY${NORMAL}"
              heat stack-show $STACK | cut -c 25- | grep "^|   \"" | cut -c5- | sort | sed 's/  //g' | tr -d "|" | sed 's/, $//g' | sed 's/,$//g'
            fi
            ready ;;
        25) heat stack-list -l ${STACK_nr} -n | tail -n +4 | head -n -1 | awk '{print $4}' | while read STACK
            do
              echo ""
              echo "${CYAN}${STACK}${NORMAL}"
              heat resource-list ${STACK} | grep SR | awk '{print $4 " - " $2 " - " $8 " - " $10}'
            done
            ready ;;
        26) heat stack-list -l ${STACK_nr2} -n | tail -n +4 | head -n -1 | awk '{print $4}' | while read STACK
            do
              echo ""
              echo "${CYAN}${STACK}${NORMAL}"
              heat resource-list ${STACK} | grep SR | awk '{print $4 " - " $2 " - " $8 " - " $10}'
            done
            ready ;;

        71) if [[ ${INTERACTIVE} == "YES" ]] ; then
              HOST=${EXTRA_PARAM}
            else
              read -p "VM Hostname: " HOST
            fi
            if [[ ! $HOST == "" ]] ; then
              COMMAND="instances?name=${HOST}&_compact=true"
              CURL ${COMMAND}
            fi
            ready ;;
        72) if [[ ${INTERACTIVE} == "YES" ]] ; then
              HOST=${EXTRA_PARAM}
            else
              read -p "VM Hostname: " HOST
            fi
            if [[ ! $HOST == "" ]] ; then
              COMMAND="instances?name=${HOST}"
              CURL ${COMMAND}
            fi
            ready ;;
        73) if [[ ${INTERACTIVE} == "YES" ]] ; then
              SR=${EXTRA_PARAM}
            else
              read -p "SR request: " SR
            fi
            if [[ ! $SR == "" ]] ; then
              COMMAND="jobs/${SR}"
              CURL ${COMMAND}
            fi
            ready ;;
        74) if [[ ${INTERACTIVE} == "YES" ]] ; then
              HOST=${EXTRA_PARAM}
            else
              read -p "VM Hostname: " HOST
            fi
            if [[ ! $HOST == "" ]] ; then
              COMMAND="instances?name=${HOST}&_compact=true"
              CURL ${COMMAND} | grep adm.ab3 | awk '{print $2}' | awk -F. '{print $1}'
            fi
            ready ;;
        79) for IP in 146.89.148.137 146.89.148.138 146.89.148.163
            do
              echo "WebSeal Proxy ${BRIGHT}${CYAN}${IP}${NORMAL}"
              check
              echo ""
            done
            ready ;;


        91) echo "${CYAN}heat stack-list -l ${STACK_nr} -n${NORMAL}"
            STRIP_OUTPUT "heat stack-list -l ${STACK_nr} -n"
            ready ;;
        92) echo "${CYAN}heat stack-list -l ${STACK_nr2} -n${NORMAL}"
            STRIP_OUTPUT "heat stack-list -l ${STACK_nr2} -n"
            ready ;;


        r|R) ;;
        * ) rm -fr ${DIR} &>/dev/null ; trap 2; exit 0 ;;
  esac
done

clear
exit
