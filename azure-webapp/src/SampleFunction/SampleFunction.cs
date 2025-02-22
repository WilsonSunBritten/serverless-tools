using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using System.Text.Json;

namespace SampleFunction
{
    public class SampleFunction
    {
        [Function("SampleEndpoint")]
        public async Task<HttpResponseData> Run([HttpTrigger(AuthorizationLevel.Anonymous, "get")] HttpRequestData req)
        {
            var response = req.CreateResponse(HttpStatusCode.OK);

            var result = new
            {
                Message = "Hello from Sample Function!",
                Timestamp = DateTime.UtcNow
            };

            await response.WriteAsJsonAsync(result);
            return response;
        }
    }
}
