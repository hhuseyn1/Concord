namespace Concord.Application.Email;

public interface IEmailSender
{
    Task SendPasswordResetEmailAsync(string toEmail, string resetLink);
    Task SendVerificationEmailAsync(string toEmail, string verificationLink);
}
