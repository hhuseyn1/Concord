namespace Concord.Domain.Exceptions;

public class ChannelNotVoiceException()
    : ParameterValidationException("channelId", "This action requires a voice channel.")
{ }
