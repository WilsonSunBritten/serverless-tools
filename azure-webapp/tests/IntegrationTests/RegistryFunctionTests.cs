using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Xunit;

namespace IntegrationTests;

public class RegistryFunctionTests
{
    private readonly HttpClient _client;
    private readonly IConfiguration _configuration;
    private readonly string _registryFunctionBaseUrl;

    public RegistryFunctionTests()
    {
        // Load configuration
        _configuration = new ConfigurationBuilder()
            .AddJsonFile("appsettings.json")
            .AddJsonFile("appsettings.Development.json", optional: true)
            .AddEnvironmentVariables()
            .Build();

        _registryFunctionBaseUrl = _configuration["TestSettings:RegistryFunctionBaseUrl"] ?? "http://localhost:7071";
        _client = new HttpClient();
    }

    [Fact]
    public async Task ListFunctions_ReturnsValidResponse()
    {
        // Arrange
        var url = $"{_registryFunctionBaseUrl}/api/ListFunctions";

        // Act
        var response = await _client.GetAsync(url);

        // Assert
        Assert.True(response.IsSuccessStatusCode, $"Failed to get response from {url}. Status: {response.StatusCode}");

        var content = await response.Content.ReadAsStringAsync();
        var functions = JsonSerializer.Deserialize<FunctionInfo[]>(content, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

        Assert.NotNull(functions);
        Assert.NotEmpty(functions);
        Assert.Contains(functions, f => f.Name == "SampleFunction");
    }

    [Fact]
    public async Task RegisterFunction_ReturnsSuccessMessage()
    {
        // Arrange
        var url = $"{_registryFunctionBaseUrl}/api/RegisterFunction";
        var functionInfo = new FunctionInfo
        {
            Name = "TestFunction",
            Url = "http://localhost:7073"
        };

        // Act
        var response = await _client.PostAsJsonAsync(url, functionInfo);

        // Assert
        Assert.True(response.IsSuccessStatusCode, $"Failed to register function. Status: {response.StatusCode}");

        var content = await response.Content.ReadAsStringAsync();
        var result = JsonSerializer.Deserialize<RegisterResponse>(content, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

        Assert.NotNull(result);
        Assert.Contains("success", result.Message.ToLower());
    }

    // Helper classes to deserialize responses
    private class FunctionInfo
    {
        public string Name { get; set; } = string.Empty;
        public string Url { get; set; } = string.Empty;
    }

    private class RegisterResponse
    {
        public string Message { get; set; } = string.Empty;
    }
}
