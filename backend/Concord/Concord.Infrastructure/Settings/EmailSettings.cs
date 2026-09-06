namespace Concord.Infrastructure.Settings;

public class EmailSettings
{
    public string SmtpHost { get; set; } = null!;
    public int SmtpPort { get; set; }
    public string SenderEmail { get; set; } = null!;
    public string SmtpPassword { get; set; } = null!;
    public string SenderName { get; set; } = null!;
    public string FrontendBaseUrl { get; set; } = null!;
}
