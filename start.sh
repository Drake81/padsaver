#!/bin/sh

# create padsaver.config if not exists
echo "Checking Config"
if [ ! -f "padsaver.config" ]; then
    cp padsaver.config.def padsaver.config
    $EDITOR padsaver.config
fi

./padsaver.pl
