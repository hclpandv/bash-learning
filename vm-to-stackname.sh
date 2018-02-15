#!/bin/bash

vmlist=$(cat vm-list.txt)
stacklist=$(heat stack-list -l20 | grep CREATE_COMPLETE | awk '{print $4}')

for stack in ${stacklist}
do
  # echo ${stack}
  for vm in ${vmlist}
  do
   heatvm=$(heat output-show ${stack} vm_name)
   #echo "${stack} | ${heatvm}"
   if [ "$heatvm" == "${vm}" ] ; then
       echo "${stack} | ${heatvm}"
       #Deleting the stack if it VM name matches
       #Please uncomment below line to delete the stack. Please be sure to do this.
       #heat stack-delete ${stack}
   fi
  done
done

