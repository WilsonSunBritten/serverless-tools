using Microsoft.Extensions.Configuration;
using Microsoft.Playwright;
using System.Text.RegularExpressions;
using Xunit;

namespace E2ETests;

public class WebAppE2ETests : IAsyncLifetime
{
    private IPlaywright _playwright;
    private IBrowser _browser;
    private IConfiguration _configuration;
    private string _webAppBaseUrl;
    private bool _headless;
    private int _slowMo;
    private int _timeout;

    public async Task InitializeAsync()
    {
        // Load configuration
        _configuration = new ConfigurationBuilder()
            .AddJsonFile("appsettings.json")
            .AddJsonFile("appsettings.Development.json", optional: true)
            .AddEnvironmentVariables()
            .Build();

        _webAppBaseUrl = _configuration["TestSettings:WebAppBaseUrl"] ?? "http://localhost:5000";
        _headless = bool.Parse(_configuration["TestSettings:Headless"] ?? "true");
        _slowMo = int.Parse(_configuration["TestSettings:SlowMo"] ?? "50");
        _timeout = int.Parse(_configuration["TestSettings:Timeout"] ?? "30000");

        // Initialize Playwright
        _playwright = await Playwright.CreateAsync();
        _browser = await _playwright.Chromium.LaunchAsync(new BrowserTypeLaunchOptions
        {
            Headless = _headless,
            SlowMo = _slowMo,
        });
    }

    public async Task DisposeAsync()
    {
        await _browser.DisposeAsync();
        _playwright.Dispose();
    }

    [Fact]
    public async Task WebApp_LoadsAndDisplaysFunctions()
    {
        // Arrange
        var page = await _browser.NewPageAsync(new BrowserNewPageOptions
        {
            BaseURL = _webAppBaseUrl,
            ViewportSize = new ViewportSize { Width = 1280, Height = 720 }
        });

        // Act
        await page.GotoAsync("/", new PageGotoOptions { Timeout = _timeout });
        
        // Wait for functions to load (this might take some time if connecting to real functions)
        await page.WaitForSelectorAsync("#functionsList:not(:has-text('Loading functions...'))", 
            new PageWaitForSelectorOptions { Timeout = _timeout });

        // Assert
        var functionsListContent = await page.TextContentAsync("#functionsList");
        Assert.NotNull(functionsListContent);
        Assert.DoesNotContain("Loading functions...", functionsListContent);
        
        // Check if there's at least one function button
        var functionButtons = await page.QuerySelectorAllAsync("#functionsList button");
        Assert.NotEmpty(functionButtons);

        // Check if there's a SampleFunction button
        var hasSampleFunction = await page.IsVisibleAsync("button:has-text('SampleFunction')");
        Assert.True(hasSampleFunction, "SampleFunction button not found");

        await page.CloseAsync();
    }

    [Fact]
    public async Task WebApp_CanCallFunction()
    {
        // Arrange
        var page = await _browser.NewPageAsync(new BrowserNewPageOptions
        {
            BaseURL = _webAppBaseUrl,
            ViewportSize = new ViewportSize { Width = 1280, Height = 720 }
        });

        // Act
        await page.GotoAsync("/", new PageGotoOptions { Timeout = _timeout });
        
        // Wait for functions to load
        await page.WaitForSelectorAsync("#functionsList:not(:has-text('Loading functions...'))", 
            new PageWaitForSelectorOptions { Timeout = _timeout });
        
        // Click the SampleFunction button
        await page.ClickAsync("button:has-text('SampleFunction')");
        
        // Wait for response to appear
        await page.WaitForSelectorAsync("#functionResponse:has-text('Hello from Sample Function!')", 
            new PageWaitForSelectorOptions { Timeout = _timeout });

        // Assert
        var responseContent = await page.TextContentAsync("#functionResponse");
        Assert.NotNull(responseContent);
        Assert.Contains("Hello from Sample Function!", responseContent);
        
        // Check if response contains a timestamp in ISO format
        var timestampPattern = new Regex(@"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}");
        Assert.Matches(timestampPattern, responseContent);

        await page.CloseAsync();
    }
}
