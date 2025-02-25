@echo off
REM Script to run integration tests locally on Windows

REM Set up variables
set WEBAPP_PORT=5000
set REGISTRY_PORT=7071
set SAMPLE_PORT=7072

REM Function to check if a port is in use and kill the process
call :kill_process_on_port %WEBAPP_PORT%
call :kill_process_on_port %REGISTRY_PORT%
call :kill_process_on_port %SAMPLE_PORT%

REM Ensure Azure Storage Emulator is running
echo Checking if Azure Storage Emulator is running...
where AzureStorageEmulator >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Starting Azure Storage Emulator...
    AzureStorageEmulator start
) else (
    echo Azure Storage Emulator not found. Please install it or use Azurite.
    echo You can install Azurite with: npm install -g azurite
    exit /b 1
)

REM Start WebApp
echo Starting WebApp on port %WEBAPP_PORT%...
start "WebApp" cmd /c "dotnet run --project src\WebApp\WebApp.csproj --urls=http://localhost:%WEBAPP_PORT%"

REM Start Registry Function
echo Starting Registry Function on port %REGISTRY_PORT%...
start "Registry Function" cmd /c "cd src\RegistryFunction && func start --port %REGISTRY_PORT% --no-interactive"

REM Start Sample Function
echo Starting Sample Function on port %SAMPLE_PORT%...
start "Sample Function" cmd /c "cd src\SampleFunction && func start --port %SAMPLE_PORT% --no-interactive"

REM Wait for services to start
echo Waiting for services to start...
timeout /t 20 /nobreak

REM Function to check if a service is running
:check_service
set url=%~1
set name=%~2
set max_attempts=%~3
set attempt=1

echo Checking if %name% is running...

:check_loop
curl -s -o nul -w "%%{http_code}" %url% 2>nul | findstr "200" >nul
if %ERRORLEVEL% EQU 0 (
    echo %name% is running
    set "service_ok=true"
    exit /b 0
) else (
    echo Attempt %attempt%: %name% is not responding yet, waiting...
    timeout /t 5 /nobreak >nul
    set /a attempt+=1
    if %attempt% LEQ %max_attempts% (
        goto :check_loop
    ) else (
        echo ERROR: %name% failed to start after %max_attempts% attempts
        set "service_ok=false"
        exit /b 1
    )
)

REM Check all services with retries
set "webapp_ok=false"
set "registry_ok=false"
set "sample_ok=false"

call :check_service "http://localhost:%WEBAPP_PORT%" "WebApp" 6
if %ERRORLEVEL% EQU 0 set "webapp_ok=true"

call :check_service "http://localhost:%REGISTRY_PORT%/api/ListFunctions" "Registry Function" 6
if %ERRORLEVEL% EQU 0 set "registry_ok=true"

call :check_service "http://localhost:%SAMPLE_PORT%/api/SampleEndpoint" "Sample Function" 6
if %ERRORLEVEL% EQU 0 set "sample_ok=true"

REM Check if all services are running
if "%webapp_ok%"=="true" if "%registry_ok%"=="true" if "%sample_ok%"=="true" (
    echo All services are running successfully
) else (
    echo WARNING: Not all services started successfully. Tests may fail.
    echo Status: WebApp (%webapp_ok%), Registry Function (%registry_ok%), Sample Function (%sample_ok%)
)

REM Run integration tests
echo Running integration tests...
cd tests\IntegrationTests
dotnet test --logger "console;verbosity=detailed"
set INTEGRATION_TEST_RESULT=%ERRORLEVEL%
cd ..\..

REM Run E2E tests if requested
if "%1"=="--e2e" (
    echo Running E2E tests...
    cd tests\E2ETests
    dotnet test --logger "console;verbosity=detailed"
    set E2E_TEST_RESULT=%ERRORLEVEL%
    cd ..\..
) else (
    echo Skipping E2E tests. Use --e2e flag to run them.
    set E2E_TEST_RESULT=0
)

REM Clean up
echo Cleaning up...
taskkill /FI "WINDOWTITLE eq WebApp*" /F
taskkill /FI "WINDOWTITLE eq Registry Function*" /F
taskkill /FI "WINDOWTITLE eq Sample Function*" /F

REM Report results
echo Test Results:
if %INTEGRATION_TEST_RESULT% EQU 0 (
    echo Integration Tests: PASSED
) else (
    echo Integration Tests: FAILED
)

if "%1"=="--e2e" (
    if %E2E_TEST_RESULT% EQU 0 (
        echo E2E Tests: PASSED
    ) else (
        echo E2E Tests: FAILED
    )
)

REM Exit with appropriate code
if %INTEGRATION_TEST_RESULT% EQU 0 (
    if "%1"=="--e2e" (
        if %E2E_TEST_RESULT% EQU 0 (
            echo All tests passed!
            exit /b 0
        ) else (
            echo Some tests failed!
            exit /b 1
        )
    ) else (
        echo All tests passed!
        exit /b 0
    )
) else (
    echo Some tests failed!
    exit /b 1
)

:kill_process_on_port
echo Killing process on port %1 if exists...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr /r ":%1 "') do (
    if not "%%a"=="0" (
        taskkill /PID %%a /F >nul 2>&1
    )
)
exit /b 0
