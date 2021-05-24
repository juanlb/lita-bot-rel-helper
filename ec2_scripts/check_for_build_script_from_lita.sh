#!/bin/bash

FILE=/tmp/lita/build.sh
if [ -f "$FILE" ]; then
    sudo mv $FILE ${FILE}_run
    sudo chown $USER:$USER ${FILE}_run
    /tmp/lita/build.sh_run
    sudo rm ${FILE}_run
fi
