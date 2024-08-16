#!/bin/bash

# Check if there are any changes in the working directory
if [[ -n "$(git status --porcelain)" ]]; then
  echo "true" > /tmp/changes
else
  echo "false" > /tmp/changes
fi

# Output the result for use in the GitHub Actions step
CHANGES=$(cat /tmp/changes)
echo "changes=$CHANGES" >> $GITHUB_OUTPUT
