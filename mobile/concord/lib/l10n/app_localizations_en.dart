// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get errorCouldNotReachServer =>
      'Couldn\'t reach Concord — check your connection and try again.';

  @override
  String get errorServerTrouble =>
      'Concord is having trouble on its end right now. Please try again shortly.';

  @override
  String get errorSomethingWentWrong =>
      'Something went wrong. Please try again.';

  @override
  String get errorCantReachServer =>
      'Can\'t reach the server. Check your connection.';

  @override
  String get errorTooManyAttempts =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get errorAccountLocked =>
      'Your account is temporarily locked. Try again in a few minutes.';

  @override
  String get errorInvalidEmailPassword => 'Invalid email or password';

  @override
  String get errorSignInExpired =>
      'That sign-in attempt expired. Go back and enter your password again.';

  @override
  String get errorInvalidCode =>
      'That code is not valid. Check your authenticator app, or use a recovery code.';

  @override
  String get errorAccountExists => 'An account with that email already exists.';

  @override
  String get validationEmailRequired => 'Email is required';

  @override
  String get validationPasswordRequired => 'Password is required';

  @override
  String get validationNameRequired => 'Name is required';

  @override
  String get validationSurnameRequired => 'Surname is required';

  @override
  String get validationEmailInvalid => 'Enter a valid email address';

  @override
  String get validationPasswordMinLength =>
      'Password must be at least 8 characters';

  @override
  String get validationPasswordTooShortPeriod =>
      'Password must be at least 8 characters.';

  @override
  String get validationPasswordsDontMatch => 'Passwords don\'t match.';

  @override
  String get validationCodeRequired => 'Enter your authentication code';

  @override
  String get loginWelcomeBack => 'Welcome back';

  @override
  String get loginSubtitle => 'We\'re excited to see you again.';

  @override
  String get loginNeedAccount => 'Need an account? ';

  @override
  String get registerLink => 'Register';

  @override
  String get fieldEmailLabel => 'Email';

  @override
  String get fieldEmailHint => 'you@example.com';

  @override
  String get fieldPasswordLabel => 'Password';

  @override
  String get loginSubmitButton => 'Log In';

  @override
  String get loginSubmitButtonLoading => 'Logging in…';

  @override
  String get registerAlreadyHaveAccount => 'Already have an account? ';

  @override
  String get loginLink => 'Log In';

  @override
  String get backToLoginButton => 'Back to Log In';

  @override
  String get registerCheckEmailTitle => 'Check your email';

  @override
  String registerCheckEmailSubtitle(String email) {
    return 'We\'ve sent a confirmation link to $email. Click it to activate your account, then log in.';
  }

  @override
  String get registerCheckEmailFallbackEmail => 'your email';

  @override
  String get registerResendMessageSent => 'Verification email sent.';

  @override
  String get registerResendMessageFailed =>
      'Could not resend right now. Try again shortly.';

  @override
  String get registerResendButton => 'Resend email';

  @override
  String get registerResendButtonLoading => 'Sending…';

  @override
  String get registerCreateAccountTitle => 'Create an account';

  @override
  String get registerCreateAccountSubtitle =>
      'Join Concord and start chatting.';

  @override
  String get fieldNameLabel => 'Name';

  @override
  String get fieldNameHint => 'Jane';

  @override
  String get fieldSurnameLabel => 'Surname';

  @override
  String get fieldSurnameHint => 'Doe';

  @override
  String get passwordMinCharactersHint => 'At least 8 characters.';

  @override
  String get registerSubmitButton => 'Create Account';

  @override
  String get registerSubmitButtonLoading => 'Creating account…';

  @override
  String get resetInvalidLinkTitle => 'Invalid reset link';

  @override
  String get resetInvalidLinkSubtitle =>
      'This password reset link is missing its token.';

  @override
  String get resetLinkExpiredError =>
      'This reset link is invalid or has expired. Request a new one.';

  @override
  String get resetPasswordTitle => 'Reset your password';

  @override
  String get resetPasswordSubtitle => 'Choose a new password for your account.';

  @override
  String get fieldNewPasswordLabel => 'New password';

  @override
  String get fieldConfirmNewPasswordLabel => 'Confirm new password';

  @override
  String get resetPasswordButton => 'Reset Password';

  @override
  String get resetPasswordButtonLoading => 'Resetting…';

  @override
  String get twoFactorTitle => 'Two-factor authentication';

  @override
  String get twoFactorSubtitle =>
      'Enter the code from your authenticator app, or one of your recovery codes.';

  @override
  String get twoFactorBackToSignIn => 'Back to sign in';

  @override
  String get fieldAuthCodeLabel => 'Authentication code';

  @override
  String get fieldAuthCodeHint => '123456 or ABCD-EFGH';

  @override
  String get twoFactorVerifyButton => 'Verify';

  @override
  String get twoFactorVerifyButtonLoading => 'Verifying…';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get saveButton => 'Save';

  @override
  String get tryAgainButton => 'Try again';

  @override
  String get loadingEllipsis => 'Loading…';

  @override
  String get someoneFallback => 'Someone';

  @override
  String get someoneFallbackLower => 'someone';

  @override
  String get messagesTab => 'Messages';

  @override
  String get friendsTab => 'Friends';

  @override
  String get notificationsTooltip => 'Notifications';

  @override
  String get searchTooltip => 'Search';

  @override
  String get serversTooltip => 'Servers';

  @override
  String get voiceConnectedLabel => 'Voice connected';

  @override
  String get callConnectedLabel => 'Call connected';

  @override
  String get tapToReturnLabel => 'Tap to return';

  @override
  String get channelFallbackTitle => 'Channel';

  @override
  String leaveServerConfirmTitle(String serverName) {
    return 'Leave $serverName?';
  }

  @override
  String get leaveServerConfirmMessage =>
      'This removes you from the server immediately. You\'ll need a new invite to rejoin later.';

  @override
  String get leaveServerButton => 'Leave Server';

  @override
  String errorLeaveServerFailed(String message) {
    return 'Could not leave server: $message';
  }

  @override
  String get serverFallbackTitle => 'Server';

  @override
  String get membersTooltip => 'Members';

  @override
  String get serverOptionsTooltip => 'Server options';

  @override
  String get invitePeopleMenuItem => 'Invite People';

  @override
  String get transferOwnershipMenuItem => 'Transfer Ownership';

  @override
  String get thisServerFallback => 'this server';

  @override
  String get couldNotLoadChannelsTitle => 'Couldn’t load channels';

  @override
  String get noChannelsYetTitle => 'No channels yet';

  @override
  String get noChannelsYetSubtitle =>
      'Channels created on this server will show up here.';

  @override
  String get textChannelsLabel => 'Text';

  @override
  String get voiceChannelsLabel => 'Voice';

  @override
  String deleteChannelConfirmTitle(String channelName) {
    return 'Delete #$channelName?';
  }

  @override
  String get deleteChannelConfirmMessage =>
      'This removes the channel for everyone in the server immediately. All messages in it will be lost. This can\'t be undone.';

  @override
  String get deleteChannelButton => 'Delete Channel';

  @override
  String errorDeleteChannelFailed(String message) {
    return 'Could not delete channel: $message';
  }

  @override
  String get renameChannelMenuItem => 'Rename Channel';

  @override
  String createChannelTooltip(String channelType) {
    return 'Create $channelType channel';
  }

  @override
  String noChannelsOfTypeYet(String channelType) {
    return 'No $channelType channels yet.';
  }

  @override
  String get channelOptionsTooltip => 'Channel options';

  @override
  String get homeTooltip => 'Home (Messages & Friends)';

  @override
  String get couldNotLoadServersText => 'Couldn’t load servers';

  @override
  String get addOrJoinServerTooltip => 'Add or join a server';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get logOutTooltip => 'Log out';

  @override
  String get statusOnline => 'Online';

  @override
  String get statusIdle => 'Idle';

  @override
  String get statusDoNotDisturb => 'Do Not Disturb';

  @override
  String get statusInvisible => 'Invisible';

  @override
  String get setStatusTitle => 'Set status';

  @override
  String get messageChannelHint => 'Message this channel…';

  @override
  String errorAttachFileFailed(String message) {
    return 'Could not attach file: $message';
  }

  @override
  String get attachFileTooltip => 'Attach a file';

  @override
  String get sendTooltip => 'Send';

  @override
  String get rateLimitedMessage =>
      'You\'re sending messages too fast. Wait a moment and try again.';

  @override
  String messageTooLong(int maxLength) {
    return 'Message is too long - trim it to $maxLength characters or fewer to send.';
  }

  @override
  String get replyingToPrefix => 'Replying to ';

  @override
  String get cancelReplyTooltip => 'Cancel reply';

  @override
  String get uploadingEllipsis => 'Uploading…';

  @override
  String get readyToSendLabel => 'Ready to send';

  @override
  String get removeAttachmentTooltip => 'Remove attachment';

  @override
  String get couldNotLoadMessagesTitle => 'Couldn\'t load messages';

  @override
  String get noMessagesYetTitle => 'No messages yet';

  @override
  String get noMessagesYetSubtitle =>
      'Say something to get the conversation started.';

  @override
  String get loadOlderMessagesButton => 'Load older messages';

  @override
  String reachedBeginningOfThread(String threadNoun) {
    return 'You\'ve reached the beginning of this $threadNoun.';
  }

  @override
  String get seenLabel => 'Seen';

  @override
  String get scrollToBottomTooltip => 'Scroll to bottom';

  @override
  String get channelThreadNoun => 'channel';

  @override
  String get conversationThreadNoun => 'conversation';

  @override
  String get messageCannotBeEmpty => 'Message cannot be empty.';

  @override
  String messageTooLongChars(int maxLength) {
    return 'Messages can be at most $maxLength characters.';
  }

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String errorUpdatePinFailed(String message) {
    return 'Could not update pin: $message';
  }

  @override
  String errorReactFailed(String message) {
    return 'Could not react: $message';
  }

  @override
  String get deleteMessageConfirmTitle => 'Delete message?';

  @override
  String get hideMessageConfirmTitle => 'Hide this message?';

  @override
  String deleteMessageConfirmMessage(String threadNoun) {
    return 'This deletes it for everyone in the $threadNoun. This can\'t be undone.';
  }

  @override
  String get hideMessageConfirmMessage =>
      'It\'ll disappear from your view only - everyone else can still see it. There\'s no way to unhide it yourself afterward.';

  @override
  String get deleteMessageButton => 'Delete Message';

  @override
  String get hideMessageButton => 'Hide Message';

  @override
  String deletedForEveryoneNotice(String threadNoun) {
    return 'This was removed for everyone in the $threadNoun, not just hidden for you.';
  }

  @override
  String get hiddenOnlyForYouNotice =>
      'You don\'t currently have permission to delete this for everyone, so it was only hidden for you.';

  @override
  String errorRemoveMessageFailed(String message) {
    return 'Could not remove message: $message';
  }

  @override
  String get replyAction => 'Reply';

  @override
  String get forwardAction => 'Forward';

  @override
  String get editMessageAction => 'Edit Message';

  @override
  String get copyTextAction => 'Copy Text';

  @override
  String get unpinAction => 'Unpin';

  @override
  String get pinAction => 'Pin';

  @override
  String get hideForMeAction => 'Hide for me';

  @override
  String get editedSuffix => '  (edited)';

  @override
  String get originalMessageLabel => 'Original message';

  @override
  String get attachmentLabel => 'Attachment';

  @override
  String forwardedFromLabel(String name) {
    return 'Forwarded from $name';
  }

  @override
  String typingSingular(String name) {
    return '$name is typing…';
  }

  @override
  String typingTwo(String name1, String name2) {
    return '$name1 and $name2 are typing…';
  }

  @override
  String typingMany(String name1, String name2) {
    return '$name1, $name2, and others are typing…';
  }

  @override
  String get messageForwardedSnackbar => 'Message forwarded.';

  @override
  String get errorForwardMessageFailed => 'Could not forward that message.';

  @override
  String get forwardMessageTitle => 'Forward Message';

  @override
  String get forwardMessageSubtitle =>
      'Choose a channel or a direct message to forward this to.';

  @override
  String get forwardSearchHint => 'Search channels or people…';

  @override
  String get channelsSectionHeader => 'CHANNELS';

  @override
  String get notInAnyServersText => 'You\'re not in any servers.';

  @override
  String get noMatchingServersText => 'No matching servers.';

  @override
  String get couldNotLoadYourServersText => 'Couldn\'t load your servers.';

  @override
  String get directMessagesSectionHeader => 'DIRECT MESSAGES';

  @override
  String get noMatchingConversationsText => 'No matching conversations.';

  @override
  String get noMatchingChannelsText => 'No matching channels.';

  @override
  String get couldNotLoadChannelsPeriod => 'Couldn\'t load channels.';

  @override
  String get sayHiSubtitle => 'Say hi to start the conversation.';

  @override
  String get messageEllipsisHint => 'Message…';

  @override
  String messageUserHint(String name) {
    return 'Message @$name…';
  }

  @override
  String get settingsScreenTitle => 'Settings';

  @override
  String get myAccountTab => 'My Account';

  @override
  String get privacyTabLabel => 'Privacy';

  @override
  String get voiceTabLabel => 'Voice';

  @override
  String get editProfileButton => 'Edit Profile';

  @override
  String get statusButton => 'Status';

  @override
  String get scanQrCodeButton => 'Scan QR Code to Log In on Web';

  @override
  String get logOutButton => 'Log Out';

  @override
  String get logOutConfirmTitle => 'Log out?';

  @override
  String get logOutConfirmMessage =>
      'You\'ll need to log back in to use Concord on this device again.';

  @override
  String get signOutDeviceConfirmTitle => 'Sign out this device?';

  @override
  String signOutDeviceConfirmMessage(String label) {
    return '$label will be signed out immediately.';
  }

  @override
  String get signOutButton => 'Sign out';

  @override
  String errorSignOutDeviceFailed(String error) {
    return 'Could not sign out that device: $error';
  }

  @override
  String get signOutAllOthersConfirmTitle => 'Sign out all other devices?';

  @override
  String get signOutAllOthersConfirmMessage =>
      'Every other device signed into your account will be signed out immediately.';

  @override
  String get signOutOthersButton => 'Sign out others';

  @override
  String errorSignOutOthersFailed(String error) {
    return 'Could not sign out other devices: $error';
  }

  @override
  String get activeSessionsTitle => 'Active Sessions';

  @override
  String get couldNotLoadSessionsTitle => 'Couldn\'t load your sessions';

  @override
  String get unknownDeviceLabel => 'Unknown device';

  @override
  String get thisDeviceBadge => 'This device';

  @override
  String lastActiveLabel(String time) {
    return 'Last active $time';
  }

  @override
  String get signOutDeviceTooltip => 'Sign out this device';

  @override
  String get currentPasswordRequired => 'Current password is required.';

  @override
  String get newPasswordTooShort =>
      'New password must be at least 8 characters.';

  @override
  String get changePasswordTitle => 'Change Password';

  @override
  String get currentPasswordLabel => 'Current password';

  @override
  String get passwordChangedNotice =>
      'Password changed. Your other devices have been signed out.';

  @override
  String get expiryNeverLabel => 'Don\'t clear';

  @override
  String get expiryThirtyMinLabel => '30 minutes';

  @override
  String get expiryOneHourLabel => '1 hour';

  @override
  String get expiryFourHoursLabel => '4 hours';

  @override
  String get expiryTodayLabel => 'Today';

  @override
  String get setCustomStatusTitle => 'Set a custom status';

  @override
  String get customStatusTextHint => 'What\'s on your mind?';

  @override
  String get clearAfterLabel => 'Clear after';

  @override
  String get clearButton => 'Clear';

  @override
  String get nameRequiredPeriod => 'Name is required.';

  @override
  String get surnameRequiredPeriod => 'Surname is required.';

  @override
  String get usernameRequiredPeriod => 'Username is required.';

  @override
  String get usernameInvalidFormat =>
      'Only letters, numbers, and underscores - up to 32 characters.';

  @override
  String errorUploadAvatarFailed(String message) {
    return 'Could not upload avatar: $message';
  }

  @override
  String get usernameTakenError => 'That username is already taken.';

  @override
  String get checkFieldsError => 'Please check the fields and try again.';

  @override
  String get updateProfileFailedError => 'Could not update profile.';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get avatarLabel => 'Avatar';

  @override
  String get avatarFormatHint => 'PNG, JPEG, WEBP or GIF, up to 5 MB.';

  @override
  String get usernameLabel => 'Username';

  @override
  String get usernameHint => 'Letters, numbers, and underscores only.';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailCannotChangeNotice => 'Email can\'t be changed yet.';

  @override
  String get cameraAccessTitle => 'Camera access';

  @override
  String get cameraAccessRationale =>
      'Concord needs camera access to scan the QR code shown on your other device.';

  @override
  String get codeInvalidOrExpired => 'That code is invalid or has expired.';

  @override
  String get couldNotLookUpCode => 'Couldn\'t look up that code.';

  @override
  String get deviceApprovedSnackbar => 'Device approved.';

  @override
  String get errorApproveDeviceFailed => 'Could not approve that device.';

  @override
  String get signInRequestDeniedSnackbar => 'Sign-in request denied.';

  @override
  String get errorDenyDeviceFailed => 'Could not deny that device.';

  @override
  String get linkDeviceTitle => 'Link a Device';

  @override
  String get linkDeviceInstructions =>
      'Scan the QR code shown on the device you want to sign in, or enter its code below.';

  @override
  String get requestingCameraAccess => 'Requesting camera access…';

  @override
  String get cameraAccessNeeded => 'Camera access is needed to scan a QR code.';

  @override
  String errorCameraAccessFailed(String detail) {
    return 'Could not access the camera: $detail';
  }

  @override
  String get enterCodeManuallyButton => 'Enter code manually';

  @override
  String get deviceCodeLabel => 'Device code';

  @override
  String get deviceCodeHint => 'ABCD1234';

  @override
  String get continueButton => 'Continue';

  @override
  String get scanQrInsteadButton => 'Scan a QR code instead';

  @override
  String get approveDeviceWarning =>
      'Only approve this if you just started signing in on the device shown above.';

  @override
  String get approveButton => 'Approve';

  @override
  String get denyButton => 'Deny';

  @override
  String get visibilityEveryone => 'Everyone';

  @override
  String get visibilityFriendsOfFriends => 'Friends of friends';

  @override
  String get visibilityNobody => 'Nobody';

  @override
  String get visibilityFriendsOnly => 'Friends only';

  @override
  String errorSavePrivacyFailed(String message) {
    return 'Could not save privacy settings: $message';
  }

  @override
  String get privacySafetyTitle => 'Privacy & Safety';

  @override
  String get whoCanSendFriendRequests => 'Who can send friend requests';

  @override
  String get whoCanDirectMessage => 'Who can direct message you';

  @override
  String get whoCanSeeActivity => 'Who can see your activity';

  @override
  String get readReceiptsLabel => 'Read receipts';

  @override
  String get readReceiptsSubtitle =>
      'Let others see when you\'ve read their messages.';

  @override
  String get blockedUsersTitle => 'Blocked Users';

  @override
  String get errorStartTwoFactorFailed => 'Could not start two-factor setup.';

  @override
  String get enterAuthCodeMessage =>
      'Enter the code from your authenticator app.';

  @override
  String get twoFactorDisabledSnackbar => 'Two-factor authentication disabled.';

  @override
  String get errorDisableTwoFactorFailed =>
      'Could not disable two-factor authentication.';

  @override
  String get regenerateRecoveryCodesTitle => 'Regenerate recovery codes';

  @override
  String get regenerateRecoveryCodesDescription =>
      'Your existing recovery codes will stop working. Confirm your password to continue.';

  @override
  String get regenerateButton => 'Regenerate';

  @override
  String get errorRegenerateCodesFailed =>
      'Could not regenerate recovery codes.';

  @override
  String get twoFactorSectionTitle => 'Two-Factor Authentication';

  @override
  String get couldNotLoadTwoFactorStatus => 'Couldn\'t load two-factor status';

  @override
  String get twoFactorOnDescription =>
      'Two-factor authentication is on. Signing in also requires a code from your authenticator app.';

  @override
  String get twoFactorOffDescription =>
      'Add an extra layer of security. Once enabled, signing in will require a code from an authenticator app.';

  @override
  String recoveryCodesRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recovery codes remaining.',
      one: '$count recovery code remaining.',
    );
    return '$_temp0';
  }

  @override
  String get enableTwoFactorButton => 'Enable Two-Factor Authentication';

  @override
  String get disableButton => 'Disable';

  @override
  String get scanQrWithAuthenticator =>
      'Scan this QR code with your authenticator app.';

  @override
  String get couldNotRenderQr =>
      'Couldn\'t render the QR code - enter the key below manually.';

  @override
  String get enterKeyManually => 'Or enter this key manually';

  @override
  String get confirmationCodeLabel => 'Confirmation code';

  @override
  String get confirmationCodeHint => '123456';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get saveRecoveryCodesTitle => 'Save your recovery codes';

  @override
  String get recoveryCodesWarning =>
      'Each code can be used once to sign in if you lose access to your authenticator. They won\'t be shown again.';

  @override
  String get copiedLabel => 'Copied';

  @override
  String get copyCodesButton => 'Copy codes';

  @override
  String get savedCodesButton => 'I\'ve saved these codes';

  @override
  String get disableTwoFactorDialogTitle => 'Disable two-factor authentication';

  @override
  String get disableTwoFactorDialogMessage =>
      'Disabling removes this extra layer of security from your account.';

  @override
  String get passwordLabel => 'Password';

  @override
  String get authOrRecoveryCodeLabel => 'Authentication code or recovery code';

  @override
  String get enterPasswordMessage => 'Enter your password.';

  @override
  String get enterCurrentOrRecoveryCodeMessage =>
      'Enter a current code or a recovery code.';

  @override
  String get voiceVideoTitle => 'Voice & Video';

  @override
  String get voiceInfoText =>
      'Concord will ask for microphone access the first time you join a call, and camera access the first time you turn your camera on. There\'s no separate device picker on mobile - audio output (earpiece/speaker/Bluetooth) is controlled by your device, not this app.';

  @override
  String get voiceNoAudioHint =>
      'If a call connects with no audio, check your device Settings app for Concord\'s microphone permission.';

  @override
  String get twoFactorConfirmCodeFailed => 'That code did not work. Try again.';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageAzerbaijani => 'Azərbaycan';

  @override
  String get preferencesTitle => 'Preferences';

  @override
  String get muteNotificationsLabel => 'Mute notifications';

  @override
  String get muteNotificationsSubtitle =>
      'Suppress in-app notification pop-ups.';

  @override
  String get notificationSoundLabel => 'Notification sound';

  @override
  String get notificationSoundSubtitle => 'Play a sound for new notifications.';

  @override
  String errorSavePreferenceFailed(String message) {
    return 'Could not save preference: $message';
  }

  @override
  String get addServerTitle => 'Add a Server';

  @override
  String get addServerSubtitle =>
      'Create a new server, or join one with an invite code.';

  @override
  String get createTab => 'Create';

  @override
  String get joinTab => 'Join';

  @override
  String get serverNameRequired => 'Server name is required.';

  @override
  String errorUploadIconFailed(String message) {
    return 'Could not upload icon: $message';
  }

  @override
  String get serverNameInvalid => 'That server name is not valid.';

  @override
  String get errorCreateServerFailed => 'Could not create server.';

  @override
  String get serverIconLabel => 'Server icon';

  @override
  String get serverIconHint => 'Optional. PNG, JPEG, WEBP or GIF, up to 5 MB.';

  @override
  String get serverNameLabel => 'Server name';

  @override
  String get serverNameHint => 'My Server';

  @override
  String get creatingServerLoading => 'Creating…';

  @override
  String get createServerButton => 'Create Server';

  @override
  String get enterInviteCodeMessage => 'Enter an invite code.';

  @override
  String get inviteCodeInvalidMessage =>
      'That invite code is invalid, expired, or no longer works.';

  @override
  String get errorJoinServerFailed => 'Could not join server.';

  @override
  String get inviteCodeLabel => 'Invite code';

  @override
  String get inviteCodeHint => 'e.g. aB3xQ9';

  @override
  String get joiningServerLoading => 'Joining…';

  @override
  String get joinServerButton => 'Join Server';

  @override
  String get channelNameRequired => 'Channel name is required.';

  @override
  String get channelNameInvalid => 'That channel name is not valid.';

  @override
  String get errorCreateChannelFailed => 'Could not create channel.';

  @override
  String get createChannelTitle => 'Create Channel';

  @override
  String get channelTypeLabel => 'Channel type';

  @override
  String get channelNameLabel => 'Channel name';

  @override
  String get channelNameHintVoice => 'general-voice';

  @override
  String get channelNameHintText => 'general';

  @override
  String get creatingChannelLoading => 'Creating…';

  @override
  String get expiryNeverOption => 'Never';

  @override
  String get expiryOneDayLabel => '1 day';

  @override
  String get expirySevenDaysLabel => '7 days';

  @override
  String get maxUsesInvalidMessage => 'Max uses must be a positive number.';

  @override
  String get errorGenerateInviteFailed => 'Could not generate an invite.';

  @override
  String get inviteCodeCopiedSnackbar => 'Invite code copied to clipboard';

  @override
  String get expiresLabel => 'Expires';

  @override
  String get maxUsesLabel => 'Max uses';

  @override
  String get unlimitedHint => 'Unlimited';

  @override
  String get generateInviteLinkButton => 'Generate invite link';

  @override
  String get couldNotLoadInvitesTitle => 'Couldn\'t load invites';

  @override
  String get noInvitesYetText => 'No invites generated yet.';

  @override
  String get copyButton => 'Copy';

  @override
  String inviteUsesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uses',
      one: '$count use',
    );
    return '$_temp0';
  }

  @override
  String inviteUsesOfMax(int count, int max, String exhausted) {
    return '$count / $max uses$exhausted';
  }

  @override
  String get inviteExhaustedSuffix => ' - exhausted';

  @override
  String get neverExpiresLabel => 'Never expires';

  @override
  String get expiredLabel => 'Expired';

  @override
  String expiresOnLabel(String date) {
    return 'Expires $date';
  }

  @override
  String errorModerationFailed(String action, String message) {
    return 'Could not $action: $message';
  }

  @override
  String get actionUnmuteMember => 'unmute this member';

  @override
  String get actionMuteMember => 'mute this member';

  @override
  String get actionRemoveTimeout => 'remove this timeout';

  @override
  String get actionTimeoutMember => 'time out this member';

  @override
  String get actionKickMember => 'kick this member';

  @override
  String get actionBanMember => 'ban this member';

  @override
  String get unknownErrorLabel => 'unknown error';

  @override
  String get unmuteAction => 'Unmute';

  @override
  String get muteAction => 'Mute';

  @override
  String get removeTimeoutAction => 'Remove Timeout';

  @override
  String get timeoutAction => 'Timeout';

  @override
  String get kickAction => 'Kick';

  @override
  String get banAction => 'Ban';

  @override
  String kickConfirmTitle(String name) {
    return 'Kick $name?';
  }

  @override
  String kickConfirmMessage(String name) {
    return '$name will be removed from the server. They can rejoin with a valid invite.';
  }

  @override
  String get timeoutFiveMin => '5 minutes';

  @override
  String timeoutConfirmTitle(String name) {
    return 'Time out $name?';
  }

  @override
  String get timeoutConfirmMessage =>
      'They\'ll temporarily lose the ability to send messages and speak in voice channels.';

  @override
  String get durationLabel => 'Duration';

  @override
  String get reasonLabel => 'Reason';

  @override
  String get optionalHint => 'Optional';

  @override
  String banConfirmTitle(String name) {
    return 'Ban $name?';
  }

  @override
  String get banConfirmMessage =>
      'This removes them from the server and blocks them from rejoining through any invite.';

  @override
  String renameChannelTitle(String name) {
    return 'Rename #$name';
  }

  @override
  String get errorRenameChannelFailed => 'Could not rename channel.';

  @override
  String get membersTitle => 'Members';

  @override
  String get couldNotLoadMembersTitle => 'Couldn\'t load members';

  @override
  String get noMembersTitle => 'No members';

  @override
  String get noMembersSubtitle => 'This server has no members yet.';

  @override
  String memberGroupHeader(String label, int count) {
    return '$label - $count';
  }

  @override
  String get loadMoreButton => 'Load more';

  @override
  String memberCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '$count member',
    );
    return '$_temp0';
  }

  @override
  String get statusOffline => 'Offline';

  @override
  String get mutedTooltip => 'Muted';

  @override
  String timedOutUntilTooltip(String date) {
    return 'Timed out until $date';
  }

  @override
  String moderateMemberTooltip(String name) {
    return 'Moderate $name';
  }

  @override
  String transferOwnershipConfirmTitle(String serverName) {
    return 'Transfer ownership of $serverName?';
  }

  @override
  String transferOwnershipConfirmMessage(String name) {
    return '$name will become the new owner. You\'ll remain a member and will then be able to leave the server yourself if you want to.';
  }

  @override
  String get transferButton => 'Transfer';

  @override
  String get errorTransferOwnershipFailed => 'Could not transfer ownership.';

  @override
  String get transferOwnershipTitle => 'Transfer ownership';

  @override
  String transferOwnershipSubtitle(String serverName) {
    return 'Pick another member to become the new owner of $serverName.';
  }

  @override
  String get filterMembersHint => 'Filter members by username…';

  @override
  String get couldNotLoadMembersPeriod => 'Couldn\'t load members.';

  @override
  String get noOtherMembersText =>
      'There\'s nobody else in this server to transfer ownership to yet.';

  @override
  String errorSendRequestFailed(String message) {
    return 'Could not send request: $message';
  }

  @override
  String errorAcceptRequestFailed(String message) {
    return 'Could not accept request: $message';
  }

  @override
  String errorDeclineRequestFailed(String message) {
    return 'Could not decline request: $message';
  }

  @override
  String get alreadyFriendsBadge => 'Already friends';

  @override
  String get requestSentLabel => 'Request sent';

  @override
  String get acceptButton => 'Accept';

  @override
  String get declineButton => 'Decline';

  @override
  String get addButton => 'Add';

  @override
  String get searchByUsernameHint => 'Enter their exact username…';

  @override
  String keepTypingMessage(int count) {
    return 'Keep typing - at least $count characters.';
  }

  @override
  String get findFriendsTitle => 'Find friends by username';

  @override
  String get findFriendsSubtitle =>
      'You\'ll need their exact username - this isn\'t a browsable directory. You, existing friends, and blocked users won\'t show up here.';

  @override
  String get searchFailedTitle => 'Search failed';

  @override
  String get noUsersFoundTitle => 'No users found';

  @override
  String noUsersFoundSubtitle(String query) {
    return 'Nobody matches \"$query\".';
  }

  @override
  String unblockConfirmTitle(String name) {
    return 'Unblock $name?';
  }

  @override
  String get unblockConfirmMessage =>
      'They will be able to see your profile, send you friend requests, and message you again.';

  @override
  String get unblockButton => 'Unblock';

  @override
  String unblockedSnackbar(String name) {
    return '$name can interact with you again.';
  }

  @override
  String errorUnblockFailed(String message) {
    return 'Could not unblock user: $message';
  }

  @override
  String get couldNotLoadBlockedTitle => 'Couldn\'t load blocked users';

  @override
  String get noBlockedUsersTitle => 'No blocked users';

  @override
  String get noBlockedUsersSubtitle =>
      'Users you block will show up here. Blocking removes them from your friends and pending requests, and they can\'t message or friend-request you again unless you unblock them.';

  @override
  String sectionCountSuffix(int count) {
    return ' - $count';
  }

  @override
  String get blockedHeader => 'BLOCKED';

  @override
  String get allFriendsHeader => 'ALL FRIENDS';

  @override
  String get incomingHeader => 'INCOMING';

  @override
  String get outgoingHeader => 'OUTGOING';

  @override
  String get pendingTabLabel => 'Pending';

  @override
  String get blockedTabLabel => 'Blocked';

  @override
  String get addFriendTabLabel => 'Add Friend';

  @override
  String errorStartConversationFailed(String message) {
    return 'Could not start conversation: $message';
  }

  @override
  String get blockConfirmTitle => 'Block this user?';

  @override
  String blockConfirmMessage(String name) {
    return '$name will be removed from your friends and won\'t be able to message you or see your profile. There\'s no separate \"unfriend\" - this is the only way to end the friendship.';
  }

  @override
  String get blockUserButton => 'Block User';

  @override
  String blockedSnackbar(String name) {
    return '$name was blocked.';
  }

  @override
  String errorBlockUserFailed(String message) {
    return 'Could not block user: $message';
  }

  @override
  String get couldNotLoadFriendsTitle => 'Couldn\'t load friends';

  @override
  String get noFriendsYetTitle => 'No friends yet';

  @override
  String get noFriendsYetSubtitle =>
      'Search for someone in the Add Friend tab to send a request.';

  @override
  String get messageTooltip => 'Message';

  @override
  String get blockTooltip => 'Block';

  @override
  String nowFriendsSnackbar(String name) {
    return 'You and $name are now friends.';
  }

  @override
  String get thisUserFallback => 'this user';

  @override
  String get couldNotLoadIncomingTitle => 'Couldn\'t load incoming requests';

  @override
  String get noIncomingRequestsText => 'No incoming requests.';

  @override
  String get couldNotLoadOutgoingTitle => 'Couldn\'t load outgoing requests';

  @override
  String get noOutgoingRequestsText => 'No outgoing requests.';

  @override
  String get cancelRequestConfirmTitle => 'Cancel friend request?';

  @override
  String cancelRequestConfirmMessage(String name) {
    return 'This cancels your pending friend request to $name. You\'ll need to send a new request if you change your mind.';
  }

  @override
  String get cancelRequestButton => 'Cancel Request';

  @override
  String errorCancelRequestFailed(String message) {
    return 'Could not cancel request: $message';
  }

  @override
  String get pendingSubtitle => 'Pending';

  @override
  String get couldNotLoadConversationsTitle => 'Couldn\'t load conversations';

  @override
  String get noConversationsYetTitle => 'No conversations yet';

  @override
  String get noConversationsYetSubtitle =>
      'Message a friend from the Friends tab to start one.';

  @override
  String get sentAttachmentPreview => 'Sent an attachment';

  @override
  String get microphoneAccessTitle => 'Microphone access';

  @override
  String get microphoneAccessRationale =>
      'Concord needs microphone access so the other person can hear you on the call.';

  @override
  String get notificationAccessTitle => 'Notifications';

  @override
  String get notificationAccessRationale =>
      'Concord can let you know about new messages and friend requests even when the app is closed. Turn on notifications?';

  @override
  String get cameraAccessRationaleVideoCalls =>
      'Concord needs camera access for video calls.';

  @override
  String get directMessageFallbackTitle => 'Direct Message';

  @override
  String get startVoiceCallTooltip => 'Start voice call';

  @override
  String get startVideoCallTooltip => 'Start video call';

  @override
  String get callingEllipsis => 'Calling…';

  @override
  String get reconnectingEllipsis => 'Reconnecting…';

  @override
  String get inCallLabel => 'In call';

  @override
  String get incomingVideoCallTitle => 'Incoming video call';

  @override
  String get incomingVoiceCallTitle => 'Incoming voice call';

  @override
  String participantYouSuffix(String name) {
    return '$name (you)';
  }

  @override
  String get youFallback => 'You';

  @override
  String get memberFallback => 'Member';

  @override
  String get unmuteMicTooltip => 'Unmute microphone';

  @override
  String get muteMicTooltip => 'Mute microphone';

  @override
  String get undeafenTooltip => 'Undeafen';

  @override
  String get deafenTooltip => 'Deafen';

  @override
  String get turnOffCameraTooltip => 'Turn off camera';

  @override
  String get turnOnCameraTooltip => 'Turn on camera';

  @override
  String get leaveCallTooltip => 'Leave call';

  @override
  String get microphoneAccessRationaleChannel =>
      'Concord needs microphone access so others in this channel can hear you.';

  @override
  String joinChannelTitle(String channelName) {
    return 'Join $channelName';
  }

  @override
  String get joinVoiceChannelTitle => 'Join voice channel';

  @override
  String get joinVoiceChannelSubtitle =>
      'Connect to start talking with everyone in this channel.';

  @override
  String get connectingEllipsis => 'Connecting…';

  @override
  String get joinVoiceButton => 'Join Voice';

  @override
  String get notificationsScreenTitle => 'Notifications';

  @override
  String get markAllReadButton => 'Mark all read';

  @override
  String get couldNotLoadNotificationsTitle => 'Couldn\'t load notifications';

  @override
  String get noNotificationsYetTitle => 'No notifications yet';

  @override
  String get noNotificationsYetSubtitle =>
      'Friend requests, missed calls, and mentions will show up here.';

  @override
  String notifFriendRequestReceived(String name) {
    return '$name sent you a friend request';
  }

  @override
  String notifFriendRequestAccepted(String name) {
    return '$name accepted your friend request';
  }

  @override
  String notifMissedCall(String name) {
    return 'Missed call from $name';
  }

  @override
  String notifMention(String name) {
    return '$name mentioned you';
  }

  @override
  String notifMessageReceived(String name) {
    return '$name sent you a message';
  }

  @override
  String notifFriendRequestDeclined(String name) {
    return '$name declined your friend request';
  }

  @override
  String notifFriendRequestCancelled(String name) {
    return '$name cancelled their friend request';
  }

  @override
  String get searchMessagesHint => 'Search messages…';

  @override
  String get keepTypingEllipsis => 'Keep typing…';

  @override
  String get couldNotSearchTitle => 'Couldn\'t search';

  @override
  String get searchAcrossTitle => 'Search across your servers and DMs';

  @override
  String get searchMinCharsSubtitle =>
      'Type at least 2 characters to start searching.';

  @override
  String get noResultsTitle => 'No results';

  @override
  String get noTextContentPlaceholder => '(no text content)';

  @override
  String get hidePasswordTooltip => 'Hide password';

  @override
  String get showPasswordTooltip => 'Show password';

  @override
  String get amLabel => 'AM';

  @override
  String get pmLabel => 'PM';

  @override
  String todayAtLabel(String time) {
    return 'Today at $time';
  }

  @override
  String yesterdayAtLabel(String time) {
    return 'Yesterday at $time';
  }

  @override
  String get justNowLabel => 'just now';

  @override
  String minutesAgoLabel(int count) {
    return '${count}m ago';
  }

  @override
  String hoursAgoLabel(int count) {
    return '${count}h ago';
  }

  @override
  String daysAgoLabel(int count) {
    return '${count}d ago';
  }

  @override
  String get dangerZoneTitle => 'Danger Zone';

  @override
  String get deleteAccountButton => 'Delete Account';

  @override
  String get deleteAccountSectionDescription =>
      'Permanently delete your account and all of your data.';

  @override
  String get deleteAccountDialogTitle => 'Delete your account?';

  @override
  String get deleteAccountConsequencesMessage =>
      'You\'ll be logged out of every device immediately. Your account will be deactivated for 30 days - if you log back in during that time, the deletion is cancelled and your account is restored. After 30 days, it\'s permanently deleted and can\'t be recovered.';

  @override
  String get deleteAccountPasswordLabel => 'Enter your password to confirm';

  @override
  String get deleteAccountConfirmButton => 'Delete My Account';

  @override
  String get deleteAccountIncorrectPasswordError => 'Incorrect password.';

  @override
  String get deleteAccountFailedError => 'Could not delete your account.';

  @override
  String get deleteAccountSuccessSnackbar =>
      'Your account has been deleted. Log back in within 30 days to cancel the deletion.';
}
