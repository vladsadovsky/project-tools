#!/bin/bash
# Save Visual Code extensions list into a text file 

set -euo pipefail
set -x

code --list-extensions > ./vscode-extensions-list.txt

# To restore 
# Linux: cat ./vscode-extenions-list.txt | xargs -L 1 echo code --install-extension 
# Windows10: type ./vscode-extenions-list.txt | wsl xargs -L 1 echo code --install-extension 

# Using Recommended Extensions settings in the workspace
# Linux: code --list-extensions | awk '{ print "\""$0"\"\,"}' then paste JSON style list into
# Recommended Extensions section of the workspace manifest and check into the source control system