#!/bin/bash
#
# This script collapses the CSV files in the input_directory to standard out. The first 2 lines from the first file
# is followed by the last line of each subsequent file.
# 
# Usage: 
#       collapse-csvs.sh input_directory
#
# This script is intended to be run from the command line.
# It is assumed that the CSV files are in /tmp and have a .csv extension.
# 

if [ $# -ne 1 ];
    then echo "Usage:"
	 echo "      " $0 "input_directory"
	 exit 1
fi

input_dir=$1
first=1
for file in ${input_dir}/*.csv
    do
        if [ $first -eq 1 ]; then
            first=0
            /usr/bin/head -q -n 2 $file 
        else
            /usr/bin/tail -q -n 1 $file
        fi 
    done
