namespace Concord.Infrastructure.Settings;

public class EmailSettings
{
    public string SmtpHost { get; set; } = null!;
    public int SmtpPort { get; set; }
    public string SmtpUsername { get; set; } = null!;
    public string SmtpPassword { get; set; } = null!;
    public bool EnableSsl { get; set; }
    public string FromAddress { get; set; } = null!;
    public string FromName { get; set; } = null!;
    public string FrontendBaseUrl { get; set; } = null!;
}
