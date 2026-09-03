using System.Net.Mime;
using Concord.Application.Models;
using Concord.Domain.Exceptions;

namespace Concord.API.Middlewares;

public class GlobalExceptionHandlingMiddleware(ILogger<GlobalExceptionHandlingMiddleware> logger) : IMiddleware
{
    private readonly ILogger<GlobalExceptionHandlingMiddleware> _logger = logger;

    private static readonly Action<ILogger, Exception> LogError = LoggerMessage.Define(LogLevel.Error, new EventId(0, nameof(GlobalExceptionHandlingMiddleware)), "Error");
    private static readonly Action<ILogger, Exception> LogWarning = LoggerMessage.Define(LogLevel.Warning, new EventId(1, nameof(GlobalExceptionHandlingMiddleware)), "Warning");

    public async Task InvokeAsync(HttpContext context, RequestDelegate next)
    {
        try
        {
            await next(context);
        }
        catch (ParameterValidationException ex)
        {
            LogWarning(_logger, ex);
            await WriteErrorAsync(context, StatusCodes.Status400BadRequest, ex.Message);
        }
        catch (UnauthorizedAccessException ex)
        {
            LogWarning(_logger, ex);
            await WriteErrorAsync(context, StatusCodes.Status401Unauthorized, ex.Message);
        }
        catch (AlreadyExistsException ex)
        {
            LogWarning(_logger, ex);
            await WriteErrorAsync(context, StatusCodes.Status409Conflict, ex.Message);
        }
        catch (NotFoundException ex)
        {
            LogWarning(_logger, ex);
            await WriteErrorAsync(context, StatusCodes.Status404NotFound, ex.Message);
        }
        catch (ForbiddenException ex)
        {
            LogWarning(_logger, ex);
            await WriteErrorAsync(context, StatusCodes.Status403Forbidden, ex.Message);
        }
        catch (Exception ex)
        {
            LogError(_logger, ex);
            await WriteErrorAsync(context, StatusCodes.Status500InternalServerError, "Internal Server Error");
        }
    }

    private static Task WriteErrorAsync(HttpContext context, int statusCode, string message)
    {
        context.Response.StatusCode = statusCode;
        context.Response.ContentType = MediaTypeNames.Application.Json;
        return context.Response.WriteAsJsonAsync(new ErrorResponse(message));
    }
}
