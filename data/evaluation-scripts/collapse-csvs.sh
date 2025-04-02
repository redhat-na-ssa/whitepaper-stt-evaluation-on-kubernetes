#!/bin/bash
#
# This script collapses the CSV files in /tmp to standard out. The first 2 lines from the first file
# is followed by the last line of each subsequent file.
# 
# Usage: collapse-csvs.sh
# This script is intended to be run from the command line.
# It is assumed that the CSV files are in /tmp and have a .csv extension.
# 

first=1
for file in /tmp/*.csv
    do
        if [ $first -eq 1 ]; then
            first=0
            /usr/bin/head -q -n 2 $file 
        else
            /usr/bin/tail -q -n 1 $file
        fi 
    done
