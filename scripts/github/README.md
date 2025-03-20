# GitHub Repository Downloader

This script allows you to download all repositories of a specific type (e.g., forks, owner, member) from your GitHub account. It supports filtering by visibility (public, private, or both) and works on macOS, Linux, and Windows (via WSL).

## Prerequisites
- Git installed on your system
- `curl` and `jq` installed (for API requests and JSON parsing)
- A GitHub Personal Access Token with repository access

## Installation
1. Download the script or clone this repository.
2. Make the script executable:
   ```bash
   chmod +x download_repos.sh
   ```

## Usage
Run the script using the following command:
```bash
./download_repos.sh
```

The script will prompt for:
- Your GitHub username
- Your GitHub personal access token
- The type of repositories to fetch (all, owner, member, forks)
- The visibility of repositories (public, private, both)
- The directory path where repositories should be downloaded

## Example Output
```
Enter your GitHub username: johndoe
Enter your GitHub personal access token: ********
Enter the type of repositories to fetch (all, owner, member, forks): forks
Do you want to fetch public, private, or both repositories? (public/private/both): both
Enter the directory path to store cloned repositories: ~/github-repos
Fetching forks repositories...

====================================
Cloning: my-forked-repo
====================================

All forks (both) repositories have been downloaded to ~/github-repos
====================================
```

## Notes
- The script ensures the target directory exists before cloning repositories.
- Your GitHub token is kept secure by not displaying it in plain text.
- If you do not have `jq` installed, you can install it using:
  - macOS: `brew install jq`
  - Linux: `sudo apt-get install jq` or `sudo yum install jq`

## License
This script is open-source and available under the MIT License.

