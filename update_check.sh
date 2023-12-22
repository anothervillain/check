#!/bin/bash

CURRENT_DIR=$(pwd)

cd ~/check

git pull

cd $CURRENT_DIR

exec zsh

echo "check.sh updated! :)"