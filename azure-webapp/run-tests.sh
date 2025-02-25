#!/bin/bash
# Script to run integration tests locally

# Set up variables
WEBAPP_PORT=5000
REGISTRY_PORT=7071
SAMPLE_PORT=7072
TEST_DIR="$(pwd)/tests"

# Function to check if a port is in use
is_port_in_use() {
  lsof -i:$1 >/dev/null 2>&1
  return $?
}

# Function to kill processes using a specific port
kill_process_on_port() {
  echo "Killing process on port $1 if exists..."
  lsof -ti:$1 | xargs kill -9 2>/dev/null || true
}

# Clean up any existing processes
kill_process_on_port $WEBAPP_PORT
kill_process_on_port $REGISTRY_PORT
kill_process_on_port $SAMPLE_PORT

# Ensure Azure Storage Emulator is running (Azurite or Azure Storage Emulator)
echo "Checking if Azure Storage Emulator is running..."
if command -v azurite &> /dev/null; then
  # Check if Azurite is already running
  if ! pgrep -f "azurite" > /dev/null; then
    echo "Starting Azurite..."
    mkdir -p azurite
    azurite --silent --location azurite --debug azurite/debug.log &
    AZURITE_PID=$!
    echo "Azurite started with PID: $AZURITE_PID"
    sleep 5
  else
    echo "Azurite is already running"
  fi
else
  echo "Azurite not found. Please install it with: npm install -g azurite"
  echo "Or use the Azure Storage Emulator on Windows"
  exit 1
fi

# Start WebApp
echo "Starting WebApp on port $WEBAPP_PORT..."
dotnet run --project src/WebApp/WebApp.csproj --urls=http://localhost:$WEBAPP_PORT &
WEBAPP_PID=$!
echo "WebApp started with PID: $WEBAPP_PID"

# Start Registry Function
echo "Starting Registry Function on port $REGISTRY_PORT..."
cd src/RegistryFunction
func start --port $REGISTRY_PORT --no-interactive &
REGISTRY_PID=$!
cd ../..
echo "Registry Function started with PID: $REGISTRY_PID"

# Start Sample Function
echo "Starting Sample Function on port $SAMPLE_PORT..."
cd src/SampleFunction
func start --port $SAMPLE_PORT --no-interactive &
SAMPLE_PID=$!
cd ../..
echo "Sample Function started with PID: $SAMPLE_PID"

# Wait for services to start
echo "Waiting for services to start..."
sleep 20  # Increased wait time

# Function to check if a service is running
check_service() {
  local url=$1
  local name=$2
  local max_attempts=$3
  local attempt=1
  
  echo "Checking if $name is running..."
  
  while [ $attempt -le $max_attempts ]; do
    if curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null | grep -q "200"; then
      echo "$name is running"
      return 0
    else
      echo "Attempt $attempt: $name is not responding yet, waiting..."
      sleep 5
      attempt=$((attempt + 1))
    fi
  done
  
  echo "ERROR: $name failed to start after $max_attempts attempts"
  return 1
}

# Check all services with retries
webapp_ok=false
registry_ok=false
sample_ok=false

check_service "http://localhost:$WEBAPP_PORT" "WebApp" 6
if [ $? -eq 0 ]; then
  webapp_ok=true
fi

check_service "http://localhost:$REGISTRY_PORT/api/ListFunctions" "Registry Function" 6
if [ $? -eq 0 ]; then
  registry_ok=true
fi

check_service "http://localhost:$SAMPLE_PORT/api/SampleEndpoint" "Sample Function" 6
if [ $? -eq 0 ]; then
  sample_ok=true
fi

# Check if all services are running
if [ "$webapp_ok" = true ] && [ "$registry_ok" = true ] && [ "$sample_ok" = true ]; then
  echo "All services are running successfully"
else
  echo "WARNING: Not all services started successfully. Tests may fail."
  echo "Status: WebApp ($webapp_ok), Registry Function ($registry_ok), Sample Function ($sample_ok)"
fi

# Run integration tests
echo "Running integration tests..."
cd tests/IntegrationTests
dotnet test --logger "console;verbosity=detailed"
INTEGRATION_TEST_RESULT=$?
cd ../..

# Run E2E tests if requested
if [ "$1" == "--e2e" ]; then
  echo "Running E2E tests..."
  cd tests/E2ETests
  dotnet test --logger "console;verbosity=detailed"
  E2E_TEST_RESULT=$?
  cd ../..
else
  echo "Skipping E2E tests. Use --e2e flag to run them."
  E2E_TEST_RESULT=0
fi

# Clean up
echo "Cleaning up..."
kill $WEBAPP_PID
kill $REGISTRY_PID
kill $SAMPLE_PID

# Only kill Azurite if we started it
if [ ! -z "$AZURITE_PID" ]; then
  kill $AZURITE_PID
fi

# Report results
echo "Test Results:"
echo "Integration Tests: $([ $INTEGRATION_TEST_RESULT -eq 0 ] && echo 'PASSED' || echo 'FAILED')"
if [ "$1" == "--e2e" ]; then
  echo "E2E Tests: $([ $E2E_TEST_RESULT -eq 0 ] && echo 'PASSED' || echo 'FAILED')"
fi

# Exit with appropriate code
if [ $INTEGRATION_TEST_RESULT -eq 0 ] && ([ "$1" != "--e2e" ] || [ $E2E_TEST_RESULT -eq 0 ]); then
  echo "All tests passed!"
  exit 0
else
  echo "Some tests failed!"
  exit 1
fi
