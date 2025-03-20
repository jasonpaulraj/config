#!/bin/bash


# Prompt user for the download path
read -p "Enter the directory path to store cloned repositories: " DownloadPath

# Display the entered path
echo "You entered: $DownloadPath"

# Convert Windows paths to Unix format if needed
if [[ "$DownloadPath" =~ ^[a-zA-Z]: ]]; then
    # This is a Windows path with drive letter
    # Convert backslashes to forward slashes
    DownloadPath=$(echo "$DownloadPath" | sed 's/\\/\//g')
    # Remove the colon after drive letter and prepend /mnt/
    drive_letter=$(echo "$DownloadPath" | cut -c1 | tr '[:upper:]' '[:lower:]')
    DownloadPath=$(echo "$DownloadPath" | sed "s/^$drive_letter:/\/mnt\/$drive_letter/")
    echo "Converted path: $DownloadPath"
fi

# Check if the path is valid
if [[ -z "$DownloadPath" ]]; then
    echo "Error: Empty path provided. Exiting."
    exit 1
fi

# Ensure the folder exists, if not create it
if [ ! -d "$DownloadPath" ]; then
    echo "Directory does not exist. Creating it..."
    mkdir -p "$DownloadPath"
    
    # Check if directory creation was successful
    if [ ! -d "$DownloadPath" ]; then
        echo "Error: Failed to create directory. Please check the path and permissions. Exiting."
        exit 1
    fi
fi

# Prompt user for GitHub username and personal access token
read -p "Enter your GitHub username: " GitHubUsername
read -s -p "Enter your GitHub personal access token: " GitHubToken
echo ""

# Prompt user for the repository type
read -p "Enter the type of repositories to fetch (all, owner, member, forks): " RepoType

# Prompt user for repository visibility
read -p "Do you want to fetch public, private, or both repositories? (public/private/both): " Visibility

# Set the API URL for fetching repositories
ApiUrl="https://api.github.com/user/repos?per_page=100&type=$RepoType"

