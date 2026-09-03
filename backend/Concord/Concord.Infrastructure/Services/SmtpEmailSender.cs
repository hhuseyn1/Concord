using System.Net;
using System.Net.Mail;
using Concord.Application.Email;
using Concord.Infrastructure.Settings;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Concord.Infrastructure.Services;

public class SmtpEmailSender(IOptions<EmailSettings> emailOptions, ILogger<SmtpEmailSender> logger) : IEmailSender
{
    private readonly EmailSettings _settings = emailOptions.Value;
    private readonly ILogger<SmtpEmailSender> _logger = logger;

    public async Task SendPasswordResetEmailAsync(string toEmail, string resetLink)
    {
        const string subject = "Reset your Concord password";
        var body = $"""
            We received a request to reset your Concord password.

            Reset your password: {resetLink}

            This link expires in 30 minutes. If you didn't request this, you can safely ignore this email.
            """;

        // Dev fallback: no SMTP host configured, so log the link instead of failing every
        // forgot-password request locally.
        if (string.IsNullOrWhiteSpace(_settings.SmtpHost))
        {
            _logger.LogWarning(
                "SmtpHost is not configured - skipping real email send. Password reset link for {Email}: {ResetLink}",
                toEmail, resetLink);
            return;
        }

        using var message = new MailMessage
        {
            From = new MailAddress(_settings.FromAddress, _settings.FromName),
            Subject = subject,
            Body = body,
            IsBodyHtml = false,
        };
        message.To.Add(toEmail);

        using var client = new SmtpClient(_settings.SmtpHost, _settings.SmtpPort)
        {
            EnableSsl = _settings.EnableSsl,
            Credentials = new NetworkCredential(_settings.SmtpUsername, _settings.SmtpPassword),
        };

        await client.SendMailAsync(message);
    }

    public async Task SendVerificationEmailAsync(string toEmail, string verificationLink)
    {
        const string subject = "Verify your Concord email";
        var body = $"""
            Welcome to Concord! Please confirm this is your email address.

            Verify your email: {verificationLink}

            This link expires in 60 minutes. If you didn't create this account, you can safely ignore this email.
            """;

        // Dev fallback: no SMTP host configured, so log the link instead of failing every
        // registration locally.
        if (string.IsNullOrWhiteSpace(_settings.SmtpHost))
        {
            _logger.LogWarning(
                "SmtpHost is not configured - skipping real email send. Email verification link for {Email}: {VerificationLink}",
                toEmail, verificationLink);
            return;
        }

        using var message = new MailMessage
        {
            From = new MailAddress(_settings.FromAddress, _settings.FromName),
            Subject = subject,
            Body = body,
            IsBodyHtml = false,
        };
        message.To.Add(toEmail);

        using var client = new SmtpClient(_settings.SmtpHost, _settings.SmtpPort)
        {
            EnableSsl = _settings.EnableSsl,
            Credentials = new NetworkCredential(_settings.SmtpUsername, _settings.SmtpPassword),
        };

        await client.SendMailAsync(message);
    }
}
