#!/bin/bash

echo -e "\n╔════════════════════════════════════════╗"
echo -e "║      GITHUB REPOSITORY DOWNLOADER      ║"
echo -e "╚════════════════════════════════════════╝"

# Prompt user for the download path
read -p "📂 Enter the directory path to store cloned repositories: " DownloadPath

# Display the entered path
echo -e "ℹ️  You entered: $DownloadPath"

# Convert Windows paths to Unix format if needed
if [[ "$DownloadPath" =~ ^[a-zA-Z]: ]]; then
    # This is a Windows path with drive letter
    # Convert backslashes to forward slashes
    DownloadPath=$(echo "$DownloadPath" | sed 's/\\/\//g')
    # Remove the colon after drive letter and prepend /mnt/
    drive_letter=$(echo "$DownloadPath" | cut -c1 | tr '[:upper:]' '[:lower:]')
    DownloadPath=$(echo "$DownloadPath" | sed "s/^$drive_letter:/\/mnt\/$drive_letter/")
    echo -e "🔄 Converted path: $DownloadPath"
fi

# Check if the path is valid
if [[ -z "$DownloadPath" ]]; then
    echo -e "❌ Error: Empty path provided. Exiting."
    exit 1
fi

# Ensure the folder exists, if not create it
if [ ! -d "$DownloadPath" ]; then
    echo -e "⏳ Directory does not exist. Creating it..."
    mkdir -p "$DownloadPath"

    # Check if directory creation was successful
    if [ ! -d "$DownloadPath" ]; then
        echo -e "❌ Error: Failed to create directory. Please check the path and permissions. Exiting."
        exit 1
    fi
    echo -e "✅ Directory created successfully."
fi

# Prompt user for GitHub username and personal access token
echo -e "\n╔════════════════════════════════════════╗"
echo -e "║           GITHUB CREDENTIALS           ║"
echo -e "╚════════════════════════════════════════╝"
read -p "👤 Enter your GitHub username: " GitHubUsername
read -s -p "🔑 Enter your GitHub personal access token: " GitHubToken
echo -e "\n"

# Prompt user for the repository type
echo -e "\n╔════════════════════════════════════════╗"
echo -e "║         REPOSITORY SELECTION           ║"
echo -e "╚════════════════════════════════════════╝"
read -p "📋 Enter the type of repositories to fetch (all, owner, member, forks): " RepoType

# Prompt user for repository visibility
read -p "🔒 Do you want to fetch public, private, or both repositories? (public/private/both): " Visibility

# Display requirements based on OS
echo -e "\n╔════════════════════════════════════════╗"
echo -e "║           REQUIREMENTS CHECK           ║"
echo -e "╚════════════════════════════════════════╝"
echo -e "This script requires the following tools:"
echo -e "✅ Git (required for all platforms)"
echo -e "✅ curl (required for all platforms)"

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo -e "✅ apt-get, yum, or dnf (for Linux)"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "✅ Homebrew (for macOS)"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
    echo -e "✅ Chocolatey (for Windows)"
    echo -e "✅ PowerShell (for Windows)"
fi

echo -e "✅ jq (will be installed if not present)"
echo -e "══════════════════════════════════════════"

# Set the API URL for fetching repositories
ApiUrl="https://api.github.com/user/repos?per_page=100&type=$RepoType"

