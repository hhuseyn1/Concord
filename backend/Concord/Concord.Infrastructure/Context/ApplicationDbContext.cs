using Concord.Application.Enums;
using Concord.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Concord.Infrastructure.Context;

public class ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : DbContext(options)
{
    public DbSet<Session> Sessions { get; set; }
    public DbSet<PasswordResetToken> PasswordResetTokens { get; set; }
    public DbSet<EmailVerificationToken> EmailVerificationTokens { get; set; }
    public DbSet<TwoFactorRecoveryCode> TwoFactorRecoveryCodes { get; set; }
    public DbSet<QrLoginSession> QrLoginSessions { get; set; }
    public DbSet<User> Users { get; set; }
    public DbSet<FriendRequest> FriendRequests { get; set; }
    public DbSet<Block> Blocks { get; set; }
    public DbSet<Server> Servers { get; set; }
    public DbSet<ServerMember> ServerMembers { get; set; }
    public DbSet<Role> Roles { get; set; }
    public DbSet<ServerMemberRole> ServerMemberRoles { get; set; }
    public DbSet<ServerBan> ServerBans { get; set; }
    public DbSet<Channel> Channels { get; set; }
    public DbSet<ChannelReadState> ChannelReadStates { get; set; }
    public DbSet<Invite> Invites { get; set; }
    public DbSet<Message> Messages { get; set; }
    public DbSet<MessageHiddenForUser> MessageHiddenForUsers { get; set; }
    public DbSet<MessageReaction> MessageReactions { get; set; }
    public DbSet<MessageMention> MessageMentions { get; set; }
    public DbSet<Conversation> Conversations { get; set; }
    public DbSet<DirectMessage> DirectMessages { get; set; }
    public DbSet<DirectMessageHiddenForUser> DirectMessageHiddenForUsers { get; set; }
    public DbSet<DirectMessageReaction> DirectMessageReactions { get; set; }
    public DbSet<DirectMessageMention> DirectMessageMentions { get; set; }
    public DbSet<UserPresence> UserPresences { get; set; }
    public DbSet<Notification> Notifications { get; set; }
    public DbSet<Call> Calls { get; set; }
    public DbSet<UploadedFile> UploadedFiles { get; set; }
    public DbSet<Report> Reports { get; set; }
    public DbSet<AuditLog> AuditLogs { get; set; }
    public DbSet<PushToken> PushTokens { get; set; }
    public DbSet<Subscription> Subscriptions { get; set; }
    public DbSet<StarTransaction> StarTransactions { get; set; }
    public DbSet<StarPurchase> StarPurchases { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.HasPostgresExtension("pg_trgm");

        ConfigureSession(modelBuilder.Entity<Session>());
        ConfigurePasswordResetToken(modelBuilder.Entity<PasswordResetToken>());
        ConfigureEmailVerificationToken(modelBuilder.Entity<EmailVerificationToken>());
        ConfigureTwoFactorRecoveryCode(modelBuilder.Entity<TwoFactorRecoveryCode>());
        ConfigureQrLoginSession(modelBuilder.Entity<QrLoginSession>());
        ConfigureUser(modelBuilder.Entity<User>());
        ConfigureFriendRequest(modelBuilder.Entity<FriendRequest>());
        ConfigureBlock(modelBuilder.Entity<Block>());
        ConfigureServer(modelBuilder.Entity<Server>());
        ConfigureServerMember(modelBuilder.Entity<ServerMember>());
        ConfigureRole(modelBuilder.Entity<Role>());
        ConfigureServerMemberRole(modelBuilder.Entity<ServerMemberRole>());
        ConfigureServerBan(modelBuilder.Entity<ServerBan>());
        ConfigureChannel(modelBuilder.Entity<Channel>());
        ConfigureChannelReadState(modelBuilder.Entity<ChannelReadState>());
        ConfigureInvite(modelBuilder.Entity<Invite>());
        ConfigureMessage(modelBuilder.Entity<Message>());
        ConfigureMessageHiddenForUser(modelBuilder.Entity<MessageHiddenForUser>());
        ConfigureMessageReaction(modelBuilder.Entity<MessageReaction>());
        ConfigureMessageMention(modelBuilder.Entity<MessageMention>());
        ConfigureConversation(modelBuilder.Entity<Conversation>());
        ConfigureDirectMessage(modelBuilder.Entity<DirectMessage>());
        ConfigureDirectMessageHiddenForUser(modelBuilder.Entity<DirectMessageHiddenForUser>());
        ConfigureDirectMessageReaction(modelBuilder.Entity<DirectMessageReaction>());
        ConfigureDirectMessageMention(modelBuilder.Entity<DirectMessageMention>());
        ConfigureUserPresence(modelBuilder.Entity<UserPresence>());
        ConfigureNotification(modelBuilder.Entity<Notification>());
        ConfigureCall(modelBuilder.Entity<Call>());
        ConfigureUploadedFile(modelBuilder.Entity<UploadedFile>());
        ConfigureReport(modelBuilder.Entity<Report>());
        ConfigureAuditLog(modelBuilder.Entity<AuditLog>());
        ConfigurePushToken(modelBuilder.Entity<PushToken>());
        ConfigureSubscription(modelBuilder.Entity<Subscription>());
        ConfigureStarTransaction(modelBuilder.Entity<StarTransaction>());
        ConfigureStarPurchase(modelBuilder.Entity<StarPurchase>());
    }
    
