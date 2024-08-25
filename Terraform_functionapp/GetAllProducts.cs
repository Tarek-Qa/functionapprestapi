using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System.Threading.Tasks;

namespace Terraform_functionapp
{
    public class GetAllProducts
    {
        private readonly ILogger<GetAllProducts> _logger;
        private readonly AppDbContext _ctx;

        // Combined constructor
        public GetAllProducts(ILogger<GetAllProducts> logger, AppDbContext ctx)
        {
            _logger = logger;
            _ctx = ctx;
        }

        [Function("GetAllProducts")]
        public async Task<IActionResult> GetAllProduct(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "products")] HttpRequest req)
        {
            _logger.LogInformation("Getting All Products");
            var products = await _ctx.Products.ToListAsync();
            return new OkObjectResult(products);
        }
    }
}
