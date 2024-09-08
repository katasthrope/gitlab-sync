#!/bin/bash

GITLAB_URL_API_V4="https://gitlab.com/api/v4"
GITLAB_TOKEN="MY-TOKEN"

GITLAB_GROUP_ID="PARENT-GROUP-ID"
GITLAB_GROUP_NAME=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL_API_V4/groups/$GITLAB_GROUP_ID" | jq -r '.full_path')
BASE_DIR=$(pwd)

clone_all_projects() {

    local GROUP_ID=$1

    if [ -z "$GROUP_ID" ]; then
        echo "GROUP ID EMPTY"
        exit 1
    fi

    GITLAB_URL_API_GROUPS="$GITLAB_URL_API_V4/groups/$GROUP_ID/subgroups?all_available=true"
    RESPONSE_GROUPS=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL_API_GROUPS")

    GROUP_DETAIL=$(echo "$RESPONSE_GROUPS" | jq -r '.[] | "\(.id) \(.full_path)"')
    if [ -n "$GROUP_DETAIL" ]; then
        echo "$GROUP_DETAIL" | while IFS= read -r DETAIL; do
            GROUP_ID=$(echo "$DETAIL" | awk '{print $1}')
            GROUP_PATH=$(echo "$DETAIL" | awk '{print $2}' | sed "s/^$GITLAB_GROUP_NAME\///")
            if [ ! -d "$GROUP_PATH" ]; then
                mkdir -p $GROUP_PATH
            fi
            GITLAB_URL_API_PROJECTS="$GITLAB_URL_API_V4/groups/$GROUP_ID/projects"
            RESPONSE_PROJECTS=$(curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL_API_PROJECTS")
            PROJECTS_DETAIL=$(echo "$RESPONSE_PROJECTS" | jq -r '.[] | "\(.ssh_url_to_repo) \(.name)"')
            
            if [ -n "$PROJECTS_DETAIL" ]; then
                echo "$PROJECTS_DETAIL" | while IFS= read -r PROJECT; do
                    PROJECT_URL=$(echo "$PROJECT" | awk '{print $1}')
                    PROJECT_NAME=$(echo "$PROJECT" | cut -d ' ' -f2-) 
                    if [ ! -d "$GROUP_PATH/$PROJECT_NAME" ]; then
                        git clone $PROJECT_URL "$GROUP_PATH/$PROJECT_NAME"
                    else
                        echo "$GROUP_PATH/$PROJECT_NAME exists. pulling instead..."
                        cd "$GROUP_PATH/$PROJECT_NAME"
                        echo "pulling in $(pwd)"
                        git pull
                        cd "$BASE_DIR"
                    fi
                    echo ""
                done
            fi
        done
    fi

    # Recursively run in all subgroups
    echo "$RESPONSE_GROUPS" | jq -r '.[].id' | while read GITLAB_SUBGROUP_ID; do
        clone_all_projects "$GITLAB_SUBGROUP_ID"
    done
}

clone_all_projects "$GITLAB_GROUP_ID"