    private static void ConfigureSession(EntityTypeBuilder<Session> builder)
    {
        builder.ToTable("Session");

        builder.HasKey(session => session.Id);

        builder.Property(session => session.Created).HasDefaultValueSql("now()");

        builder.Property(session => session.UserAgent).HasMaxLength(512);
        builder.Property(session => session.IpAddress).HasMaxLength(45);
        builder.Property(session => session.DeviceLabel).HasMaxLength(200);
        builder.Property(session => session.Browser).HasMaxLength(100);
        builder.Property(session => session.OS).HasMaxLength(100);

        builder.HasOne(session => session.User)
            .WithMany(user => user.Sessions)
            .IsRequired()
            .OnDelete(DeleteBehavior.Restrict);
    }
    
    private static void ConfigurePasswordResetToken(EntityTypeBuilder<PasswordResetToken> builder)
    {
        builder.ToTable("PasswordResetToken");

        builder.HasKey(token => token.Id);

        builder.Property(token => token.Created).HasDefaultValueSql("now()");

        builder.Property(token => token.TokenHash).IsRequired().HasMaxLength(64);

        builder.HasIndex(token => token.TokenHash).IsUnique();

        builder.HasOne(token => token.User)
            .WithMany()
            .HasForeignKey(token => token.UserId)
            .IsRequired()
            .OnDelete(DeleteBehavior.Restrict);
    }

    private static void ConfigureEmailVerificationToken(EntityTypeBuilder<EmailVerificationToken> builder)
    {
        builder.ToTable("EmailVerificationToken");

        builder.HasKey(token => token.Id);

        builder.Property(token => token.Created).HasDefaultValueSql("now()");

        builder.Property(token => token.TokenHash).IsRequired().HasMaxLength(64);

        builder.HasIndex(token => token.TokenHash).IsUnique();

        builder.HasOne(token => token.User)
            .WithMany()
            .HasForeignKey(token => token.UserId)
            .IsRequired()
            .OnDelete(DeleteBehavior.Restrict);
    }

    private static void ConfigureTwoFactorRecoveryCode(EntityTypeBuilder<TwoFactorRecoveryCode> builder)
    {
        builder.ToTable("TwoFactorRecoveryCode");

        builder.HasKey(code => code.Id);

        builder.Property(code => code.Created).HasDefaultValueSql("now()");

        builder.Property(code => code.CodeHash).IsRequired().HasMaxLength(100);

        // Redemption looks codes up by user, then compares hashes in memory - the hash is salted per
        // row, so it cannot be used as a lookup key the way PasswordResetToken's can.
        builder.HasIndex(code => code.UserId);

        builder.HasOne<User>()
            .WithMany()
            .HasForeignKey(code => code.UserId)
            .IsRequired()
            .OnDelete(DeleteBehavior.Cascade);
    }

