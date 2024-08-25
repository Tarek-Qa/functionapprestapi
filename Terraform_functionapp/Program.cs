using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using Microsoft.Azure.Functions.Worker;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Terraform_functionapp;

var host = new HostBuilder()
    .ConfigureFunctionsWebApplication()
    .ConfigureServices(services =>
    {
        var KeyVaultUrl = new Uri(Environment.GetEnvironmentVariable("KeyVaultUrl"));
        var secretClient = new SecretClient(KeyVaultUrl, new DefaultAzureCredential());

        // Fetch the connection string from KeyVault
        var cs = secretClient.GetSecret("sql").Value.Value;
        services.AddDbContext<AppDbContext>(options => options.UseSqlServer(cs));


        services.AddApplicationInsightsTelemetryWorkerService();
        services.ConfigureFunctionsApplicationInsights();

    })
    .Build();


host.Run();
