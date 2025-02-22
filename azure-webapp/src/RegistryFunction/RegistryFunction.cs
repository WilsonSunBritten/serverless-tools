using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using System.Text.Json;

namespace RegistryFunction
{
    public class RegistryFunction
    {
        [Function("ListFunctions")]
        public async Task<HttpResponseData> RunListFunctions([HttpTrigger(AuthorizationLevel.Anonymous, "get")] HttpRequestData req)
        {
            var response = req.CreateResponse(HttpStatusCode.OK);

            var functionList = new[]
            {
                new {
                    Name = "SampleFunction",
                    Url = Environment.GetEnvironmentVariable("SAMPLE_FUNCTION_URL")?.Replace("localhost", "127.0.0.1") ?? "http://127.0.0.1:7072"
                }
            };

            await response.WriteAsJsonAsync(functionList);
            return response;
        }

        [Function("RegisterFunction")]
        public async Task<HttpResponseData> RunRegisterFunction([HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequestData req)
        {
            var response = req.CreateResponse(HttpStatusCode.OK);
            
            // In a real implementation, this would store the registration in Azure Table Storage
            await response.WriteAsJsonAsync(new { message = "Function registered successfully" });
            return response;
        }
    }
}
