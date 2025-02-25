# Azure WebApp with Function Apps

A scalable Azure solution featuring an ASP.NET Core web application with Azure Function Apps for microservices architecture.

## Project Structure

```
azure-webapp/
├── src/
│   ├── WebApp/              # ASP.NET Core Web App
│   ├── RegistryFunction/    # Function App for service discovery
│   └── SampleFunction/      # Example Function App
├── tests/
│   ├── IntegrationTests/    # API and service integration tests
│   └── E2ETests/            # End-to-end browser tests with Playwright
├── infrastructure/          # Bicep templates
└── .github/
    └── workflows/          # GitHub Actions workflow definitions
```

## Components

1. **WebApp**: ASP.NET Core web application with authentication
2. **RegistryFunction**: Service discovery function app that maintains a registry of available functions
3. **SampleFunction**: Example function app demonstrating the architecture

## Prerequisites

- .NET 8.0 SDK
- Azure CLI
- Azure subscription
- GitHub account

## Local Development

1. Clone the repository
2. Open the solution in Visual Studio or VS Code
3. Set up local settings:

   For each Function App, create a `local.settings.json`:
   ```json
   {
     "IsEncrypted": false,
     "Values": {
       "AzureWebJobsStorage": "UseDevelopmentStorage=true",
       "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated"
     }
   }
   ```

4. Run the projects:
   - WebApp: `dotnet run --project src/WebApp/WebApp.csproj`
   - RegistryFunction: `dotnet run --project src/RegistryFunction/RegistryFunction.csproj`
   - SampleFunction: `dotnet run --project src/SampleFunction/SampleFunction.csproj`

## Testing

The solution includes both integration tests and end-to-end tests:

### Running Tests with the Automated Script

The easiest way to run tests is using the provided script, which handles starting all required services:

#### On Linux/macOS:

```bash
# Make the script executable (first time only)
chmod +x run-tests.sh

# Run integration tests only
./run-tests.sh

# Run both integration and E2E tests
./run-tests.sh --e2e
```

#### On Windows:

```cmd
# Run integration tests only
run-tests.bat

# Run both integration and E2E tests
run-tests.bat --e2e
```

The script will:
1. Start the Azure Storage Emulator (Azurite on Linux/macOS, Azure Storage Emulator on Windows)
2. Start the WebApp, Registry Function, and Sample Function
3. Verify all services are running with multiple retry attempts
4. Run the integration tests (and optionally E2E tests)
5. Clean up all processes when done

The scripts include robust service health checks with multiple retry attempts to ensure all services are properly started before running tests. This helps prevent "connection refused" errors that can occur when tests run before services are fully initialized.

### Running Tests Manually

If you prefer to run tests manually:

#### Running Integration Tests

1. Start the required services:
   ```bash
   # Start WebApp
   dotnet run --project src/WebApp/WebApp.csproj --urls=http://localhost:5000

   # Start Registry Function
   dotnet run --project src/RegistryFunction/RegistryFunction.csproj

   # Start Sample Function
   dotnet run --project src/SampleFunction/SampleFunction.csproj
   ```

2. Run the integration tests:
   ```bash
   cd tests/IntegrationTests
   dotnet test
   ```

#### Running E2E Tests

1. Install Playwright browsers (first time only):
   ```bash
   cd tests/E2ETests
   dotnet add package Microsoft.Playwright
   dotnet build
   pwsh -c "& dotnet tool install --global Microsoft.Playwright.CLI"
   pwsh -c "& playwright install"
   ```

2. Start the required services (same as for integration tests)

3. Run the E2E tests:
   ```bash
   cd tests/E2ETests
   dotnet test
   ```

## Deployment

The solution uses GitHub Actions for automated deployment:

1. Set up GitHub repository
2. Get your subscription ID and resource group:
   ```bash
   # List all subscriptions
   az account list --output table

   # Set and show your active subscription
   az account set --subscription <subscription-name>
   az account show --query id --output tsv

   # List resource groups in your subscription
   az group list --output table
   ```

3. Configure Azure credentials:
   ```bash
   az ad sp create-for-rbac --name "myapp-principal" --role contributor \
     --scopes /subscriptions/$(az account show --query id -o tsv)/resourceGroups/<your-resource-group> \
     --sdk-auth
   ```
4. Add the JSON output as a GitHub secret named `AZURE_CREDENTIALS`
5. Create the following environments in GitHub:
   - development
   - production
5. Push to main branch or create a pull request to trigger the workflow

### Infrastructure

The Bicep template (`infrastructure/main.bicep`) creates:
- App Service Plan
- Web App
- Function Apps
- Storage Account

## Adding New Function Apps

1. Create a new Function App project
2. Register it with the Registry Function
3. Update the infrastructure template
4. Update the GitHub Actions workflow

## Security

- Web App uses Azure AD authentication
- Function Apps use function-level authorization
- All communications over HTTPS
- Secrets managed through Azure Key Vault (to be implemented)

## Recent Improvements

### Deployment Enhancements
- Fixed resource naming to prevent creating new apps with each deployment
- Added resource existence check to update existing resources instead of creating new ones
- Implemented incremental deployment mode for Bicep templates

### Testing Infrastructure
- Added integration tests for all components:
  - Registry Function tests
  - Sample Function tests
  - Web App tests
- Added end-to-end tests using Playwright
- Integrated tests into the CI/CD pipeline:
  - Tests run pre-deployment in a simulated environment
  - Azure Functions Core Tools and Azurite storage emulator are used
  - Tests verify functionality before deployment to Azure
  - Pipeline continues even if tests fail (with warnings) to prevent blocking deployments

## Future Enhancements

- Add Azure Key Vault integration
- Implement Table Storage for function registry
- Add monitoring and logging
- Expand test coverage
