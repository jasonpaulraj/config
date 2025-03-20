#!/bin/bash

# Prompt user for GitHub username and personal access token
read -p "Enter your GitHub username: " GitHubUsername
read -s -p "Enter your GitHub personal access token: " GitHubToken
echo ""

# Prompt user for the repository type
read -p "Enter the type of repositories to fetch (all, owner, member, forks): " RepoType

# Prompt user for repository visibility
read -p "Do you want to fetch public, private, or both repositories? (public/private/both): " Visibility

# Prompt user for the download path
read -p "Enter the directory path to store cloned repositories: " DownloadPath

# Ensure the folder exists, if not create it
if [ ! -d "$DownloadPath" ]; then
    echo "Directory does not exist. Creating it..."
    mkdir -p "$DownloadPath"
fi

# Set the API URL for fetching repositories
ApiUrl="https://api.github.com/user/repos?per_page=100&type=$RepoType"

# Fetch the list of repositories
echo "Fetching $RepoType repositories..."
Repos=$(curl -s -H "Authorization: token $GitHubToken" "$ApiUrl")

# Filter repositories based on visibility case
echo "$Repos" | jq -r --arg Visibility "$Visibility" '
    if $Visibility == "both" then .[]
    elif $Visibility == "public" then .[] | select(.private == false)
    elif $Visibility == "private" then .[] | select(.private == true)
    else empty end | .clone_url' | while read -r RepoCloneUrl; do
    RepoName=$(basename -s .git "$RepoCloneUrl")
    
    echo "\n===================================="
    echo "Cloning: $RepoName"
    echo "====================================\n"
    
    git clone "$RepoCloneUrl" "$DownloadPath/$RepoName"
done

echo "\n===================================="
echo "All $RepoType ($Visibility) repositories have been downloaded to $DownloadPath"
echo "===================================="
