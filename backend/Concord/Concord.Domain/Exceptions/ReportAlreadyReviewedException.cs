namespace Concord.Domain.Exceptions;

public class ReportAlreadyReviewedException()
    : AlreadyExistsException("This report has already been resolved or dismissed.")
{ }
