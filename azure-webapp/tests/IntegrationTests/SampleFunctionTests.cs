using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Xunit;

namespace IntegrationTests;

public class SampleFunctionTests
{
    private readonly HttpClient _client;
    private readonly IConfiguration _configuration;
    private readonly string _sampleFunctionBaseUrl;

    public SampleFunctionTests()
    {
        // Load configuration
        _configuration = new ConfigurationBuilder()
            .AddJsonFile("appsettings.json")
            .AddJsonFile("appsettings.Development.json", optional: true)
            .AddEnvironmentVariables()
            .Build();

        _sampleFunctionBaseUrl = _configuration["TestSettings:SampleFunctionBaseUrl"] ?? "http://localhost:7072";
        _client = new HttpClient();
    }

    [Fact]
    public async Task SampleEndpoint_ReturnsValidResponse()
    {
        // Arrange
        var url = $"{_sampleFunctionBaseUrl}/api/SampleEndpoint";

        // Act
        var response = await _client.GetAsync(url);

        // Assert
        Assert.True(response.IsSuccessStatusCode, $"Failed to get response from {url}. Status: {response.StatusCode}");

        var content = await response.Content.ReadAsStringAsync();
        var result = JsonSerializer.Deserialize<SampleResponse>(content, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

        Assert.NotNull(result);
        Assert.Equal("Hello from Sample Function!", result.Message);
        Assert.NotEqual(default, result.Timestamp);
    }

    // Helper class to deserialize response
    private class SampleResponse
    {
        public string Message { get; set; } = string.Empty;
        public DateTime Timestamp { get; set; }
    }
}
