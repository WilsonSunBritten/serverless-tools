# Azure WebApp with Function Apps

A scalable Azure solution featuring an ASP.NET Core web application with Azure Function Apps for microservices architecture.

## Project Structure

```
azure-webapp/
├── src/
│   ├── WebApp/              # ASP.NET Core Web App
│   ├── RegistryFunction/    # Function App for service discovery
│   └── SampleFunction/      # Example Function App
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

## Deployment

The solution uses GitHub Actions for automated deployment:

1. Set up GitHub repository
2. Configure Azure credentials:
   ```bash
   az ad sp create-for-rbac --name "myapp-principal" --role contributor \
     --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group} \
     --sdk-auth
   ```
3. Add the JSON output as a GitHub secret named `AZURE_CREDENTIALS`
4. Create the following environments in GitHub:
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

## Future Enhancements

- Add Azure Key Vault integration
- Implement Table Storage for function registry
- Add monitoring and logging
- Implement staging environment
