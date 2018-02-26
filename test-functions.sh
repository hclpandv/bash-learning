#!/bin/bash

LOG_FILE=./script${date}.log

WRITE_LOG(){
  local msg=$1 #Param
  datestring=$(date +'%Y-%m-%d %H:%M:%S')
  echo -e "[$datestring] : ${msg}" >> ${LOG_FILE}
}

WRITE_LOG "This is written through my log function all actions are logged @ ${LOG_FILE}"
