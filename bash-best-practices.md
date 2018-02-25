### REMEMBER Styling Guide https://google.github.io/styleguide/shell.xml

```#!/usr/bin/env bash ``` is more portable than ``` #!/bin/bash```

#### A Sample way to Start a Script

```
#TODO(vpandey6) : to be customized  

#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# Set variables for current file & dir

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"
__root="$(cd "$(dirname "${__dir}")" && pwd)" 

arg1="${1:-}"
```


