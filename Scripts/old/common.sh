#!/usr/bin/env bash

echo "Most common out of $(cat ~/.bash_history | wc -l) commands:"
cat ~/.bash_history | sed 's/sudo //g' | cut -d ' ' -f1 | sort | uniq -c | sort -nr | head -20
