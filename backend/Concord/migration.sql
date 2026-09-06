CREATE TABLE IF NOT EXISTS "__EFMigrationsHistory" (
    "MigrationId" character varying(150) NOT NULL,
    "ProductVersion" character varying(32) NOT NULL,
    CONSTRAINT "PK___EFMigrationsHistory" PRIMARY KEY ("MigrationId")
);

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260813112036_InitialCreate') THEN
    CREATE TYPE roles AS ENUM ('admin', 'user');
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260813112036_InitialCreate') THEN
    CREATE TABLE "User" (
        "Id" uuid NOT NULL,
        "PhoneNumber" character varying(30),
        "EmailConfirmed" boolean NOT NULL,
        "IsLocked" boolean NOT NULL,
        "Role" roles NOT NULL,
        "Locale" character varying(7) NOT NULL,
        "Password" character varying(100),
        "Disabled" timestamp with time zone,
        "FailedLoginAttempts" integer NOT NULL,
        "LockoutEnd" timestamp with time zone,
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_User" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260813112036_InitialCreate') THEN
    CREATE TABLE "Session" (
        "Id" uuid NOT NULL,
        "UserId" uuid NOT NULL,
        "AccessTokenId" uuid NOT NULL,
        "RefreshTokenId" uuid NOT NULL,
        "Refreshed" timestamp with time zone,
        "Expires" timestamp with time zone NOT NULL,
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_Session" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_Session_User_UserId" FOREIGN KEY ("UserId") REFERENCES "User" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260813112036_InitialCreate') THEN
    CREATE INDEX "IX_Session_UserId" ON "Session" ("UserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260813112036_InitialCreate') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260813112036_InitialCreate', '10.0.11');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260813113730_FixUserMapping') THEN
    ALTER TABLE "User" ADD "Email" text;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260813113730_FixUserMapping') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260813113730_FixUserMapping', '10.0.11');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260813131631_AddUserNameSurname') THEN
    ALTER TABLE "User" ADD "Name" character varying(100) NOT NULL DEFAULT '';
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260813131631_AddUserNameSurname') THEN
    ALTER TABLE "User" ADD "Surname" character varying(100) NOT NULL DEFAULT '';
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260813131631_AddUserNameSurname') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260813131631_AddUserNameSurname', '10.0.11');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260813140350_AddUsernameAvatarToUser') THEN
    ALTER TABLE "User" ADD "AvatarUrl" character varying(2048);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260813140350_AddUsernameAvatarToUser') THEN
    ALTER TABLE "User" ADD "Username" character varying(32);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260813140350_AddUsernameAvatarToUser') THEN
    CREATE UNIQUE INDEX "IX_User_Username" ON "User" ("Username");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260813140350_AddUsernameAvatarToUser') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260813140350_AddUsernameAvatarToUser', '10.0.11');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260813200142_AddFriendRequestsAndBlocks') THEN
    CREATE TYPE friend_request_status AS ENUM ('accepted', 'pending');
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260813200142_AddFriendRequestsAndBlocks') THEN
    CREATE TABLE "Block" (
        "Id" uuid NOT NULL,
        "BlockerId" uuid NOT NULL,
        "BlockedId" uuid NOT NULL,
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_Block" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_Block_User_BlockedId" FOREIGN KEY ("BlockedId") REFERENCES "User" ("Id") ON DELETE RESTRICT,
        CONSTRAINT "FK_Block_User_BlockerId" FOREIGN KEY ("BlockerId") REFERENCES "User" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260813200142_AddFriendRequestsAndBlocks') THEN
    CREATE TABLE "FriendRequest" (
        "Id" uuid NOT NULL,
        "RequesterId" uuid NOT NULL,
        "AddresseeId" uuid NOT NULL,
        "Status" friend_request_status NOT NULL,
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_FriendRequest" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_FriendRequest_User_AddresseeId" FOREIGN KEY ("AddresseeId") REFERENCES "User" ("Id") ON DELETE RESTRICT,
        CONSTRAINT "FK_FriendRequest_User_RequesterId" FOREIGN KEY ("RequesterId") REFERENCES "User" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260813200142_AddFriendRequestsAndBlocks') THEN
    CREATE INDEX "IX_Block_BlockedId" ON "Block" ("BlockedId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260813200142_AddFriendRequestsAndBlocks') THEN
    CREATE INDEX "IX_Block_BlockerId" ON "Block" ("BlockerId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260813200142_AddFriendRequestsAndBlocks') THEN
    CREATE INDEX "IX_FriendRequest_AddresseeId" ON "FriendRequest" ("AddresseeId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260813200142_AddFriendRequestsAndBlocks') THEN
    CREATE INDEX "IX_FriendRequest_RequesterId" ON "FriendRequest" ("RequesterId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260813200142_AddFriendRequestsAndBlocks') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260813200142_AddFriendRequestsAndBlocks', '10.0.11');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814070136_AddServersChannelsAndInvites') THEN
    CREATE TYPE channel_type AS ENUM ('text', 'voice');
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814070136_AddServersChannelsAndInvites') THEN
    CREATE TABLE "Server" (
        "Id" uuid NOT NULL,
        "Name" character varying(100) NOT NULL,
        "OwnerId" uuid NOT NULL,
        "IconUrl" character varying(2048),
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_Server" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_Server_User_OwnerId" FOREIGN KEY ("OwnerId") REFERENCES "User" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814070136_AddServersChannelsAndInvites') THEN
    CREATE TABLE "Channel" (
        "Id" uuid NOT NULL,
        "ServerId" uuid NOT NULL,
        "Name" character varying(100) NOT NULL,
        "Type" channel_type NOT NULL,
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_Channel" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_Channel_Server_ServerId" FOREIGN KEY ("ServerId") REFERENCES "Server" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814070136_AddServersChannelsAndInvites') THEN
    CREATE TABLE "Invite" (
        "Id" uuid NOT NULL,
        "ServerId" uuid NOT NULL,
        "Code" character varying(16) NOT NULL,
        "CreatedByUserId" uuid NOT NULL,
        "ExpiresAtUtc" timestamp with time zone,
        "MaxUses" integer,
        "UseCount" integer NOT NULL,
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_Invite" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_Invite_Server_ServerId" FOREIGN KEY ("ServerId") REFERENCES "Server" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_Invite_User_CreatedByUserId" FOREIGN KEY ("CreatedByUserId") REFERENCES "User" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814070136_AddServersChannelsAndInvites') THEN
    CREATE TABLE "ServerMember" (
        "Id" uuid NOT NULL,
        "ServerId" uuid NOT NULL,
        "UserId" uuid NOT NULL,
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_ServerMember" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_ServerMember_Server_ServerId" FOREIGN KEY ("ServerId") REFERENCES "Server" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_ServerMember_User_UserId" FOREIGN KEY ("UserId") REFERENCES "User" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814070136_AddServersChannelsAndInvites') THEN
    CREATE INDEX "IX_Channel_ServerId" ON "Channel" ("ServerId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814070136_AddServersChannelsAndInvites') THEN
    CREATE UNIQUE INDEX "IX_Invite_Code" ON "Invite" ("Code");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814070136_AddServersChannelsAndInvites') THEN
    CREATE INDEX "IX_Invite_CreatedByUserId" ON "Invite" ("CreatedByUserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814070136_AddServersChannelsAndInvites') THEN
    CREATE INDEX "IX_Invite_ServerId" ON "Invite" ("ServerId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814070136_AddServersChannelsAndInvites') THEN
    CREATE INDEX "IX_Server_OwnerId" ON "Server" ("OwnerId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814070136_AddServersChannelsAndInvites') THEN
    CREATE UNIQUE INDEX "IX_ServerMember_ServerId_UserId" ON "ServerMember" ("ServerId", "UserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814070136_AddServersChannelsAndInvites') THEN
    CREATE INDEX "IX_ServerMember_UserId" ON "ServerMember" ("UserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814070136_AddServersChannelsAndInvites') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260814070136_AddServersChannelsAndInvites', '10.0.11');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814075420_AddMessagesAndHiddenMessages') THEN
    CREATE TABLE "Message" (
        "Id" uuid NOT NULL,
        "ChannelId" uuid NOT NULL,
        "SenderId" uuid NOT NULL,
        "Content" text NOT NULL,
        "EditedAtUtc" timestamp with time zone,
        "AttachmentUrl" character varying(2048),
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_Message" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_Message_Channel_ChannelId" FOREIGN KEY ("ChannelId") REFERENCES "Channel" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_Message_User_SenderId" FOREIGN KEY ("SenderId") REFERENCES "User" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814075420_AddMessagesAndHiddenMessages') THEN
    CREATE TABLE "MessageHiddenForUser" (
        "Id" uuid NOT NULL,
        "MessageId" uuid NOT NULL,
        "UserId" uuid NOT NULL,
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_MessageHiddenForUser" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_MessageHiddenForUser_Message_MessageId" FOREIGN KEY ("MessageId") REFERENCES "Message" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_MessageHiddenForUser_User_UserId" FOREIGN KEY ("UserId") REFERENCES "User" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814075420_AddMessagesAndHiddenMessages') THEN
    CREATE INDEX "IX_Message_ChannelId" ON "Message" ("ChannelId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814075420_AddMessagesAndHiddenMessages') THEN
    CREATE INDEX "IX_Message_SenderId" ON "Message" ("SenderId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814075420_AddMessagesAndHiddenMessages') THEN
    CREATE UNIQUE INDEX "IX_MessageHiddenForUser_MessageId_UserId" ON "MessageHiddenForUser" ("MessageId", "UserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814075420_AddMessagesAndHiddenMessages') THEN
    CREATE INDEX "IX_MessageHiddenForUser_UserId" ON "MessageHiddenForUser" ("UserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814075420_AddMessagesAndHiddenMessages') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260814075420_AddMessagesAndHiddenMessages', '10.0.11');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814084446_AddUserPresence') THEN
    CREATE TYPE presence_status AS ENUM ('idle', 'offline', 'online');
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814084446_AddUserPresence') THEN
    CREATE TABLE "UserPresence" (
        "UserId" uuid NOT NULL,
        "Status" presence_status NOT NULL,
        "LastSeenAt" timestamp with time zone,
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_UserPresence" PRIMARY KEY ("UserId"),
        CONSTRAINT "FK_UserPresence_User_UserId" FOREIGN KEY ("UserId") REFERENCES "User" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814084446_AddUserPresence') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260814084446_AddUserPresence', '10.0.11');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814095134_AddNotifications') THEN
    CREATE TYPE notification_type AS ENUM ('friend_request_accepted', 'friend_request_received');
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814095134_AddNotifications') THEN
    CREATE TABLE "Notification" (
        "Id" uuid NOT NULL,
        "RecipientUserId" uuid NOT NULL,
        "Type" notification_type NOT NULL,
        "RelatedUserId" uuid,
        "IsRead" boolean NOT NULL,
        "ReadAt" timestamp with time zone,
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_Notification" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_Notification_User_RecipientUserId" FOREIGN KEY ("RecipientUserId") REFERENCES "User" ("Id") ON DELETE RESTRICT,
        CONSTRAINT "FK_Notification_User_RelatedUserId" FOREIGN KEY ("RelatedUserId") REFERENCES "User" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814095134_AddNotifications') THEN
    CREATE INDEX "IX_Notification_RecipientUserId" ON "Notification" ("RecipientUserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814095134_AddNotifications') THEN
    CREATE INDEX "IX_Notification_RelatedUserId" ON "Notification" ("RelatedUserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814095134_AddNotifications') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260814095134_AddNotifications', '10.0.11');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814185416_AddEmailUniqueIndexAndMessageContentCap') THEN
    ALTER TABLE "Message" ALTER COLUMN "Content" TYPE character varying(4000);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814185416_AddEmailUniqueIndexAndMessageContentCap') THEN
    CREATE UNIQUE INDEX "IX_User_Email" ON "User" ("Email");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260814185416_AddEmailUniqueIndexAndMessageContentCap') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260814185416_AddEmailUniqueIndexAndMessageContentCap', '10.0.11');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260816055821_AddDirectMessages') THEN
    CREATE TABLE "Conversation" (
        "Id" uuid NOT NULL,
        "UserAId" uuid NOT NULL,
        "UserBId" uuid NOT NULL,
        "LastMessageAt" timestamp with time zone,
        "LastReadAtA" timestamp with time zone,
        "LastReadAtB" timestamp with time zone,
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_Conversation" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_Conversation_User_UserAId" FOREIGN KEY ("UserAId") REFERENCES "User" ("Id") ON DELETE RESTRICT,
        CONSTRAINT "FK_Conversation_User_UserBId" FOREIGN KEY ("UserBId") REFERENCES "User" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260816055821_AddDirectMessages') THEN
    CREATE TABLE "DirectMessage" (
        "Id" uuid NOT NULL,
        "ConversationId" uuid NOT NULL,
        "SenderId" uuid NOT NULL,
        "Content" character varying(4000) NOT NULL,
        "EditedAtUtc" timestamp with time zone,
        "AttachmentUrl" character varying(2048),
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_DirectMessage" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_DirectMessage_Conversation_ConversationId" FOREIGN KEY ("ConversationId") REFERENCES "Conversation" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_DirectMessage_User_SenderId" FOREIGN KEY ("SenderId") REFERENCES "User" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260816055821_AddDirectMessages') THEN
    CREATE TABLE "DirectMessageHiddenForUser" (
        "Id" uuid NOT NULL,
        "DirectMessageId" uuid NOT NULL,
        "UserId" uuid NOT NULL,
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_DirectMessageHiddenForUser" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_DirectMessageHiddenForUser_DirectMessage_DirectMessageId" FOREIGN KEY ("DirectMessageId") REFERENCES "DirectMessage" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_DirectMessageHiddenForUser_User_UserId" FOREIGN KEY ("UserId") REFERENCES "User" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260816055821_AddDirectMessages') THEN
    CREATE INDEX "IX_Conversation_UserAId" ON "Conversation" ("UserAId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260816055821_AddDirectMessages') THEN
    CREATE UNIQUE INDEX "IX_Conversation_UserAId_UserBId" ON "Conversation" ("UserAId", "UserBId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260816055821_AddDirectMessages') THEN
    CREATE INDEX "IX_Conversation_UserBId" ON "Conversation" ("UserBId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260816055821_AddDirectMessages') THEN
    CREATE INDEX "IX_DirectMessage_ConversationId" ON "DirectMessage" ("ConversationId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260816055821_AddDirectMessages') THEN
    CREATE INDEX "IX_DirectMessage_SenderId" ON "DirectMessage" ("SenderId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260816055821_AddDirectMessages') THEN
    CREATE UNIQUE INDEX "IX_DirectMessageHiddenForUser_DirectMessageId_UserId" ON "DirectMessageHiddenForUser" ("DirectMessageId", "UserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260816055821_AddDirectMessages') THEN
    CREATE INDEX "IX_DirectMessageHiddenForUser_UserId" ON "DirectMessageHiddenForUser" ("UserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260816055821_AddDirectMessages') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260816055821_AddDirectMessages', '10.0.11');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260816144905_AddMessageReplyTo') THEN
    ALTER TABLE "Message" ADD "ReplyToMessageId" uuid;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260816144905_AddMessageReplyTo') THEN
    ALTER TABLE "DirectMessage" ADD "ReplyToMessageId" uuid;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260816144905_AddMessageReplyTo') THEN
    CREATE INDEX "IX_Message_ReplyToMessageId" ON "Message" ("ReplyToMessageId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260816144905_AddMessageReplyTo') THEN
    CREATE INDEX "IX_DirectMessage_ReplyToMessageId" ON "DirectMessage" ("ReplyToMessageId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260816144905_AddMessageReplyTo') THEN
    ALTER TABLE "DirectMessage" ADD CONSTRAINT "FK_DirectMessage_DirectMessage_ReplyToMessageId" FOREIGN KEY ("ReplyToMessageId") REFERENCES "DirectMessage" ("Id") ON DELETE SET NULL;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260816144905_AddMessageReplyTo') THEN
    ALTER TABLE "Message" ADD CONSTRAINT "FK_Message_Message_ReplyToMessageId" FOREIGN KEY ("ReplyToMessageId") REFERENCES "Message" ("Id") ON DELETE SET NULL;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260816144905_AddMessageReplyTo') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260816144905_AddMessageReplyTo', '10.0.11');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260816145754_AddChannelReadState') THEN
    CREATE TABLE "ChannelReadState" (
        "Id" uuid NOT NULL,
        "ChannelId" uuid NOT NULL,
        "UserId" uuid NOT NULL,
        "LastReadAtUtc" timestamp with time zone NOT NULL,
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_ChannelReadState" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_ChannelReadState_Channel_ChannelId" FOREIGN KEY ("ChannelId") REFERENCES "Channel" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_ChannelReadState_User_UserId" FOREIGN KEY ("UserId") REFERENCES "User" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260816145754_AddChannelReadState') THEN
    CREATE UNIQUE INDEX "IX_ChannelReadState_ChannelId_UserId" ON "ChannelReadState" ("ChannelId", "UserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260816145754_AddChannelReadState') THEN
    CREATE INDEX "IX_ChannelReadState_UserId" ON "ChannelReadState" ("UserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260816145754_AddChannelReadState') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260816145754_AddChannelReadState', '10.0.11');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260816150347_AddMessageReactions') THEN
    CREATE TABLE "DirectMessageReaction" (
        "Id" uuid NOT NULL,
        "DirectMessageId" uuid NOT NULL,
        "UserId" uuid NOT NULL,
        "Emoji" character varying(32) NOT NULL,
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_DirectMessageReaction" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_DirectMessageReaction_DirectMessage_DirectMessageId" FOREIGN KEY ("DirectMessageId") REFERENCES "DirectMessage" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_DirectMessageReaction_User_UserId" FOREIGN KEY ("UserId") REFERENCES "User" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260816150347_AddMessageReactions') THEN
    CREATE TABLE "MessageReaction" (
        "Id" uuid NOT NULL,
        "MessageId" uuid NOT NULL,
        "UserId" uuid NOT NULL,
        "Emoji" character varying(32) NOT NULL,
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_MessageReaction" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_MessageReaction_Message_MessageId" FOREIGN KEY ("MessageId") REFERENCES "Message" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_MessageReaction_User_UserId" FOREIGN KEY ("UserId") REFERENCES "User" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260816150347_AddMessageReactions') THEN
    CREATE UNIQUE INDEX "IX_DirectMessageReaction_DirectMessageId_UserId_Emoji" ON "DirectMessageReaction" ("DirectMessageId", "UserId", "Emoji");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260816150347_AddMessageReactions') THEN
    CREATE INDEX "IX_DirectMessageReaction_UserId" ON "DirectMessageReaction" ("UserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260816150347_AddMessageReactions') THEN
    CREATE UNIQUE INDEX "IX_MessageReaction_MessageId_UserId_Emoji" ON "MessageReaction" ("MessageId", "UserId", "Emoji");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260816150347_AddMessageReactions') THEN
    CREATE INDEX "IX_MessageReaction_UserId" ON "MessageReaction" ("UserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260816150347_AddMessageReactions') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260816150347_AddMessageReactions', '10.0.11');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819082310_AddSessionAndUserPreferences') THEN
    ALTER TYPE notification_type ADD VALUE 'missed_call';
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819082310_AddSessionAndUserPreferences') THEN
    ALTER TABLE "User" ADD "NotificationsMuted" boolean NOT NULL DEFAULT FALSE;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819082310_AddSessionAndUserPreferences') THEN
    ALTER TABLE "User" ADD "NotificationsSoundEnabled" boolean NOT NULL DEFAULT TRUE;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819082310_AddSessionAndUserPreferences') THEN
    ALTER TABLE "Session" ADD "Browser" character varying(100);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819082310_AddSessionAndUserPreferences') THEN
    ALTER TABLE "Session" ADD "DeviceLabel" character varying(200);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819082310_AddSessionAndUserPreferences') THEN
    ALTER TABLE "Session" ADD "IpAddress" character varying(45);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819082310_AddSessionAndUserPreferences') THEN
    ALTER TABLE "Session" ADD "OS" character varying(100);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819082310_AddSessionAndUserPreferences') THEN
    ALTER TABLE "Session" ADD "UserAgent" character varying(512);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819082310_AddSessionAndUserPreferences') THEN
    CREATE TABLE "Call" (
        "Id" uuid NOT NULL,
        "ConversationId" uuid NOT NULL,
        "InitiatorId" uuid NOT NULL,
        "CalleeId" uuid NOT NULL,
        "Type" integer NOT NULL,
        "Status" integer NOT NULL,
        "AnsweredAt" timestamp with time zone,
        "EndedAt" timestamp with time zone,
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_Call" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_Call_Conversation_ConversationId" FOREIGN KEY ("ConversationId") REFERENCES "Conversation" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_Call_User_CalleeId" FOREIGN KEY ("CalleeId") REFERENCES "User" ("Id") ON DELETE RESTRICT,
        CONSTRAINT "FK_Call_User_InitiatorId" FOREIGN KEY ("InitiatorId") REFERENCES "User" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819082310_AddSessionAndUserPreferences') THEN
    CREATE INDEX "IX_Call_CalleeId" ON "Call" ("CalleeId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819082310_AddSessionAndUserPreferences') THEN
    CREATE INDEX "IX_Call_ConversationId" ON "Call" ("ConversationId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819082310_AddSessionAndUserPreferences') THEN
    CREATE INDEX "IX_Call_InitiatorId" ON "Call" ("InitiatorId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819082310_AddSessionAndUserPreferences') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260819082310_AddSessionAndUserPreferences', '10.0.11');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819091703_AddPresenceStatusesAndUserPrivacy') THEN
    ALTER TYPE presence_status ADD VALUE 'do_not_disturb' BEFORE 'idle';
    ALTER TYPE presence_status ADD VALUE 'invisible' AFTER 'idle';
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819091703_AddPresenceStatusesAndUserPrivacy') THEN
    ALTER TABLE "User" ADD "ActivityVisibility" integer NOT NULL DEFAULT 0;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819091703_AddPresenceStatusesAndUserPrivacy') THEN
    ALTER TABLE "User" ADD "CustomStatusEmoji" character varying(16);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819091703_AddPresenceStatusesAndUserPrivacy') THEN
    ALTER TABLE "User" ADD "CustomStatusExpiresAt" timestamp with time zone;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819091703_AddPresenceStatusesAndUserPrivacy') THEN
    ALTER TABLE "User" ADD "CustomStatusText" character varying(128);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819091703_AddPresenceStatusesAndUserPrivacy') THEN
    ALTER TABLE "User" ADD "DirectMessagePrivacy" integer NOT NULL DEFAULT 1;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819091703_AddPresenceStatusesAndUserPrivacy') THEN
    ALTER TABLE "User" ADD "FriendRequestPrivacy" integer NOT NULL DEFAULT 0;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819091703_AddPresenceStatusesAndUserPrivacy') THEN
    ALTER TABLE "User" ADD "ReadReceiptsEnabled" boolean NOT NULL DEFAULT TRUE;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819091703_AddPresenceStatusesAndUserPrivacy') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260819091703_AddPresenceStatusesAndUserPrivacy', '10.0.11');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    ALTER TYPE notification_type ADD VALUE 'mention' AFTER 'friend_request_received';
    CREATE EXTENSION IF NOT EXISTS pg_trgm;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    ALTER TABLE "User" ADD "ActivityApplicationName" character varying(128);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    ALTER TABLE "User" ADD "ActivityStartedAt" timestamp with time zone;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    ALTER TABLE "User" ADD "ActivityType" integer;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    ALTER TABLE "Notification" ADD "ContextChannelId" uuid;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    ALTER TABLE "Notification" ADD "ContextConversationId" uuid;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    ALTER TABLE "Notification" ADD "ContextMessageId" uuid;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    ALTER TABLE "Message" ADD "ForwardedFromCreatedAt" timestamp with time zone;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    ALTER TABLE "Message" ADD "ForwardedFromSenderId" uuid;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    ALTER TABLE "Message" ADD "PinnedAt" timestamp with time zone;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    ALTER TABLE "Message" ADD "PinnedByUserId" uuid;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    ALTER TABLE "DirectMessage" ADD "ForwardedFromCreatedAt" timestamp with time zone;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    ALTER TABLE "DirectMessage" ADD "ForwardedFromSenderId" uuid;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    ALTER TABLE "DirectMessage" ADD "PinnedAt" timestamp with time zone;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    ALTER TABLE "DirectMessage" ADD "PinnedByUserId" uuid;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    CREATE TABLE "DirectMessageMention" (
        "Id" uuid NOT NULL,
        "DirectMessageId" uuid NOT NULL,
        "MentionedUserId" uuid NOT NULL,
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_DirectMessageMention" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_DirectMessageMention_DirectMessage_DirectMessageId" FOREIGN KEY ("DirectMessageId") REFERENCES "DirectMessage" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_DirectMessageMention_User_MentionedUserId" FOREIGN KEY ("MentionedUserId") REFERENCES "User" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    CREATE TABLE "MessageMention" (
        "Id" uuid NOT NULL,
        "MessageId" uuid NOT NULL,
        "MentionedUserId" uuid NOT NULL,
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_MessageMention" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_MessageMention_Message_MessageId" FOREIGN KEY ("MessageId") REFERENCES "Message" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_MessageMention_User_MentionedUserId" FOREIGN KEY ("MentionedUserId") REFERENCES "User" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    CREATE INDEX "IX_Notification_ContextChannelId" ON "Notification" ("ContextChannelId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    CREATE INDEX "IX_Notification_ContextConversationId" ON "Notification" ("ContextConversationId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    CREATE INDEX "IX_Message_Content" ON "Message" USING gin ("Content" gin_trgm_ops);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    CREATE INDEX "IX_Message_ForwardedFromSenderId" ON "Message" ("ForwardedFromSenderId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    CREATE INDEX "IX_Message_PinnedByUserId" ON "Message" ("PinnedByUserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    CREATE INDEX "IX_DirectMessage_Content" ON "DirectMessage" USING gin ("Content" gin_trgm_ops);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    CREATE INDEX "IX_DirectMessage_ForwardedFromSenderId" ON "DirectMessage" ("ForwardedFromSenderId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    CREATE INDEX "IX_DirectMessage_PinnedByUserId" ON "DirectMessage" ("PinnedByUserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    CREATE UNIQUE INDEX "IX_DirectMessageMention_DirectMessageId_MentionedUserId" ON "DirectMessageMention" ("DirectMessageId", "MentionedUserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    CREATE INDEX "IX_DirectMessageMention_MentionedUserId" ON "DirectMessageMention" ("MentionedUserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    CREATE INDEX "IX_MessageMention_MentionedUserId" ON "MessageMention" ("MentionedUserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    CREATE UNIQUE INDEX "IX_MessageMention_MessageId_MentionedUserId" ON "MessageMention" ("MessageId", "MentionedUserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    ALTER TABLE "DirectMessage" ADD CONSTRAINT "FK_DirectMessage_User_ForwardedFromSenderId" FOREIGN KEY ("ForwardedFromSenderId") REFERENCES "User" ("Id") ON DELETE SET NULL;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    ALTER TABLE "DirectMessage" ADD CONSTRAINT "FK_DirectMessage_User_PinnedByUserId" FOREIGN KEY ("PinnedByUserId") REFERENCES "User" ("Id") ON DELETE SET NULL;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    ALTER TABLE "Message" ADD CONSTRAINT "FK_Message_User_ForwardedFromSenderId" FOREIGN KEY ("ForwardedFromSenderId") REFERENCES "User" ("Id") ON DELETE SET NULL;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    ALTER TABLE "Message" ADD CONSTRAINT "FK_Message_User_PinnedByUserId" FOREIGN KEY ("PinnedByUserId") REFERENCES "User" ("Id") ON DELETE SET NULL;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    ALTER TABLE "Notification" ADD CONSTRAINT "FK_Notification_Channel_ContextChannelId" FOREIGN KEY ("ContextChannelId") REFERENCES "Channel" ("Id") ON DELETE SET NULL;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    ALTER TABLE "Notification" ADD CONSTRAINT "FK_Notification_Conversation_ContextConversationId" FOREIGN KEY ("ContextConversationId") REFERENCES "Conversation" ("Id") ON DELETE SET NULL;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819112010_P2Features') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260819112010_P2Features', '10.0.11');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819120929_AddMentionNotificationServerContext') THEN
    ALTER TABLE "Notification" ADD "ContextServerId" uuid;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819120929_AddMentionNotificationServerContext') THEN
    CREATE INDEX "IX_Notification_ContextServerId" ON "Notification" ("ContextServerId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819120929_AddMentionNotificationServerContext') THEN
    ALTER TABLE "Notification" ADD CONSTRAINT "FK_Notification_Server_ContextServerId" FOREIGN KEY ("ContextServerId") REFERENCES "Server" ("Id") ON DELETE SET NULL;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260819120929_AddMentionNotificationServerContext') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260819120929_AddMentionNotificationServerContext', '10.0.11');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260821062205_AddRememberMeAndPasswordResetToken') THEN
    ALTER TABLE "Session" ADD "IsPersistent" boolean NOT NULL DEFAULT FALSE;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260821062205_AddRememberMeAndPasswordResetToken') THEN
    CREATE TABLE "PasswordResetToken" (
        "Id" uuid NOT NULL,
        "UserId" uuid NOT NULL,
        "TokenHash" character varying(64) NOT NULL,
        "ExpiresAt" timestamp with time zone NOT NULL,
        "Used" boolean NOT NULL,
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_PasswordResetToken" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_PasswordResetToken_User_UserId" FOREIGN KEY ("UserId") REFERENCES "User" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260821062205_AddRememberMeAndPasswordResetToken') THEN
    CREATE UNIQUE INDEX "IX_PasswordResetToken_TokenHash" ON "PasswordResetToken" ("TokenHash");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260821062205_AddRememberMeAndPasswordResetToken') THEN
    CREATE INDEX "IX_PasswordResetToken_UserId" ON "PasswordResetToken" ("UserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260821062205_AddRememberMeAndPasswordResetToken') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260821062205_AddRememberMeAndPasswordResetToken', '10.0.11');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260828065524_AddGranularRoles') THEN
    CREATE TABLE "Role" (
        "Id" uuid NOT NULL,
        "ServerId" uuid NOT NULL,
        "Name" character varying(100) NOT NULL,
        "Color" character varying(7),
        "Permissions" bigint NOT NULL,
        "Position" integer NOT NULL,
        "IsDefault" boolean NOT NULL,
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_Role" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_Role_Server_ServerId" FOREIGN KEY ("ServerId") REFERENCES "Server" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260828065524_AddGranularRoles') THEN
    CREATE TABLE "ServerMemberRole" (
        "Id" uuid NOT NULL,
        "ServerMemberId" uuid NOT NULL,
        "RoleId" uuid NOT NULL,
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_ServerMemberRole" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_ServerMemberRole_Role_RoleId" FOREIGN KEY ("RoleId") REFERENCES "Role" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_ServerMemberRole_ServerMember_ServerMemberId" FOREIGN KEY ("ServerMemberId") REFERENCES "ServerMember" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260828065524_AddGranularRoles') THEN
    CREATE UNIQUE INDEX "IX_Role_ServerId_Default" ON "Role" ("ServerId") WHERE "IsDefault";
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260828065524_AddGranularRoles') THEN
    CREATE INDEX "IX_Role_ServerId_Position" ON "Role" ("ServerId", "Position");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260828065524_AddGranularRoles') THEN
    CREATE INDEX "IX_ServerMemberRole_RoleId" ON "ServerMemberRole" ("RoleId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260828065524_AddGranularRoles') THEN
    CREATE UNIQUE INDEX "IX_ServerMemberRole_ServerMemberId_RoleId" ON "ServerMemberRole" ("ServerMemberId", "RoleId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260828065524_AddGranularRoles') THEN
    INSERT INTO "Role" ("Id", "ServerId", "Name", "Color", "Permissions", "Position", "IsDefault", "Created")
    SELECT gen_random_uuid(), server."Id", '@everyone', NULL, 6147, 0, TRUE, now()
    FROM "Server" AS server
    WHERE NOT EXISTS (
        SELECT 1 FROM "Role" AS role WHERE role."ServerId" = server."Id" AND role."IsDefault"
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260828065524_AddGranularRoles') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260828065524_AddGranularRoles', '10.0.11');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260828072955_AddModeration') THEN
    ALTER TABLE "ServerMember" ADD "IsMuted" boolean NOT NULL DEFAULT FALSE;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260828072955_AddModeration') THEN
    ALTER TABLE "ServerMember" ADD "TimedOutByUserId" uuid;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260828072955_AddModeration') THEN
    ALTER TABLE "ServerMember" ADD "TimedOutUntil" timestamp with time zone;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260828072955_AddModeration') THEN
    ALTER TABLE "ServerMember" ADD "TimeoutReason" character varying(500);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260828072955_AddModeration') THEN
    CREATE TABLE "ServerBan" (
        "Id" uuid NOT NULL,
        "ServerId" uuid NOT NULL,
        "UserId" uuid NOT NULL,
        "BannedByUserId" uuid NOT NULL,
        "Reason" character varying(500),
        "ExpiresAtUtc" timestamp with time zone,
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_ServerBan" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_ServerBan_Server_ServerId" FOREIGN KEY ("ServerId") REFERENCES "Server" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_ServerBan_User_BannedByUserId" FOREIGN KEY ("BannedByUserId") REFERENCES "User" ("Id") ON DELETE RESTRICT,
        CONSTRAINT "FK_ServerBan_User_UserId" FOREIGN KEY ("UserId") REFERENCES "User" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260828072955_AddModeration') THEN
    CREATE INDEX "IX_ServerBan_BannedByUserId" ON "ServerBan" ("BannedByUserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260828072955_AddModeration') THEN
    CREATE UNIQUE INDEX "IX_ServerBan_ServerId_UserId" ON "ServerBan" ("ServerId", "UserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260828072955_AddModeration') THEN
    CREATE INDEX "IX_ServerBan_UserId" ON "ServerBan" ("UserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260828072955_AddModeration') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260828072955_AddModeration', '10.0.11');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260828074907_AddTwoFactorAuthentication') THEN
    ALTER TABLE "User" ADD "TwoFactorEnabled" boolean NOT NULL DEFAULT FALSE;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260828074907_AddTwoFactorAuthentication') THEN
    ALTER TABLE "User" ADD "TwoFactorEnabledAt" timestamp with time zone;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260828074907_AddTwoFactorAuthentication') THEN
    ALTER TABLE "User" ADD "TwoFactorLastUsedStep" bigint;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260828074907_AddTwoFactorAuthentication') THEN
    ALTER TABLE "User" ADD "TwoFactorSecret" character varying(64);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260828074907_AddTwoFactorAuthentication') THEN
    CREATE TABLE "TwoFactorRecoveryCode" (
        "Id" uuid NOT NULL,
        "UserId" uuid NOT NULL,
        "CodeHash" character varying(100) NOT NULL,
        "UsedAt" timestamp with time zone,
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_TwoFactorRecoveryCode" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_TwoFactorRecoveryCode_User_UserId" FOREIGN KEY ("UserId") REFERENCES "User" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260828074907_AddTwoFactorAuthentication') THEN
    CREATE INDEX "IX_TwoFactorRecoveryCode_UserId" ON "TwoFactorRecoveryCode" ("UserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260828074907_AddTwoFactorAuthentication') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260828074907_AddTwoFactorAuthentication', '10.0.11');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260828094950_AddQrLogin') THEN
    CREATE TYPE qr_login_status AS ENUM ('approved', 'consumed', 'denied', 'pending');
    CREATE EXTENSION IF NOT EXISTS pg_trgm;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260828094950_AddQrLogin') THEN
    CREATE TABLE "QrLoginSession" (
        "Id" uuid NOT NULL,
        "UserCode" character varying(16) NOT NULL,
        "PollingTokenHash" character varying(64) NOT NULL,
        "Status" qr_login_status NOT NULL,
        "ApprovedByUserId" uuid,
        "ExpiresAtUtc" timestamp with time zone NOT NULL,
        "ConsumedAt" timestamp with time zone,
        "UserAgent" character varying(512),
        "IpAddress" character varying(45),
        "DeviceLabel" character varying(200),
        "Browser" character varying(100),
        "OS" character varying(100),
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_QrLoginSession" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_QrLoginSession_User_ApprovedByUserId" FOREIGN KEY ("ApprovedByUserId") REFERENCES "User" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260828094950_AddQrLogin') THEN
    CREATE INDEX "IX_QrLoginSession_ApprovedByUserId" ON "QrLoginSession" ("ApprovedByUserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260828094950_AddQrLogin') THEN
    CREATE UNIQUE INDEX "IX_QrLoginSession_PollingTokenHash" ON "QrLoginSession" ("PollingTokenHash");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260828094950_AddQrLogin') THEN
    CREATE UNIQUE INDEX "IX_QrLoginSession_UserCode" ON "QrLoginSession" ("UserCode");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260828094950_AddQrLogin') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260828094950_AddQrLogin', '10.0.11');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260829055524_AddFriendRequestCancelledDeclinedNotifications') THEN
    ALTER TYPE notification_type ADD VALUE 'friend_request_cancelled' AFTER 'friend_request_accepted';
    ALTER TYPE notification_type ADD VALUE 'friend_request_declined' AFTER 'friend_request_cancelled';
    CREATE EXTENSION IF NOT EXISTS pg_trgm;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260829055524_AddFriendRequestCancelledDeclinedNotifications') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260829055524_AddFriendRequestCancelledDeclinedNotifications', '10.0.11');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260830051211_AuditRemediation_EmailVerification_2FAEncryption_UploadedFiles') THEN
    ALTER TABLE "User" ALTER COLUMN "TwoFactorSecret" TYPE character varying(512);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260830051211_AuditRemediation_EmailVerification_2FAEncryption_UploadedFiles') THEN
    CREATE TABLE "EmailVerificationToken" (
        "Id" uuid NOT NULL,
        "UserId" uuid NOT NULL,
        "TokenHash" character varying(64) NOT NULL,
        "ExpiresAt" timestamp with time zone NOT NULL,
        "Used" boolean NOT NULL,
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_EmailVerificationToken" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_EmailVerificationToken_User_UserId" FOREIGN KEY ("UserId") REFERENCES "User" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260830051211_AuditRemediation_EmailVerification_2FAEncryption_UploadedFiles') THEN
    CREATE TABLE "UploadedFile" (
        "Id" uuid NOT NULL,
        "UploaderUserId" uuid NOT NULL,
        "Url" character varying(2048) NOT NULL,
        "Purpose" integer NOT NULL,
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_UploadedFile" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_UploadedFile_User_UploaderUserId" FOREIGN KEY ("UploaderUserId") REFERENCES "User" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260830051211_AuditRemediation_EmailVerification_2FAEncryption_UploadedFiles') THEN
    CREATE UNIQUE INDEX "IX_EmailVerificationToken_TokenHash" ON "EmailVerificationToken" ("TokenHash");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260830051211_AuditRemediation_EmailVerification_2FAEncryption_UploadedFiles') THEN
    CREATE INDEX "IX_EmailVerificationToken_UserId" ON "EmailVerificationToken" ("UserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260830051211_AuditRemediation_EmailVerification_2FAEncryption_UploadedFiles') THEN
    CREATE INDEX "IX_UploadedFile_UploaderUserId" ON "UploadedFile" ("UploaderUserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260830051211_AuditRemediation_EmailVerification_2FAEncryption_UploadedFiles') THEN
    CREATE UNIQUE INDEX "IX_UploadedFile_Url" ON "UploadedFile" ("Url");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260830051211_AuditRemediation_EmailVerification_2FAEncryption_UploadedFiles') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260830051211_AuditRemediation_EmailVerification_2FAEncryption_UploadedFiles', '10.0.11');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260830052724_AddReportsAuditLogPushTokens') THEN
    CREATE TABLE "AuditLog" (
        "Id" uuid NOT NULL,
        "ActorUserId" uuid NOT NULL,
        "Action" character varying(64) NOT NULL,
        "TargetType" character varying(64),
        "TargetId" uuid,
        "Metadata" text,
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_AuditLog" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_AuditLog_User_ActorUserId" FOREIGN KEY ("ActorUserId") REFERENCES "User" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260830052724_AddReportsAuditLogPushTokens') THEN
    CREATE TABLE "PushToken" (
        "Id" uuid NOT NULL,
        "UserId" uuid NOT NULL,
        "Token" character varying(4096) NOT NULL,
        "Platform" integer NOT NULL,
        "LastSeenUtc" timestamp with time zone NOT NULL,
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_PushToken" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_PushToken_User_UserId" FOREIGN KEY ("UserId") REFERENCES "User" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260830052724_AddReportsAuditLogPushTokens') THEN
    CREATE TABLE "Report" (
        "Id" uuid NOT NULL,
        "ReporterUserId" uuid NOT NULL,
        "TargetType" integer NOT NULL,
        "TargetId" uuid NOT NULL,
        "Reason" character varying(500) NOT NULL,
        "Status" integer NOT NULL,
        "ResolvedByUserId" uuid,
        "ResolvedAtUtc" timestamp with time zone,
        "Created" timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_Report" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_Report_User_ReporterUserId" FOREIGN KEY ("ReporterUserId") REFERENCES "User" ("Id") ON DELETE RESTRICT,
        CONSTRAINT "FK_Report_User_ResolvedByUserId" FOREIGN KEY ("ResolvedByUserId") REFERENCES "User" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260830052724_AddReportsAuditLogPushTokens') THEN
    CREATE INDEX "IX_AuditLog_Action_Created" ON "AuditLog" ("Action", "Created");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260830052724_AddReportsAuditLogPushTokens') THEN
    CREATE INDEX "IX_AuditLog_ActorUserId_Created" ON "AuditLog" ("ActorUserId", "Created");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260830052724_AddReportsAuditLogPushTokens') THEN
    CREATE UNIQUE INDEX "IX_PushToken_Token" ON "PushToken" ("Token");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260830052724_AddReportsAuditLogPushTokens') THEN
    CREATE INDEX "IX_PushToken_UserId" ON "PushToken" ("UserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260830052724_AddReportsAuditLogPushTokens') THEN
    CREATE INDEX "IX_Report_ReporterUserId" ON "Report" ("ReporterUserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260830052724_AddReportsAuditLogPushTokens') THEN
    CREATE INDEX "IX_Report_ResolvedByUserId" ON "Report" ("ResolvedByUserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260830052724_AddReportsAuditLogPushTokens') THEN
    CREATE INDEX "IX_Report_Status" ON "Report" ("Status");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260830052724_AddReportsAuditLogPushTokens') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260830052724_AddReportsAuditLogPushTokens', '10.0.11');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260830061026_AddMentionsEveryoneAndChannelPosition') THEN
    DROP INDEX "IX_Channel_ServerId";
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260830061026_AddMentionsEveryoneAndChannelPosition') THEN
    ALTER TABLE "Message" ADD "MentionsEveryone" boolean NOT NULL DEFAULT FALSE;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260830061026_AddMentionsEveryoneAndChannelPosition') THEN
    ALTER TABLE "Channel" ADD "Position" integer NOT NULL DEFAULT 0;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260830061026_AddMentionsEveryoneAndChannelPosition') THEN
    WITH ranked AS (
        SELECT "Id", ROW_NUMBER() OVER (PARTITION BY "ServerId", "Type" ORDER BY "Created", "Id") - 1 AS "NewPosition"
        FROM "Channel"
    )
    UPDATE "Channel"
    SET "Position" = ranked."NewPosition"
    FROM ranked
    WHERE "Channel"."Id" = ranked."Id";
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260830061026_AddMentionsEveryoneAndChannelPosition') THEN
    CREATE INDEX "IX_Channel_ServerId_Type_Position" ON "Channel" ("ServerId", "Type", "Position");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260830061026_AddMentionsEveryoneAndChannelPosition') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260830061026_AddMentionsEveryoneAndChannelPosition', '10.0.11');
    END IF;
END $EF$;
COMMIT;

