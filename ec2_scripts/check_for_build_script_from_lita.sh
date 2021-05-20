#!/bin/bash

FILE=/tmp/lita/build.sh
if [ -f "$FILE" ]; then
    sudo mv $FILE ${FILE}_run
    /tmp/lita/build.sh_run
fi

sudo rm ${FILE}_run
