namespace Concord.Domain.Exceptions;

public class MissingSettingException(string name)
    : Exception($"Missing setting '{name}'.")
{ }