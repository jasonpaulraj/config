# Curl Test Script with Enhanced Error Handling

This repository includes two bash scripts for testing `curl` requests with enhanced error handling and dynamic parameters.

## Scripts

1. **test_curl.sh** - A basic script that takes fixed parameters for a single endpoint.
2. **dynamic_curl.sh** - A flexible script that accepts dynamic headers, data fields, and URL.

## Usage

### 1. test_curl.sh

This script requires the following arguments:

- `hashkey`: The hash key for authorization.
- `email`: The email address for the request.
- `password`: The password for the request.
- `url`: The endpoint URL.

**Example:**

```bash
./test_curl.sh "hashkey_value" "email@example.com" "P@ssword123" "http://example.com/api/login"
```

```bash
./dynamic_curl.sh -H "hashkey: 1b1abad9f6680bc8ac44c3f61218d89070" -H "Content-Type: application/json" -d "email=jason@techiegoose.com" -d "password=P@ssword123" http://example.com/api/user/login
```

## Error Handling

Both scripts handle a range of potential errors, including network connectivity issues, unreachable URLs, and HTTP response errors.

### Network Issues:

- curl exit code 6: Could not resolve host. Check the URL or your network connection.
- curl exit code 7: Failed to connect to the host. The server might be down or the URL might be incorrect.
- curl exit code 28: Connection timed out. The server may be unreachable, or the network is slow.
- Other exit codes indicate other network issues or unsupported protocols.
  HTTP Response Errors:

- 4xx (Client Errors): Shows an error message and response body for client-related issues (e.g., 404 Not Found, 401 Unauthorized).
- 5xx (Server Errors): Shows an error message and response body for server-related issues (e.g., 500 Internal Server Error).
- 2xx (Success): Displays the response body when the request is successful.

## Prerequisites

### Curl: Ensure that curl is installed on your system. You can check by running:

bash

```bash
curl --version
```

### Permissions: Make sure the scripts are executable by setting appropriate permissions:

```bash
chmod +x test_curl.sh dynamic_curl.sh
```

## Compatibility

The scripts are compatible with Unix-like operating systems (Linux, macOS) and can be executed in Windows environments using WSL (Windows Subsystem for Linux) or Git Bash.

### Notes

- Both scripts will pause and wait for user input before closing, which allows you to see any error messages before exiting.
- The dynamic script (dynamic_curl.sh) is versatile for testing various endpoints and parameters, making it useful for APIs with changing headers and payloads.
