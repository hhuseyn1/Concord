using Concord.Application.Email;
using Concord.Infrastructure.Settings;
using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MimeKit;

namespace Concord.Infrastructure.Services;

public class SmtpEmailSender(IOptions<EmailSettings> emailOptions, ILogger<SmtpEmailSender> logger) : IEmailSender
{
    private readonly EmailSettings _settings = emailOptions.Value;
    private readonly ILogger<SmtpEmailSender> _logger = logger;

    public async Task SendPasswordResetEmailAsync(string toEmail, string resetLink)
    {
        const string subject = "Reset your Concord password";
        var body = $"""
            <html><body style="font-family:Arial,sans-serif;max-width:600px;margin:auto;padding:24px;">
              <h2 style="color:#4f46e5;">Reset Your Password</h2>
              <p>Hello,</p>
              <p>We received a request to reset your Concord password. Click the button below to choose a new one:</p>
              <p style="margin:24px 0;">
                <a href="{resetLink}" style="background:#4f46e5;color:#ffffff;padding:12px 24px;border-radius:6px;text-decoration:none;font-weight:bold;">Reset Password</a>
              </p>
              <p>Or copy and paste this link into your browser:</p>
              <p style="word-break:break-all;color:#4f46e5;">{resetLink}</p>
              <p>This link expires in 30 minutes. If you didn't request this, you can safely ignore this email.</p>
              <p style="color:#6b7280;font-size:0.875rem;">This email was sent automatically.</p>
            </body></html>
            """;

        if (string.IsNullOrWhiteSpace(_settings.SmtpHost))
        {
            _logger.LogWarning(
                "SmtpHost is not configured - skipping real email send. Password reset link for {Email}: {ResetLink}",
                toEmail, resetLink);
            return;
        }

        await SendAsync(toEmail, subject, body);
    }

    public async Task SendVerificationEmailAsync(string toEmail, string verificationLink)
    {
        const string subject = "Verify your Concord email";
        var body = $"""
            <html><body style="font-family:Arial,sans-serif;max-width:600px;margin:auto;padding:24px;">
              <h2 style="color:#a229ff;">Verify Your Email</h2>
              <p>Welcome to Concord!</p>
              <p>Please confirm this is your email address by clicking the button below:</p>
              <p style="margin:24px 0;">
                <a href="{verificationLink}" style="background:#a229ff;color:#ffffff;padding:12px 24px;border-radius:6px;text-decoration:none;font-weight:bold;">Verify Email</a>
              </p>
              <p>Or copy and paste this link into your browser:</p>
              <p style="word-break:break-all;color:#a229ff;">{verificationLink}</p>
              <p>This link expires in 60 minutes. If you didn't create this account, you can safely ignore this email.</p>
              <p style="color:#6b7280;font-size:0.875rem;">This email was sent automatically.</p>
            </body></html>
            """;

        if (string.IsNullOrWhiteSpace(_settings.SmtpHost))
        {
            _logger.LogWarning(
                "SmtpHost is not configured - skipping real email send. Email verification link for {Email}: {VerificationLink}",
                toEmail, verificationLink);
            return;
        }

        await SendAsync(toEmail, subject, body);
    }

    private async Task SendAsync(string toEmail, string subject, string body)
    {
        using var client = new SmtpClient();
        await client.ConnectAsync(_settings.SmtpHost, _settings.SmtpPort, SecureSocketOptions.StartTls);
        await client.AuthenticateAsync(_settings.SenderEmail, _settings.SmtpPassword);
        await client.SendAsync(BuildMimeMessage(toEmail, subject, body));
        await client.DisconnectAsync(true);
    }

    private MimeMessage BuildMimeMessage(string toEmail, string subject, string body)
    {
        var mime = new MimeMessage();
        mime.From.Add(new MailboxAddress(_settings.SenderName, _settings.SenderEmail));
        mime.To.Add(MailboxAddress.Parse(toEmail));
        mime.Subject = subject;
        mime.Body = new TextPart("html") { Text = body };
        return mime;
    }
}
