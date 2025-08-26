#!/bin/bash
# chmod a+x /where/i/saved/it/updateJB2A.sh
# Update JB2A from diff
#

echo "Stopping Foundry..."
pm2 stop all

# Variables
# Step 1: Find all directories under $HOME that contain 'jb2a_patreon' in their name
echo "Searching for folders named '*jb2a_patreon*' under \$HOME..."
MATCHING_DIRS=$(find "$HOME" -type d -iname '*jb2a_patreon*')
TMP_ZIP="/tmp/temp_download.zip"

if [ -z "$MATCHING_DIRS" ]; then
    echo "No matching directories found."
    exit 1
fi

echo "Found the following directories:"
echo "$MATCHING_DIRS"

# Step 2: Download the JB2A diff file from URL
echo "Enter the download URL for the DIFF file for JB2A:"
read URL
# Download the zip file
echo "Downloading $URL..."
wget -O $TMP_ZIP "$URL"
if [ $? -ne 0 ]; then
    echo "Error: Failed to download $URL"
    exit 2
fi

# Step 3: Unzip the contents to the matching folders, overwriting existing files
for DIR in $MATCHING_DIRS; do
    echo "Unzipping into: $DIR"
    unzip -q -o "$TMP_ZIP" -d "$DIR"
    if [ $? -ne 0 ]; then
        echo "Failed to unzip into $DIR"
    fi
done

# Clean up
echo "Cleaning up temp files..."
rm "$TMP_ZIP"
echo "Restarting Foundry.."
pm2 start all
echo "Done."
