#!/bin/bash
# chmod a+x /where/i/saved/it/reinstallFoundry.sh
# Fresh reinstall for FoundryVTT on Linux
# 

# get the needed directory
echo "Folder name of Foundry instance being upgraded?"
read fvttfolder

pm2 stop $fvttfolder

mv $HOME/$fvttfolder "$HOME/${fvttfolder}_backup"
mkdir $HOME/$fvttfolder
echo "Enter the FoundryVTT timed download url for the Linux version:"
read tdurl
wget -O $HOME/$fvttfolder/foundryvtt.zip "$tdurl"
unzip $HOME/$fvttfolder/foundryvtt.zip -d $HOME/$fvttfolder/
rm $HOME/$fvttfolder/foundryvtt.zip

pm2 start $fvttfolder
