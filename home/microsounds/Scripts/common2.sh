#!/usr/bin/env bash

TOTAL=$(cat ~/.bash_history | wc -l)
LIST=$(cat ~/.bash_history | sed 's/sudo //g' | cut -d ' ' -f1 | sort | uniq -c | sort -nr | head -20)
echo "Most common out of $TOTAL commands:"
n=0
for line in $LIST
do
	if (( (n % 2) == 0 ))
	then
		PCT=$(echo "scale=3; ($line / $TOTAL) * 100" | bc | sed 's/00$//g')
		echo -ne "${PCT}%\t${line}x"
	else
		echo -e "\t$line"
	fi
	n=$((n + 1))
done
