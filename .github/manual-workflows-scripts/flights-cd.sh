#!/bin/bash

# Function to check the status code and exit if not zero
check_status() {
  if [ $1 -ne 0 ]; then
    echo "Error: $2"
    exit 1
  fi
}

echo "Step 1: Checkout (Skipped for manual script)"

echo "Step 2: Check Kong Gateway is up"
deck gateway ping --kong-addr http://localhost:8001
check_status $? "Kong Gateway is not up"

echo "Step 3: Generate Kong declarative configuration from Spec"
deck file openapi2kong --spec flight-data/flights/flights-openapi.yaml --output-file flight-data/flights/kong/.generated/kong.yaml
check_status $? "Generating Kong declarative configuration failed"

echo "Step 4: Add plugin configuration"
deck file merge flight-data/flights/kong/.generated/kong.yaml flight-data/flights/kong/plugins/*.yaml --output-file flight-data/flights/kong/.generated/kong.yaml
check_status $? "Adding plugin configuration failed"

echo "Step 5: Add tags to Kong configuration"
cat flight-data/flights/kong/.generated/kong.yaml | deck file add-tags --selector "$.services[*]" --selector "$.services[*].routes[*]" flights-team --output-file flight-data/flights/kong/.generated/kong.yaml
check_status $? "Adding tags to Kong configuration failed"

echo "Step 6: Patch service for test environment"
cat flight-data/flights/kong/.generated/kong.yaml | deck file patch flight-data/flights/kong/patches.yaml --output-file flight-data/flights/kong/.generated/kong.yaml
check_status $? "Patching service for test environment failed"

echo "Step 7: Validate Kong declarative configuration"
deck gateway validate flight-data/flights/kong/.generated/kong.yaml
check_status $? "Validating Kong declarative configuration failed"

echo "Step 8: Backup current Kong Configuration"
deck gateway dump --output-file flight-data/flights/kong/.generated/backup.yaml
check_status $? "Backing up current Kong configuration failed"

echo "Step 9: Check changes against current Kong configuration"
deck gateway diff flight-data/flights/kong/.generated/kong.yaml
check_status $? "Checking changes against current Kong configuration failed"

echo "Step 10: Deploy declarative config"
deck gateway sync flight-data/flights/kong/.generated/kong.yaml
check_status $? "Deploying declarative config failed"

sleep 5
echo "Step 11: Run Integration Tests"
for test_script in flight-data/flights/tests/*.sh; do
  echo "Running $test_script"
  bash "$test_script"
  if [ $? -ne 0 ]; then
    echo "Test $test_script failed"
    exit 1
  fi
done

echo "Step 12: Publish Spec to Dev Portal"
cd flight-data/flights
http --check-status --ignore-stdin PUT :8001/default/files/specs/flights-openapi.yaml contents=@flights-openapi.yaml
check_status $? "Publishing Spec to Dev Portal failed"

echo "All steps completed successfully"