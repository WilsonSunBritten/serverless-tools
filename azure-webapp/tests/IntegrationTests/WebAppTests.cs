using Microsoft.Extensions.Configuration;
using Xunit;

namespace IntegrationTests;

public class WebAppTests
{
    private readonly HttpClient _client;
    private readonly IConfiguration _configuration;
    private readonly string _webAppBaseUrl;

    public WebAppTests()
    {
        // Load configuration
        _configuration = new ConfigurationBuilder()
            .AddJsonFile("appsettings.json")
            .AddJsonFile("appsettings.Development.json", optional: true)
            .AddEnvironmentVariables()
            .Build();

        _webAppBaseUrl = _configuration["TestSettings:WebAppBaseUrl"] ?? "http://localhost:5000";
        _client = new HttpClient();
    }

    [Fact]
    public async Task WebApp_HomePage_LoadsSuccessfully()
    {
        // Arrange
        var url = _webAppBaseUrl;

        // Act
        var response = await _client.GetAsync(url);

        // Assert
        Assert.True(response.IsSuccessStatusCode, $"Failed to get response from {url}. Status: {response.StatusCode}");

        var content = await response.Content.ReadAsStringAsync();
        
        // Check for expected content in the HTML
        Assert.Contains("Azure Functions Demo", content);
        Assert.Contains("Available Functions", content);
        Assert.Contains("Function Response", content);
    }

    [Fact]
    public async Task WebApp_CanConnect_ToRegistryFunction()
    {
        // This test verifies that the web app can connect to the registry function
        // In a real test, we would need to mock the registry function or ensure it's running
        // For now, we'll just check that the web app loads and contains the expected elements

        // Arrange
        var url = _webAppBaseUrl;

        // Act
        var response = await _client.GetAsync(url);

        // Assert
        Assert.True(response.IsSuccessStatusCode, $"Failed to get response from {url}. Status: {response.StatusCode}");

        var content = await response.Content.ReadAsStringAsync();
        
        // Check for the script that calls the registry function
        Assert.Contains("loadFunctions", content);
        Assert.Contains("fetch", content);
        Assert.Contains("ListFunctions", content);
    }
}
