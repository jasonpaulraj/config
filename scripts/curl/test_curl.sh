#!/bin/bash

# Usage: ./test_curl.sh <hashkey> <email> <password> <url>

# Check if the correct number of arguments is provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <hashkey> <email> <password> <url>"
    exit 1
fi

# Assign input arguments to variables
HASHKEY=$1
EMAIL=$2
PASSWORD=$3
URL=$4

# Make the curl POST request and capture the response
RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/curl_response_output -X POST \
    -H "hashkey: $HASHKEY" \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"$EMAIL\", \"password\": \"$PASSWORD\"}" \
    "$URL")
CURL_EXIT_STATUS=$?

# Read the response body and HTTP status code
BODY=$(cat /tmp/curl_response_output)
HTTP_STATUS="${RESPONSE: -3}"

# Check curl exit status for network errors
if [ "$CURL_EXIT_STATUS" -ne 0 ]; then
    case $CURL_EXIT_STATUS in
        6) echo "Error: Could not resolve host. Check the URL or your network connection.";;
        7) echo "Error: Failed to connect to the host.";;
        28) echo "Error: Connection timed out. The server may be unreachable.";;
        *) echo "Error: Network issue or unsupported protocol.";;
    esac
    exit $CURL_EXIT_STATUS
fi

# Handle HTTP status codes for application-level errors
if [ "$HTTP_STATUS" -ge 400 ]; then
    echo "HTTP Error $HTTP_STATUS"
    echo "Response: $BODY"
elif [ "$HTTP_STATUS" -ge 200 ] && [ "$HTTP_STATUS" -lt 300 ]; then
    echo "Success: $BODY"
else
    echo "Unexpected HTTP status code $HTTP_STATUS"
fi

# Pause to keep the terminal open
echo "Press any key to exit..."
read -n 1 -s
