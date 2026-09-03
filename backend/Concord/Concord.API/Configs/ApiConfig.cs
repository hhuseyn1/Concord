using Concord.Application.Models;
using Microsoft.AspNetCore.Mvc;

namespace Concord.API.Configs;

public static class ApiConfig
{
    public static IMvcBuilder SetupCustomModelValidationResponse(this IMvcBuilder builder)
    {
        builder.ConfigureApiBehaviorOptions(options => options.InvalidModelStateResponseFactory = context =>
        {
            var errors = context.ModelState.LastOrDefault(kvp => kvp.Value?.Errors.Count > 0).Value?.Errors;
            var message = errors is null ? "Unknown model validation error." : errors.Last().ErrorMessage;
            return new BadRequestObjectResult(new ErrorResponse(message));
        });

        return builder;
    }
}