# Check if jq is installed and install it if needed
if ! command -v jq &>/dev/null; then
    echo -e "\n╔═════════════════════════════════════╗"
    echo -e "║         JQ INSTALLATION REQUIRED    ║"
    echo -e "╚═════════════════════════════════════╝"
    echo -e "⏳ jq is not installed. Attempting to install it automatically..."

    # Detect operating system
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        echo -e "🐧 Linux detected. Installing jq..."
        if command -v apt-get &>/dev/null; then
            echo -e "⏳ Using apt-get to install jq..."
            sudo apt-get update && sudo apt-get install -y jq
            echo -e "✅ jq installed successfully via apt-get."
        elif command -v yum &>/dev/null; then
            echo -e "⏳ Using yum to install jq..."
            sudo yum install -y jq
            echo -e "✅ jq installed successfully via yum."
        elif command -v dnf &>/dev/null; then
            echo -e "⏳ Using dnf to install jq..."
            sudo dnf install -y jq
            echo -e "✅ jq installed successfully via dnf."
        else
            echo -e "❌ Could not determine package manager. Please install jq manually."
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        echo -e "🍎 macOS detected. Installing jq..."
        if command -v brew &>/dev/null; then
            echo -e "⏳ Using Homebrew to install jq..."
            brew install jq
            echo -e "✅ jq installed successfully via Homebrew."
        else
            echo -e "⏳ Homebrew not found. Installing Homebrew first..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            echo -e "✅ Homebrew installed. Now installing jq..."
            brew install jq
            echo -e "✅ jq installed successfully via Homebrew."
        fi
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
        # Windows (Git Bash, Cygwin, or native)
        echo -e "🪟 Windows detected. Installing jq..."
        if command -v choco &>/dev/null; then
            echo -e "⏳ Using Chocolatey to install jq..."
            choco install jq -y
            if ! command -v jq &>/dev/null; then
                echo -e "⚠️ Chocolatey command ran but jq is still not available."
                echo -e "⏳ Falling back to direct binary download..."
                # Proceed to direct download instead of exiting
                mkdir -p "$HOME/bin"
                curl -L -o "$HOME/bin/jq.exe" "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-win64.exe"
                chmod +x "$HOME/bin/jq.exe"
                export PATH="$HOME/bin:$PATH"
                echo -e "✅ jq has been downloaded to: $HOME/bin/jq.exe"
                echo -e "ℹ️  You may want to add this directory to your PATH permanently"
                echo -e "   by adding the following to your ~/.bashrc or ~/.bash_profile:"
                echo -e "   export PATH=\"\$HOME/bin:\$PATH\"\n"
            else
                echo -e "✅ jq installed successfully via Chocolatey."
            fi
        else
            echo -e "⏳ Chocolatey not found. Attempting to install Chocolatey..."
            echo -e "ℹ️  You may need to run PowerShell as Administrator for this to work."

            # Try to set execution policy temporarily for this process only
            choco_install_output=$(powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; try { [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')) } catch { Write-Host 'Failed to install Chocolatey automatically.' }" 2>&1)

            # Check if installation was successful or if Chocolatey was already installed
            if command -v choco &>/dev/null || [[ "$choco_install_output" == *"An existing Chocolatey installation was detected"* ]]; then
                echo -e "\n╔════════════════════════════════════════╗"
                echo -e "║         CHOCOLATEY DETECTED            ║"
                echo -e "╚════════════════════════════════════════╝"
                echo -e "✅ Chocolatey is already installed on this system"
                echo -e "⏳ Installing jq package using Chocolatey...\n"
                choco install jq -y
                
                # Check if jq was actually installed by Chocolatey
                if ! command -v jq &>/dev/null; then
                    echo -e "⚠️ Chocolatey command ran but jq is still not available."
                    echo -e "⏳ Falling back to direct binary download..."
                    # Proceed to direct download instead of exiting
                    mkdir -p "$HOME/bin"
                    curl -L -o "$HOME/bin/jq.exe" "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-win64.exe"
                    chmod +x "$HOME/bin/jq.exe"
                    export PATH="$HOME/bin:$PATH"
                    echo -e "✅ jq has been downloaded to: $HOME/bin/jq.exe"
                    echo -e "ℹ️  You may want to add this directory to your PATH permanently"
                    echo -e "   by adding the following to your ~/.bashrc or ~/.bash_profile:"
                    echo -e "   export PATH=\"\$HOME/bin:\$PATH\"\n"
                else
                    echo -e "✅ jq installed successfully via Chocolatey."
                fi
            else
                echo -e "\n╔════════════════════════════════════════╗"
                echo -e "║       CHOCOLATEY INSTALLATION FAILED   ║"
                echo -e "╚════════════════════════════════════════╝"
                echo -e "❌ Unable to install or detect Chocolatey package manager"
                echo -e "ℹ️  Proceeding with direct binary download...\n"
                
                # Directly download jq binary instead of showing options
                echo -e "⏳ Downloading jq binary directly..."
                mkdir -p "$HOME/bin"
                curl -L -o "$HOME/bin/jq.exe" "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-win64.exe"
                chmod +x "$HOME/bin/jq.exe"
                export PATH="$HOME/bin:$PATH"
                echo -e "✅ jq has been downloaded to: $HOME/bin/jq.exe"
                echo -e "ℹ️  You may want to add this directory to your PATH permanently"
                echo -e "   by adding the following to your ~/.bashrc or ~/.bash_profile:"
                echo -e "   export PATH=\"\$HOME/bin:\$PATH\"\n"
            fi
        fi
    else
        echo -e "❌ Unsupported operating system. Please install jq manually."
        exit 1
    fi

    # Verify installation
    if ! command -v jq &>/dev/null; then
        echo -e "❌ Failed to install jq. Please install it manually and try again."
        exit 1
    else
        echo -e "✅ jq has been successfully installed and is ready to use."
    fi
fi

# Fetch the list of repositories
echo -e "\n╔════════════════════════════════════════╗"
echo -e "║         FETCHING REPOSITORIES          ║"
echo -e "╚════════════════════════════════════════╝"
echo -e "⏳ Fetching $RepoType repositories from GitHub..."
Repos=$(curl -s -H "Authorization: token $GitHubToken" "$ApiUrl")

# Check if the API request was successful
if [[ $(echo "$Repos" | jq -r 'if type=="array" then "valid" elif .message then .message else "invalid" end') != "valid" ]]; then
    error_message=$(echo "$Repos" | jq -r '.message // "Unknown error"')
    echo -e "❌ Error accessing GitHub API: $error_message"
    echo -e "ℹ️  Please check your token and internet connection."
    exit 1
fi

# Count repositories that match the visibility filter
repo_count=$(echo "$Repos" | jq -r --arg Visibility "$Visibility" '
    if $Visibility == "both" then .[] 
    elif $Visibility == "public" then .[] | select(.private == false)
    elif $Visibility == "private" then .[] | select(.private == true)
    else empty end | .clone_url' | wc -l)

echo -e "\n╔════════════════════════════════════════╗"
echo -e "║         REPOSITORIES FOUND             ║"
echo -e "╚════════════════════════════════════════╝"
echo -e "🔍 Found $repo_count repositories matching your criteria."
echo -e "══════════════════════════════════════════"

if [[ $repo_count -eq 0 ]]; then
    echo -e "ℹ️  No repositories found with the specified criteria. Exiting."
    exit 0
fi

# Initialize counters for statistics
successful_clones=0
already_exists=0
failed_clones=0

echo -e "\n╔════════════════════════════════════════╗"
echo -e "║         PROCESSING REPOSITORIES        ║"
echo -e "╚════════════════════════════════════════╝"

# Filter repositories based on visibility case
echo "$Repos" | jq -r --arg Visibility "$Visibility" '
    if $Visibility == "both" then .[]
    elif $Visibility == "public" then .[] | select(.private == false)
    elif $Visibility == "private" then .[] | select(.private == true)
    else empty end | .clone_url' | while read -r RepoCloneUrl; do
    RepoName=$(basename -s .git "$RepoCloneUrl")

    # Check if repository already exists in the target directory
    if [ -d "$DownloadPath/$RepoName" ]; then
        echo -e "\n╔════════════════════════════════════════╗"
        echo -e "║         REPOSITORY EXISTS              ║"
        echo -e "╚════════════════════════════════════════╝"
        echo -e "📁 Repository already exists: $RepoName"

        # Check if it's a git repository
        if [ -d "$DownloadPath/$RepoName/.git" ]; then
            # Get the last commit date
            cd "$DownloadPath/$RepoName"
            last_commit_date=$(git log -1 --format="%ct" 2>/dev/null)
            current_date=$(date +%s)

            # Calculate days since last commit (86400 seconds in a day)
            days_since_last_commit=$(((current_date - last_commit_date) / 86400))

            echo -e "🕒 Last commit was $days_since_last_commit days ago."

            # If repository is older than 30 days, update it
            if [ $days_since_last_commit -gt 30 ]; then
                echo -e "⏳ Repository is outdated. Updating to latest version..."
                git_update_output=$(git pull 2>&1)
                git_update_status=$?

                if [ $git_update_status -eq 0 ]; then
                    echo -e "✅ Successfully updated $RepoName to the latest version."
                    ((successful_clones++))
                else
                    echo -e "❌ Failed to update repository: $git_update_output"
                    echo -e "ℹ️  You may need to resolve conflicts manually."
                    ((failed_clones++))
                fi
            else
                echo -e "✅ Repository is recent. Skipping update."
            fi

            cd - >/dev/null
        else
            echo -e "⚠️ Folder exists but is not a git repository."
        fi

        echo -e "══════════════════════════════════════════"
        ((already_exists++))
        continue
    fi

    echo -e "\n╔════════════════════════════════════════╗"
    echo -e "║         CLONING REPOSITORY             ║"
    echo -e "╚════════════════════════════════════════╝"
    echo -e "📥 Cloning: $RepoName"
    echo -e "══════════════════════════════════════════"

    # Test if the repository URL is accessible
    # Clean the URL to remove any potential malformed characters
    CleanRepoUrl=$(echo "$RepoCloneUrl" | sed 's/[?].*//g')

    echo -e "🔍 Testing access to repository: $CleanRepoUrl"
    git_response=$(git ls-remote --exit-code "$CleanRepoUrl" 2>&1)
    git_status=$?

    if [ $git_status -ne 0 ]; then
        echo -e "❌ Error: Cannot access repository at $CleanRepoUrl"
        echo -e "🛑 Git error: $git_response"

        # Check if it's an authentication issue
        if [[ "$git_response" == *"Authentication failed"* || "$git_response" == *"401"* ]]; then
            echo -e "🔐 This appears to be an authentication issue. Your token may not have access to this repository."

            # Try with embedded credentials
            echo -e "⏳ Attempting to clone with embedded credentials..."
            RepoUrlWithAuth=$(echo "$CleanRepoUrl" | sed "s|https://|https://${GitHubUsername}:${GitHubToken}@|")
            git clone --progress "$RepoUrlWithAuth" "$DownloadPath/$RepoName"

            if [ $? -eq 0 ]; then
                echo -e "✅ Successfully cloned $RepoName using embedded credentials"
                ((successful_clones++))
                continue
            else
                echo -e "❌ Failed to clone with embedded credentials as well. Skipping this repository."
                ((failed_clones++))
            fi
        elif [[ "$git_response" == *"not found"* || "$git_response" == *"404"* ]]; then
            echo -e "🔍 The repository may not exist or you may not have permission to access it."
        elif [[ "$git_response" == *"Malformed input"* || "$git_response" == *"URL rejected"* ]]; then
            echo -e "⚠️ The repository URL appears to be malformed."
        fi

        echo -e "⏭️ Skipping this repository."
        ((failed_clones++))
        continue
    fi

    # Clone the repository with verbose output
    echo -e "⏳ Cloning repository..."
    git clone --progress "$CleanRepoUrl" "$DownloadPath/$RepoName"

    # Check if clone was successful
    if [ $? -ne 0 ]; then
        echo -e "❌ Error: Failed to clone $RepoName"
        echo -e "⏭️ Skipping this repository."
        ((failed_clones++))
    else
        echo -e "✅ Successfully cloned $RepoName"
        ((successful_clones++))
    fi
done

# Print summary statistics
echo -e "\n╔════════════════════════════════════════╗"
echo -e "║       REPOSITORY DOWNLOAD SUMMARY      ║"
echo -e "╚══════════════════════════════════════════╝"
echo -e "📊 Total repositories found: $repo_count"
echo -e "✅ Successfully cloned: $successful_clones"
echo -e "📁 Already existing: $already_exists"
echo -e "❌ Failed to clone: $failed_clones"
echo -e "══════════════════════════════════════════"
echo -e "🎉 All $RepoType ($Visibility) repositories have been processed."
echo -e "══════════════════════════════════════════"