    private static void ConfigureQrLoginSession(EntityTypeBuilder<QrLoginSession> builder)
    {
        builder.ToTable("QrLoginSession");

        builder.HasKey(session => session.Id);

        builder.Property(session => session.Created).HasDefaultValueSql("now()");

        builder.Property(session => session.UserCode).IsRequired().HasMaxLength(16);
        builder.Property(session => session.PollingTokenHash).IsRequired().HasMaxLength(64);

        // Both are lookup keys on unauthenticated or near-unauthenticated paths, so both are unique
        // and indexed - a scan here would be a denial-of-service lever.
        builder.HasIndex(session => session.UserCode).IsUnique();
        builder.HasIndex(session => session.PollingTokenHash).IsUnique();

        builder.HasOne<User>()
            .WithMany()
            .HasForeignKey(session => session.ApprovedByUserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Property(session => session.UserAgent).HasMaxLength(512);
        builder.Property(session => session.IpAddress).HasMaxLength(45);
        builder.Property(session => session.DeviceLabel).HasMaxLength(200);
        builder.Property(session => session.Browser).HasMaxLength(100);
        builder.Property(session => session.OS).HasMaxLength(100);
    }

    private static void ConfigureUser(EntityTypeBuilder<User> builder)
    {
        builder.ToTable<User>("User");

        builder.Property(user => user.Created).HasDefaultValueSql("now()");

        builder.HasKey(user => user.Id);

        builder.Property(user => user.PhoneNumber).HasMaxLength(30);

        builder.Property(user => user.Name).IsRequired().HasMaxLength(100);

        builder.Property(user => user.Surname).IsRequired().HasMaxLength(100);

        builder.Property(user => user.Username).HasMaxLength(32);

        builder.HasIndex(user => user.Username).IsUnique();

        builder.HasIndex(user => user.Email).IsUnique();

        builder.Property(user => user.AvatarUrl).HasMaxLength(2048);

        builder.Property(user => user.Locale).HasMaxLength(7);

        builder.Property(user => user.Password).HasMaxLength(100);

        builder.Property(user => user.NotificationsSoundEnabled).HasDefaultValue(true);

        builder.Property(user => user.CustomStatusEmoji).HasMaxLength(16);
        builder.Property(user => user.CustomStatusText).HasMaxLength(128);

        builder.Property(user => user.FriendRequestPrivacy).HasDefaultValue(FriendRequestPrivacy.Everyone);
        builder.Property(user => user.DirectMessagePrivacy).HasDefaultValue(DirectMessagePrivacy.FriendsOnly);
        builder.Property(user => user.ActivityVisibility).HasDefaultValue(ActivityVisibility.Everyone);
        builder.Property(user => user.ReadReceiptsEnabled).HasDefaultValue(true);

        builder.Property(user => user.ActivityApplicationName).HasMaxLength(128);

        // Base32 of a 20-byte secret is 32 chars, but the stored value is that secret wrapped by
        // Data Protection's IDataProtector.Protect - measured at ~176 base64 chars for a 32-char
        // input, so 64 silently truncated it. 512 leaves comfortable headroom.
        builder.Property(user => user.TwoFactorSecret).HasMaxLength(512);

        builder.Property(user => user.StarsBalance).HasDefaultValue(0);
        builder.Property(user => user.StarsEarnedToday).HasDefaultValue(0);
    }

    private static void ConfigureFriendRequest(EntityTypeBuilder<FriendRequest> builder)
    {
        builder.ToTable("FriendRequest");

        builder.HasKey(request => request.Id);

        builder.Property(request => request.Created).HasDefaultValueSql("now()");

        builder.HasOne<User>().WithMany().HasForeignKey(request => request.RequesterId).OnDelete(DeleteBehavior.Restrict);
        builder.HasOne<User>().WithMany().HasForeignKey(request => request.AddresseeId).OnDelete(DeleteBehavior.Restrict);
    }

    private static void ConfigureBlock(EntityTypeBuilder<Block> builder)
    {
        builder.ToTable("Block");

        builder.HasKey(block => block.Id);

        builder.Property(block => block.Created).HasDefaultValueSql("now()");

        builder.HasOne<User>().WithMany().HasForeignKey(block => block.BlockerId).OnDelete(DeleteBehavior.Restrict);
        builder.HasOne<User>().WithMany().HasForeignKey(block => block.BlockedId).OnDelete(DeleteBehavior.Restrict);
    }

    private static void ConfigureServer(EntityTypeBuilder<Server> builder)
    {
        builder.ToTable("Server");

        builder.HasKey(server => server.Id);

        builder.Property(server => server.Created).HasDefaultValueSql("now()");

        builder.Property(server => server.Name).IsRequired().HasMaxLength(100);

        builder.Property(server => server.IconUrl).HasMaxLength(2048);

        builder.HasOne<User>().WithMany().HasForeignKey(server => server.OwnerId).OnDelete(DeleteBehavior.Restrict);
    }

    private static void ConfigureServerMember(EntityTypeBuilder<ServerMember> builder)
    {
        builder.ToTable("ServerMember");

        builder.HasKey(member => member.Id);

        builder.Property(member => member.Created).HasDefaultValueSql("now()");

        builder.HasIndex(member => new { member.ServerId, member.UserId }).IsUnique();

        builder.Property(member => member.TimeoutReason).HasMaxLength(500);

        builder.HasOne<Server>().WithMany().HasForeignKey(member => member.ServerId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<User>().WithMany().HasForeignKey(member => member.UserId).OnDelete(DeleteBehavior.Restrict);
    }


    private static void ConfigureRole(EntityTypeBuilder<Role> builder)
    {
        builder.ToTable("Role");

        builder.HasKey(role => role.Id);

        builder.Property(role => role.Created).HasDefaultValueSql("now()");

        builder.Property(role => role.Name).IsRequired().HasMaxLength(100);

        builder.Property(role => role.Color).HasMaxLength(7);

        // Persisted as bigint so the flags enum has room to grow past 32 permissions.
        builder.Property(role => role.Permissions).HasConversion<long>();

        builder.HasIndex(role => new { role.ServerId, role.Position });

        // One @everyone role per server, enforced in the database rather than only in the service.
        builder.HasIndex(role => role.ServerId)
            .IsUnique()
            .HasFilter("\"IsDefault\"")
            .HasDatabaseName("IX_Role_ServerId_Default");

        builder.HasOne<Server>().WithMany().HasForeignKey(role => role.ServerId).OnDelete(DeleteBehavior.Cascade);
    }

    private static void ConfigureServerMemberRole(EntityTypeBuilder<ServerMemberRole> builder)
    {
        builder.ToTable("ServerMemberRole");

        builder.HasKey(assignment => assignment.Id);

        builder.Property(assignment => assignment.Created).HasDefaultValueSql("now()");

        builder.HasIndex(assignment => new { assignment.ServerMemberId, assignment.RoleId }).IsUnique();

        builder.HasOne<ServerMember>().WithMany().HasForeignKey(assignment => assignment.ServerMemberId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<Role>().WithMany().HasForeignKey(assignment => assignment.RoleId).OnDelete(DeleteBehavior.Cascade);
    }

    private static void ConfigureServerBan(EntityTypeBuilder<ServerBan> builder)
    {
        builder.ToTable("ServerBan");

        builder.HasKey(ban => ban.Id);

        builder.Property(ban => ban.Created).HasDefaultValueSql("now()");

        builder.Property(ban => ban.Reason).HasMaxLength(500);

        // One live ban row per (server, user). Lifting a ban deletes the row rather than flagging it,
        // so this stays a plain unique index and "is banned" never needs a status column.
        builder.HasIndex(ban => new { ban.ServerId, ban.UserId }).IsUnique();

        builder.HasOne<Server>().WithMany().HasForeignKey(ban => ban.ServerId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<User>().WithMany().HasForeignKey(ban => ban.UserId).OnDelete(DeleteBehavior.Restrict);
        builder.HasOne<User>().WithMany().HasForeignKey(ban => ban.BannedByUserId).OnDelete(DeleteBehavior.Restrict);
    }

    private static void ConfigureChannel(EntityTypeBuilder<Channel> builder)
    {
        builder.ToTable("Channel");

        builder.HasKey(channel => channel.Id);

        builder.Property(channel => channel.Created).HasDefaultValueSql("now()");

        builder.Property(channel => channel.Name).IsRequired().HasMaxLength(100);

        builder.Property(channel => channel.Position).HasDefaultValue(0);

        builder.HasIndex(channel => new { channel.ServerId, channel.Type, channel.Position });

        builder.HasOne<Server>().WithMany().HasForeignKey(channel => channel.ServerId).OnDelete(DeleteBehavior.Cascade);
    }

    private static void ConfigureChannelReadState(EntityTypeBuilder<ChannelReadState> builder)
    {
        builder.ToTable("ChannelReadState");

        builder.HasKey(state => state.Id);

        builder.Property(state => state.Created).HasDefaultValueSql("now()");

        builder.HasIndex(state => new { state.ChannelId, state.UserId }).IsUnique();

        builder.HasOne<Channel>().WithMany().HasForeignKey(state => state.ChannelId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<User>().WithMany().HasForeignKey(state => state.UserId).OnDelete(DeleteBehavior.Restrict);
    }

    private static void ConfigureInvite(EntityTypeBuilder<Invite> builder)
    {
        builder.ToTable("Invite");

        builder.HasKey(invite => invite.Id);

        builder.Property(invite => invite.Created).HasDefaultValueSql("now()");

        builder.Property(invite => invite.Code).IsRequired().HasMaxLength(16);

        builder.HasIndex(invite => invite.Code).IsUnique();

        builder.HasOne<Server>().WithMany().HasForeignKey(invite => invite.ServerId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<User>().WithMany().HasForeignKey(invite => invite.CreatedByUserId).OnDelete(DeleteBehavior.Restrict);
    }

    private static void ConfigureMessage(EntityTypeBuilder<Message> builder)
    {
        builder.ToTable("Message");

        builder.HasKey(message => message.Id);

        builder.Property(message => message.Created).HasDefaultValueSql("now()");

        builder.Property(message => message.Content).IsRequired().HasMaxLength(4000);

        builder.Property(message => message.AttachmentUrl).HasMaxLength(2048);

        builder.Property(message => message.MentionsEveryone).HasDefaultValue(false);

        builder.HasOne<Channel>().WithMany().HasForeignKey(message => message.ChannelId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<User>().WithMany().HasForeignKey(message => message.SenderId).OnDelete(DeleteBehavior.Restrict);
        builder.HasOne<Message>().WithMany().HasForeignKey(message => message.ReplyToMessageId).OnDelete(DeleteBehavior.SetNull);
        builder.HasOne<User>().WithMany().HasForeignKey(message => message.PinnedByUserId).OnDelete(DeleteBehavior.SetNull);
        builder.HasOne<User>().WithMany().HasForeignKey(message => message.ForwardedFromSenderId).OnDelete(DeleteBehavior.SetNull);

        // P2.3 global search: trigram-backed ILIKE lookups over Content, widened from the P1
        // per-conversation search to every channel/DM the caller can access.
        builder.HasIndex(message => message.Content).HasMethod("gin").HasOperators("gin_trgm_ops");
    }

    private static void ConfigureMessageHiddenForUser(EntityTypeBuilder<MessageHiddenForUser> builder)
    {
        builder.ToTable("MessageHiddenForUser");

        builder.HasKey(hidden => hidden.Id);

        builder.Property(hidden => hidden.Created).HasDefaultValueSql("now()");

        builder.HasIndex(hidden => new { hidden.MessageId, hidden.UserId }).IsUnique();

        builder.HasOne<Message>().WithMany().HasForeignKey(hidden => hidden.MessageId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<User>().WithMany().HasForeignKey(hidden => hidden.UserId).OnDelete(DeleteBehavior.Restrict);
    }

    private static void ConfigureMessageReaction(EntityTypeBuilder<MessageReaction> builder)
    {
        builder.ToTable("MessageReaction");

        builder.HasKey(reaction => reaction.Id);

        builder.Property(reaction => reaction.Created).HasDefaultValueSql("now()");

        builder.Property(reaction => reaction.Emoji).IsRequired().HasMaxLength(32);

        builder.HasIndex(reaction => new { reaction.MessageId, reaction.UserId, reaction.Emoji }).IsUnique();

        builder.HasOne<Message>().WithMany().HasForeignKey(reaction => reaction.MessageId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<User>().WithMany().HasForeignKey(reaction => reaction.UserId).OnDelete(DeleteBehavior.Restrict);
    }

    private static void ConfigureMessageMention(EntityTypeBuilder<MessageMention> builder)
    {
        builder.ToTable("MessageMention");

        builder.HasKey(mention => mention.Id);

        builder.Property(mention => mention.Created).HasDefaultValueSql("now()");

        builder.HasIndex(mention => new { mention.MessageId, mention.MentionedUserId }).IsUnique();
        builder.HasIndex(mention => mention.MentionedUserId);

        builder.HasOne<Message>().WithMany().HasForeignKey(mention => mention.MessageId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<User>().WithMany().HasForeignKey(mention => mention.MentionedUserId).OnDelete(DeleteBehavior.Restrict);
    }

    private static void ConfigureConversation(EntityTypeBuilder<Conversation> builder)
    {
        builder.ToTable("Conversation");

        builder.HasKey(conversation => conversation.Id);

        builder.Property(conversation => conversation.Created).HasDefaultValueSql("now()");

        builder.HasIndex(conversation => new { conversation.UserAId, conversation.UserBId }).IsUnique();
        builder.HasIndex(conversation => conversation.UserAId);
        builder.HasIndex(conversation => conversation.UserBId);

        builder.HasOne<User>().WithMany().HasForeignKey(conversation => conversation.UserAId).OnDelete(DeleteBehavior.Restrict);
        builder.HasOne<User>().WithMany().HasForeignKey(conversation => conversation.UserBId).OnDelete(DeleteBehavior.Restrict);
    }

    private static void ConfigureDirectMessage(EntityTypeBuilder<DirectMessage> builder)
    {
        builder.ToTable("DirectMessage");

        builder.HasKey(message => message.Id);

        builder.Property(message => message.Created).HasDefaultValueSql("now()");

        builder.Property(message => message.Content).IsRequired().HasMaxLength(4000);

        builder.Property(message => message.AttachmentUrl).HasMaxLength(2048);

        builder.HasOne<Conversation>().WithMany().HasForeignKey(message => message.ConversationId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<User>().WithMany().HasForeignKey(message => message.SenderId).OnDelete(DeleteBehavior.Restrict);
        builder.HasOne<DirectMessage>().WithMany().HasForeignKey(message => message.ReplyToMessageId).OnDelete(DeleteBehavior.SetNull);
        builder.HasOne<User>().WithMany().HasForeignKey(message => message.PinnedByUserId).OnDelete(DeleteBehavior.SetNull);
        builder.HasOne<User>().WithMany().HasForeignKey(message => message.ForwardedFromSenderId).OnDelete(DeleteBehavior.SetNull);

        // Mirrors ConfigureMessage's trigram index (P2.3).
        builder.HasIndex(message => message.Content).HasMethod("gin").HasOperators("gin_trgm_ops");
    }

    private static void ConfigureDirectMessageHiddenForUser(EntityTypeBuilder<DirectMessageHiddenForUser> builder)
    {
        builder.ToTable("DirectMessageHiddenForUser");

        builder.HasKey(hidden => hidden.Id);

        builder.Property(hidden => hidden.Created).HasDefaultValueSql("now()");

        builder.HasIndex(hidden => new { hidden.DirectMessageId, hidden.UserId }).IsUnique();

        builder.HasOne<DirectMessage>().WithMany().HasForeignKey(hidden => hidden.DirectMessageId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<User>().WithMany().HasForeignKey(hidden => hidden.UserId).OnDelete(DeleteBehavior.Restrict);
    }

    private static void ConfigureDirectMessageReaction(EntityTypeBuilder<DirectMessageReaction> builder)
    {
        builder.ToTable("DirectMessageReaction");

        builder.HasKey(reaction => reaction.Id);

        builder.Property(reaction => reaction.Created).HasDefaultValueSql("now()");

        builder.Property(reaction => reaction.Emoji).IsRequired().HasMaxLength(32);

        builder.HasIndex(reaction => new { reaction.DirectMessageId, reaction.UserId, reaction.Emoji }).IsUnique();

        builder.HasOne<DirectMessage>().WithMany().HasForeignKey(reaction => reaction.DirectMessageId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<User>().WithMany().HasForeignKey(reaction => reaction.UserId).OnDelete(DeleteBehavior.Restrict);
    }

    private static void ConfigureDirectMessageMention(EntityTypeBuilder<DirectMessageMention> builder)
    {
        builder.ToTable("DirectMessageMention");

        builder.HasKey(mention => mention.Id);

        builder.Property(mention => mention.Created).HasDefaultValueSql("now()");

        builder.HasIndex(mention => new { mention.DirectMessageId, mention.MentionedUserId }).IsUnique();
        builder.HasIndex(mention => mention.MentionedUserId);

        builder.HasOne<DirectMessage>().WithMany().HasForeignKey(mention => mention.DirectMessageId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<User>().WithMany().HasForeignKey(mention => mention.MentionedUserId).OnDelete(DeleteBehavior.Restrict);
    }

    private static void ConfigureUserPresence(EntityTypeBuilder<UserPresence> builder)
    {
        builder.ToTable("UserPresence");

        builder.HasKey(presence => presence.UserId);

        builder.Property(presence => presence.Created).HasDefaultValueSql("now()");

        builder.HasOne<User>().WithMany().HasForeignKey(presence => presence.UserId).OnDelete(DeleteBehavior.Restrict);
    }

    private static void ConfigureNotification(EntityTypeBuilder<Notification> builder)
    {
        builder.ToTable("Notification");

        builder.HasKey(notification => notification.Id);

        builder.Property(notification => notification.Created).HasDefaultValueSql("now()");

        // Matches ModerationService's/ReportsService's ban/timeout/report reason ceiling.
        builder.Property(notification => notification.Reason).HasMaxLength(500);

        builder.HasOne<User>().WithMany().HasForeignKey(notification => notification.RecipientUserId).OnDelete(DeleteBehavior.Restrict);
        builder.HasOne<User>().WithMany().HasForeignKey(notification => notification.RelatedUserId).OnDelete(DeleteBehavior.Restrict);
        builder.HasOne<Server>().WithMany().HasForeignKey(notification => notification.ContextServerId).OnDelete(DeleteBehavior.SetNull);
        builder.HasOne<Channel>().WithMany().HasForeignKey(notification => notification.ContextChannelId).OnDelete(DeleteBehavior.SetNull);
        builder.HasOne<Conversation>().WithMany().HasForeignKey(notification => notification.ContextConversationId).OnDelete(DeleteBehavior.SetNull);
    }

    private static void ConfigureCall(EntityTypeBuilder<Call> builder)
    {
        builder.ToTable("Call");

        builder.HasKey(call => call.Id);

        builder.Property(call => call.Created).HasDefaultValueSql("now()");

        builder.HasIndex(call => call.ConversationId);

        builder.HasOne<Conversation>().WithMany().HasForeignKey(call => call.ConversationId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne<User>().WithMany().HasForeignKey(call => call.InitiatorId).OnDelete(DeleteBehavior.Restrict);
        builder.HasOne<User>().WithMany().HasForeignKey(call => call.CalleeId).OnDelete(DeleteBehavior.Restrict);
    }

    private static void ConfigureUploadedFile(EntityTypeBuilder<UploadedFile> builder)
    {
        builder.ToTable("UploadedFile");

        builder.HasKey(file => file.Id);

        builder.Property(file => file.Created).HasDefaultValueSql("now()");

        // Matches AvatarUrl's ceiling (ConfigureUser) - every URL this table stores comes from the
        // same FilesService.SaveFileAsync path.
        builder.Property(file => file.Url).IsRequired().HasMaxLength(2048);

        builder.HasIndex(file => file.Url).IsUnique();
        builder.HasIndex(file => file.UploaderUserId);

        builder.HasOne<User>()
            .WithMany()
            .HasForeignKey(file => file.UploaderUserId)
            .IsRequired()
            .OnDelete(DeleteBehavior.Restrict);
    }

    private static void ConfigureReport(EntityTypeBuilder<Report> builder)
    {
        builder.ToTable("Report");

        builder.HasKey(report => report.Id);

        builder.Property(report => report.Created).HasDefaultValueSql("now()");

        // Matches ModerationService's ban/timeout reason ceiling (MaxReasonLength = 500).
        builder.Property(report => report.Reason).IsRequired().HasMaxLength(500);

        // Read pattern is "give me the queue" (filtered by Status) and "who filed this" - both get
        // their own index rather than a composite, since either can be queried alone.
        builder.HasIndex(report => report.Status);
        builder.HasIndex(report => report.ReporterUserId);

        builder.HasOne<User>()
            .WithMany()
            .HasForeignKey(report => report.ReporterUserId)
            .IsRequired()
            .OnDelete(DeleteBehavior.Restrict);

        // Nullable, unset until reviewed; Restrict for the same reason every other actor FK on this
        // context is Restrict - an admin account is never expected to be hard-deleted out from under
        // rows that reference it.
        builder.HasOne<User>()
            .WithMany()
            .HasForeignKey(report => report.ResolvedByUserId)
            .OnDelete(DeleteBehavior.Restrict);

        // TargetId is deliberately not an FK - see the Report class doc comment.
    }

    private static void ConfigureAuditLog(EntityTypeBuilder<AuditLog> builder)
    {
        builder.ToTable("AuditLog");

        builder.HasKey(log => log.Id);

        builder.Property(log => log.Created).HasDefaultValueSql("now()");

        builder.Property(log => log.Action).IsRequired().HasMaxLength(64);
        builder.Property(log => log.TargetType).HasMaxLength(64);

        // The admin feed is read newest-first and commonly filtered by actor or by action; a composite
        // covering the default sort keeps both filtered and unfiltered reads off a full scan.
        builder.HasIndex(log => new { log.ActorUserId, log.Created });
        builder.HasIndex(log => new { log.Action, log.Created });

        builder.HasOne<User>()
            .WithMany()
            .HasForeignKey(log => log.ActorUserId)
            .IsRequired()
            .OnDelete(DeleteBehavior.Restrict);
    }

    private static void ConfigurePushToken(EntityTypeBuilder<PushToken> builder)
    {
        builder.ToTable("PushToken");

        builder.HasKey(token => token.Id);

        builder.Property(token => token.Created).HasDefaultValueSql("now()");

        builder.Property(token => token.Token).IsRequired().HasMaxLength(4096);

        // Unique on Token alone, not (UserId, Token) - see PushTokensService.RegisterAsync for why a
        // re-registration under a different account must reassign this row rather than duplicate it.
        builder.HasIndex(token => token.Token).IsUnique();
        builder.HasIndex(token => token.UserId);

        builder.HasOne<User>()
            .WithMany()
            .HasForeignKey(token => token.UserId)
            .IsRequired()
            .OnDelete(DeleteBehavior.Cascade);
    }

    private static void ConfigureSubscription(EntityTypeBuilder<Subscription> builder)
    {
        builder.ToTable("Subscription");

        builder.HasKey(subscription => subscription.Id);

        builder.Property(subscription => subscription.Created).HasDefaultValueSql("now()");

        builder.Property(subscription => subscription.StripeCustomerId).IsRequired();
        builder.Property(subscription => subscription.StripeSubscriptionId).IsRequired();

        // Idempotency backstop against concurrent webhook races - see BillingService's upsert.
        builder.HasIndex(subscription => subscription.StripeSubscriptionId).IsUnique();

        // Not unique - a user accumulates multiple historical rows across resubscribe cycles.
        builder.HasIndex(subscription => subscription.UserId);

        builder.HasOne<User>()
            .WithMany()
            .HasForeignKey(subscription => subscription.UserId)
            .OnDelete(DeleteBehavior.Restrict);
    }

    private static void ConfigureStarTransaction(EntityTypeBuilder<StarTransaction> builder)
    {
        builder.ToTable("StarTransaction");

        builder.HasKey(transaction => transaction.Id);

        builder.Property(transaction => transaction.Created).HasDefaultValueSql("now()");

        builder.Property(transaction => transaction.IdempotencyKey).HasMaxLength(100);

        // The ledger is read as "give me this user's history", newest first - a composite covering
        // that default sort keeps it off a full scan.
        builder.HasIndex(transaction => new { transaction.UserId, transaction.Created });

        // Idempotency backstop against duplicate transfer/trial-activation requests (see
        // StarsService) - scoped to rows that actually carry a key, since chat rewards and
        // webhook-driven package purchases never set one.
        builder.HasIndex(transaction => new { transaction.UserId, transaction.IdempotencyKey })
            .IsUnique()
            .HasFilter("\"IdempotencyKey\" IS NOT NULL");

        builder.HasOne<User>()
            .WithMany()
            .HasForeignKey(transaction => transaction.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne<User>()
            .WithMany()
            .HasForeignKey(transaction => transaction.CounterpartyUserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne<StarPurchase>()
            .WithMany()
            .HasForeignKey(transaction => transaction.RelatedPurchaseId)
            .OnDelete(DeleteBehavior.Restrict);
    }

    private static void ConfigureStarPurchase(EntityTypeBuilder<StarPurchase> builder)
    {
        builder.ToTable("StarPurchase");

        builder.HasKey(purchase => purchase.Id);

        builder.Property(purchase => purchase.Created).HasDefaultValueSql("now()");

        builder.Property(purchase => purchase.PackageId).IsRequired().HasMaxLength(64);
        builder.Property(purchase => purchase.Currency).IsRequired().HasMaxLength(8);
        builder.Property(purchase => purchase.PaymentProvider).IsRequired().HasMaxLength(32);
        builder.Property(purchase => purchase.StripeCheckoutSessionId).HasMaxLength(255);
        builder.Property(purchase => purchase.StripePaymentIntentId).HasMaxLength(255);

        // decimal defaults to (18,2) precision under Npgsql, which is exactly right for a two-decimal
        // currency amount - set explicitly so it's not left to the provider's own default-mapping
        // convention.
        builder.Property(purchase => purchase.PriceAmount).HasPrecision(18, 2);

        builder.HasIndex(purchase => purchase.UserId);
        builder.HasIndex(purchase => purchase.StripeCheckoutSessionId);

        builder.HasOne<User>()
            .WithMany()
            .HasForeignKey(purchase => purchase.UserId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
