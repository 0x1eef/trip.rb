#!/bin/sh

for file in test/*_test.rb; do
    ruby $file
    if [ "$?" = "0" ]; then
        echo "OK"
    else
        exit $?
    fi
done