# Check if jq is installed and install it if needed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Attempting to install it automatically..."
    
    # Detect operating system
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y jq
        elif command -v yum &> /dev/null; then
            sudo yum install -y jq
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y jq
        else
            echo "Could not determine package manager. Please install jq manually."
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install jq
        else
            echo "Homebrew not found. Installing Homebrew first..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            brew install jq
        fi
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
        # Windows (Git Bash, Cygwin, or native)
        if command -v choco &> /dev/null; then
            choco install jq -y
        else
            echo "Chocolatey not found. Attempting to install Chocolatey..."
            echo "You may need to run PowerShell as Administrator for this to work."
            
            # Try to set execution policy temporarily for this process only
            powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; try { [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')) } catch { Write-Host 'Failed to install Chocolatey automatically.' }"
            
            # Check if installation was successful
            if ! command -v choco &> /dev/null; then
                echo "Failed to install Chocolatey automatically."
                echo "Please install jq manually using one of these methods:"
                echo "1. Run PowerShell as Administrator and execute: Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
                echo "2. Then run: choco install jq -y"
                echo "3. Alternatively, download jq directly from: https://stedolan.github.io/jq/download/"
                echo "   and place it in a directory in your PATH"
                
                # Offer to download jq binary directly
                read -p "Would you like to download jq binary directly? (y/n): " download_jq
                if [[ "$download_jq" == "y" || "$download_jq" == "Y" ]]; then
                    echo "Downloading jq binary..."
                    mkdir -p "$HOME/bin"
                    curl -L -o "$HOME/bin/jq.exe" "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-win64.exe"
                    chmod +x "$HOME/bin/jq.exe"
                    export PATH="$HOME/bin:$PATH"
                    echo "jq has been downloaded to $HOME/bin/jq.exe"
                    echo "You may want to add this directory to your PATH permanently."
                else
                    exit 1
                fi
            else
                choco install jq -y
            fi
        fi
    else
        echo "Unsupported operating system. Please install jq manually."
        exit 1
    fi
    
    # Verify installation
    if ! command -v jq &> /dev/null; then
        echo "Failed to install jq. Please install it manually and try again."
        exit 1
    else
        echo "jq has been successfully installed."
    fi
fi

# Fetch the list of repositories
echo "Fetching $RepoType repositories..."
Repos=$(curl -s -H "Authorization: token $GitHubToken" "$ApiUrl")

# Check if the API request was successful
if [[ $(echo "$Repos" | jq -r 'if type=="array" then "valid" elif .message then .message else "invalid" end') != "valid" ]]; then
    error_message=$(echo "$Repos" | jq -r '.message // "Unknown error"')
    echo "Error accessing GitHub API: $error_message"
    echo "Please check your token and internet connection."
    exit 1
fi

# Count repositories that match the visibility filter
repo_count=$(echo "$Repos" | jq -r --arg Visibility "$Visibility" '
    if $Visibility == "both" then .[] 
    elif $Visibility == "public" then .[] | select(.private == false)
    elif $Visibility == "private" then .[] | select(.private == true)
    else empty end | .clone_url' | wc -l)

echo -e "\n===================================="
echo "Found $repo_count repositories matching your criteria."
echo "===================================="

if [[ $repo_count -eq 0 ]]; then
    echo "No repositories found with the specified criteria. Exiting."
    exit 0
fi

# Initialize counters for statistics
successful_clones=0
already_exists=0
failed_clones=0

# Filter repositories based on visibility case
echo "$Repos" | jq -r --arg Visibility "$Visibility" '
    if $Visibility == "both" then .[]
    elif $Visibility == "public" then .[] | select(.private == false)
    elif $Visibility == "private" then .[] | select(.private == true)
    else empty end | .clone_url' | while read -r RepoCloneUrl; do
    RepoName=$(basename -s .git "$RepoCloneUrl")
    
    # Check if repository already exists in the target directory
    if [ -d "$DownloadPath/$RepoName" ]; then
        echo -e "\n===================================="
        echo "Repository already exists: $RepoName"
        echo -e "====================================\n"
        ((already_exists++))
        continue
    fi
    
    echo -e "\n===================================="
    echo "Cloning: $RepoName"
    echo -e "====================================\n"
    
    # Test if the repository URL is accessible
    # Clean the URL to remove any potential malformed characters
    CleanRepoUrl=$(echo "$RepoCloneUrl" | sed 's/[?].*//g')
    
    echo "Testing access to repository: $CleanRepoUrl"
    git_response=$(git ls-remote --exit-code "$CleanRepoUrl" 2>&1)
    git_status=$?
    
    if [ $git_status -ne 0 ]; then
        echo "Error: Cannot access repository at $CleanRepoUrl"
        echo "Git error: $git_response"
        
        # Check if it's an authentication issue
        if [[ "$git_response" == *"Authentication failed"* || "$git_response" == *"401"* ]]; then
            echo "This appears to be an authentication issue. Your token may not have access to this repository."
            
            # Try with embedded credentials
            echo "Attempting to clone with embedded credentials..."
            RepoUrlWithAuth=$(echo "$CleanRepoUrl" | sed "s|https://|https://${GitHubUsername}:${GitHubToken}@|")
            git clone --progress "$RepoUrlWithAuth" "$DownloadPath/$RepoName"
            
            if [ $? -eq 0 ]; then
                echo "Successfully cloned $RepoName using embedded credentials"
                ((successful_clones++))
                continue
            else
                echo "Failed to clone with embedded credentials as well. Skipping this repository."
                ((failed_clones++))
            fi
        elif [[ "$git_response" == *"not found"* || "$git_response" == *"404"* ]]; then
            echo "The repository may not exist or you may not have permission to access it."
        elif [[ "$git_response" == *"Malformed input"* || "$git_response" == *"URL rejected"* ]]; then
            echo "The repository URL appears to be malformed."
        fi
        
        echo "Skipping this repository."
        ((failed_clones++))
        continue
    fi
    
    # Clone the repository with verbose output
    git clone --progress "$CleanRepoUrl" "$DownloadPath/$RepoName"
    
    # Check if clone was successful
    if [ $? -ne 0 ]; then
        echo "Error: Failed to clone $RepoName"
        echo "Skipping this repository."
        ((failed_clones++))
    else
        echo "Successfully cloned $RepoName"
        ((successful_clones++))
    fi
done

# Print summary statistics
echo -e "\n===================================="
echo "REPOSITORY DOWNLOAD SUMMARY"
echo "===================================="
echo "Total repositories found: $repo_count"
echo "Successfully cloned: $successful_clones"
echo "Already existing: $already_exists"
echo "Failed to clone: $failed_clones"
echo "===================================="
echo "All $RepoType ($Visibility) repositories have been processed."
echo "======================================"
