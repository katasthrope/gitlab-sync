# Gitlab-Sync
A simple shell script to clone and pull all your projects in gitlab group and subgroup

make sure to have jq installed

# How to use
1. clone or download crawler.sh
2. adjust GITLAB_TOKEN
3. adjust GITLAB_URL_API_V4 for self hosted
4. set GITLAB_GROUP_ID for parent group id
5. chmod executable
6. run sync.sh

This will clone all projects in the group, create folder for subgroups and clone subgroup projects in that folder
