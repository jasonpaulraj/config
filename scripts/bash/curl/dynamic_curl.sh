#!/bin/bash

# Usage: ./dynamic_curl.sh -H "header1:value1" -H "header2:value2" -d "key1=value1" -d "key2=value2" <url>

# Initialize arrays for headers and data fields
declare -a HEADERS
declare -a DATA

# Loop through arguments and classify them
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -H|--header)  # Header flag
            HEADERS+=("$2")
            shift 2
            ;;
        -d|--data)  # Data flag
            DATA+=("$2")
            shift 2
            ;;
        *)  # Assume the last argument is the URL
            URL=$1
            shift
            ;;
    esac
done

# Check if URL is provided
if [ -z "$URL" ]; then
    echo "Error: No URL provided."
    echo "Usage: $0 -H \"header:value\" -d \"key=value\" <url>"
    exit 1
fi

# Build curl command dynamically and capture response
CURL_COMMAND="curl -s -w \"%{http_code}\" -o /tmp/curl_response_output -X POST "

# Append headers to the command
for HEADER in "${HEADERS[@]}"; do
    CURL_COMMAND+="-H \"$HEADER\" "
done

# Append data fields to the command
for FIELD in "${DATA[@]}"; do
    CURL_COMMAND+="-d \"$FIELD\" "
done

# Append URL to the command
CURL_COMMAND+="$URL"

# Execute the command and capture response
RESPONSE=$(eval $CURL_COMMAND)
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
