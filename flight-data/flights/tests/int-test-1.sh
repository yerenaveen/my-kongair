#!/bin/bash

# URL to make the GET request

# Make the GET request using httpie and capture the output
response=$(http --headers GET http://localhost:8000/flights)

# Check if the status code is 200
status_code=$(echo "$response" | grep "HTTP/1.1 200 OK")

# Check if the x-flights-provider header is kong-air
provider_header=$(echo "$response" | grep "x-flights-provider: kong-air")

# Verify both conditions
if [[ -n "$status_code" && -n "$provider_header" ]]; then
    echo "Success: Status code is 200 and x-flights-provider is kong-air."
else
    echo "Failure: Either the status code is not 200 or x-flights-provider is not kong-air."
fi
