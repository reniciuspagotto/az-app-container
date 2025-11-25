using AzAppDevContainer.App.Data;
using AzAppDevContainer.App.Domain;
using Microsoft.EntityFrameworkCore;

namespace AzAppDevContainer.App.Controllers;

public static class CustomerController
{
    public static void MapCustomerEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapPost("/customer", async (Customer customer, DataContext context) =>
            {
                await context.Customers.AddAsync(customer);
                await context.SaveChangesAsync();
                return Results.Created($"/customer/{customer.Id}", customer);
            })
            .WithName("Create a new Customer")
            .WithOpenApi();

        app.MapGet("/customer/{id}", async (int id, DataContext context) =>
            {
                var customer = await context.Customers.Where(p => p.Id == id).FirstOrDefaultAsync();
                return customer is null ? Results.NotFound() : Results.Ok(customer);
            })
            .WithName("Get an existing Customer")
            .WithOpenApi();
    }
}
