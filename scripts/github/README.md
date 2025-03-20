# GitHub Repository Downloader

This script allows you to download all repositories of a specific type (e.g., forks, owner, member) from your GitHub account. It supports filtering by visibility (public, private, or both) and works on macOS, Linux, and Windows (via Git Bash or WSL).

## Features

- Download repositories by type (all, owner, member, forks)
- Filter by visibility (public, private, or both)
- Automatic installation of required dependencies
- Cross-platform support (Windows, macOS, Linux)
- Automatic path conversion for Windows paths
- Repository tracking to avoid unnecessary downloads
- Smart update system for existing repositories
- Detailed progress information with visual indicators
- Comprehensive error handling and recovery options
- Summary statistics after completion

## Prerequisites

- Git installed on your system
- `curl` installed (for API requests)
- A GitHub Personal Access Token with repository access
- `jq` will be automatically installed if not present

## Installation

1. Download the script or clone this repository.
2. Make the script executable (Linux/macOS):
   ```bash
   chmod +x download_repo.sh
   ```

## Usage

Run the script using the following command:

```bash
./download_repo.sh
```

For Windows users with Git Bash:

```bash
bash download_repo.sh
```

The script will prompt for:

- The directory path where repositories should be downloaded
- Your GitHub username
- Your GitHub personal access token
- The type of repositories to fetch (all, owner, member, forks)
- The visibility of repositories (public, private, both)

## Example Output

```plaintext
╔════════════════════════════════════════╗
║      GITHUB REPOSITORY DOWNLOADER      ║
╚════════════════════════════════════════╝

📂 Enter the directory path to store cloned repositories: e:\github-repos
ℹ️  You entered: e:\github-repos
🔄 Converted path: /mnt/e/github-repos
✅ Directory created successfully.

╔════════════════════════════════════════╗
║           GITHUB CREDENTIALS           ║
╚════════════════════════════════════════╝
👤 Enter your GitHub username: johndoe
🔑 Enter your GitHub personal access token: ********

╔════════════════════════════════════════╗
║         REPOSITORY SELECTION           ║
╚════════════════════════════════════════╝
📋 Enter the type of repositories to fetch (all, owner, member, forks): owner
🔒 Do you want to fetch public, private, or both repositories? (public/private/both): both

╔════════════════════════════════════════╗
║         FETCHING REPOSITORIES          ║
╚════════════════════════════════════════╝
⏳ Fetching owner repositories from GitHub...

╔════════════════════════════════════════╗
║         REPOSITORIES FOUND             ║
╚════════════════════════════════════════╝
🔍 Found 15 repositories matching your criteria.
══════════════════════════════════════════

╔════════════════════════════════════════╗
║         CLONING REPOSITORY             ║
╚════════════════════════════════════════╝
📥 Cloning: my-awesome-project
══════════════════════════════════════════
✅ Successfully cloned my-awesome-project

╔════════════════════════════════════════╗
║         REPOSITORY EXISTS              ║
╚════════════════════════════════════════╝
📁 Repository already exists: another-project
⏳ Re-downloading repository...
✅ Successfully re-downloaded another-project

╔════════════════════════════════════════╗
║       REPOSITORY DOWNLOAD SUMMARY      ║
╚════════════════════════════════════════╝
📊 Total repositories found: 15
✅ Successfully cloned: 10
📁 Already existing: 5
❌ Failed to clone: 0
══════════════════════════════════════════
🎉 All owner (both) repositories have been processed.
══════════════════════════════════════════
```

## Repository Tracking

The script creates a tracking file ( .repo_tracking.txt ) in the download directory to keep track of when repositories were last downloaded. This helps to:

- Avoid unnecessary downloads of repositories that were recently updated
- Ensure repositories are updated if they haven't been downloaded in more than a day
- Maintain a record of all downloaded repositories

## Automatic Dependency Installation

If jq is not installed on your system, the script will attempt to install it automatically:

- On Linux: Using apt-get, yum, or dnf
- On macOS: Using Homebrew
- On Windows: Using Chocolatey or direct binary download

## Error Handling

The script includes comprehensive error handling for:

- Authentication issues
- Network connectivity problems
- Repository access permissions
- Path conversion and validation
- Dependency installation failures

## Notes

- The script ensures the target directory exists before cloning repositories.
- Your GitHub token is kept secure by not displaying it in plain text.
- Windows paths are automatically converted to the appropriate format for Git Bash.
- The script provides detailed visual feedback with emoji indicators for better readability.

## License

This script is open-source and available under the MIT License.
