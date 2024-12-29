#!/bin/bash
# chmod a+x /where/i/saved/it/reinstallFoundry.sh
# Fresh reinstall for FoundryVTT on Linux
# 

pm2 stop foundry
rm -rf $HOME/foundry/*
echo "Enter the FoundryVTT timed download url for the NodeJS version:"
read tdurl
wget -O $HOME/foundry/foundryvtt.zip "$tdurl"
unzip $HOME/foundry/foundryvtt.zip -d $HOME/foundry/
rm $HOME/foundry/foundryvtt.zip
pm2 start foundry
