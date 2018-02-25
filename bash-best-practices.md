### REMEMBER Styling Guide https://google.github.io/styleguide/shell.xml

```#!/usr/bin/env bash ``` is more portable than ``` #!/bin/bash```

#### A Sample way to Start a Script

```
#TODO(vpandey6) : to be customized  

#!/usr/bin/env bash

set -o errexit
set -o pipefail
[[ "${DEBUG}" == 'true' ]] && set -o xtrace

# Set variables for current file & dir

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"
__root="$(cd "$(dirname "${__dir}")" && pwd)" 

arg1="${1:-}"

#Script Glbal Variables

readonly LOG_DIR="${__dir}"
readonly LOG_FILE="${LOG_DIR}/${__file}.log"  #TODO(vpandey6): Add Date and Time in the String

#Functions Library

PROGNAME=$(basename $0)

error_exit()
{

#	----------------------------------------------------------------
#	Function for exit due to fatal program error
#		Accepts 1 argument:
#			string containing descriptive error message
#	----------------------------------------------------------------


	echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
	exit 1
}

# Example call of the error_exit function.  Note the inclusion
# of the LINENO environment variable.  It contains the current
# line number.

echo "Example of error with line number and message"
error_exit "$LINENO: An error has occurred."

```


