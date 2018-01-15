#!/bin/bash

# viewing environment variables
echo "The value of the home variable is: "
echo $HOME

# issue a command
echo "The output of the pwd command is: "
pwd

# that's boring, grab output and make it readable
echo "The value of the pwd command is $(pwd)"

# assign command output to a variable
output=$(pwd)
echo "The value of the output variable is ${output}"

# view data on the command line
echo "I saw $@ on the command line"

# read data from the user
echo "Enter a value: "
read userInput
echo "You just entered $userInput"

# concatenate userinput with command output
echo "Enter a file extension: "
read ext
touch "yourfile.${ext}"

# check to see if a file exists
if [ -d /etc/sysconfig ]; then
        echo "That file is there and a directory"
else
        echo "Not there or not a directory"
fi

#ODD & EVEN
if [ $((${1} % 2)) -eq 0 ];then 
   echo  "Even!"
else
   echo "Odd!"
fi

#Interger
#!/bin/bash

for i in $(seq 10)
do
  echo "value is: ${i}"
done

#for changing the permissions of the files(groups)
#!/bin/bash

for i in $(ls)
do
  chgrp was_user ${i}
done
