namespace Concord.Domain.Exceptions;

public class TwoFactorAlreadyEnabledException()
    : AlreadyExistsException("Two-factor authentication is already enabled on this account.")
{ }
