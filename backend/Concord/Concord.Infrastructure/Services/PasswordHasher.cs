using System.Security.Cryptography;
using Microsoft.AspNetCore.Cryptography.KeyDerivation;

namespace Concord.Infrastructure.Services;

public static class PasswordHasher
{
    private const byte CurrentVersion = 0x01;

    private const int SaltSize = 128 / 8;
    private const int SubkeyLength = 256 / 8;

    private const KeyDerivationPrf LegacyPrf = KeyDerivationPrf.HMACSHA1;
    private const int LegacyIterations = 1000;

    private const int CurrentIterations = 600_000;

    public static string HashPassword(string password)
    {
        byte[] salt = RandomNumberGenerator.GetBytes(SaltSize);

        byte[] subkey = Rfc2898DeriveBytes.Pbkdf2(
            password,
            salt,
            CurrentIterations,
            HashAlgorithmName.SHA256,
            SubkeyLength);

        var outputBytes = new byte[1 + SaltSize + SubkeyLength];
        outputBytes[0] = CurrentVersion;
        Buffer.BlockCopy(salt, 0, outputBytes, 1, SaltSize);
        Buffer.BlockCopy(subkey, 0, outputBytes, 1 + SaltSize, SubkeyLength);

        return Convert.ToBase64String(outputBytes);
    }

    public static bool VerifyHashedPassword(string hashedPassword, string password)
    {
        byte[] decoded;

        try
        {
            decoded = Convert.FromBase64String(hashedPassword);
        }
        catch (FormatException)
        {
            return false;
        }

        if (decoded.Length < 1)
            return false;

        return decoded[0] switch
        {
            0x00 => VerifyV0(password, decoded),
            0x01 => VerifyV1(password, decoded),
            _ => false
        };
    }

    public static bool NeedsRehash(string hashedPassword)
    {
        byte[] decoded;

        try
        {
            decoded = Convert.FromBase64String(hashedPassword);
        }
        catch (FormatException)
        {
            return false;
        }

        return decoded.Length < 1 || decoded[0] != CurrentVersion;
    }

    private static bool VerifyV0(string password, byte[] decoded)
    {
        if (decoded.Length != 1 + SaltSize + SubkeyLength)
            return false;

        byte[] salt = new byte[SaltSize];
        Buffer.BlockCopy(decoded, 1, salt, 0, SaltSize);

        byte[] expectedSubkey = new byte[SubkeyLength];
        Buffer.BlockCopy(decoded, 1 + SaltSize, expectedSubkey, 0, SubkeyLength);

        byte[] actualSubkey = KeyDerivation.Pbkdf2(
            password,
            salt,
            LegacyPrf,
            LegacyIterations,
            SubkeyLength);

        return CryptographicOperations.FixedTimeEquals(actualSubkey, expectedSubkey);
    }

    private static bool VerifyV1(string password, byte[] decoded)
    {
        if (decoded.Length != 1 + SaltSize + SubkeyLength)
            return false;

        byte[] salt = new byte[SaltSize];
        Buffer.BlockCopy(decoded, 1, salt, 0, SaltSize);

        byte[] expectedSubkey = new byte[SubkeyLength];
        Buffer.BlockCopy(decoded, 1 + SaltSize, expectedSubkey, 0, SubkeyLength);

        byte[] actualSubkey = Rfc2898DeriveBytes.Pbkdf2(
            password,
            salt,
            CurrentIterations,
            HashAlgorithmName.SHA256,
            SubkeyLength);

        return CryptographicOperations.FixedTimeEquals(actualSubkey, expectedSubkey);
    }
}