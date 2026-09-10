import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_az.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('az'),
    Locale('en'),
  ];

  /// No description provided for @errorCouldNotReachServer.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach Concord — check your connection and try again.'**
  String get errorCouldNotReachServer;

  /// No description provided for @errorServerTrouble.
  ///
  /// In en, this message translates to:
  /// **'Concord is having trouble on its end right now. Please try again shortly.'**
  String get errorServerTrouble;

  /// No description provided for @errorSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorSomethingWentWrong;

  /// No description provided for @errorCantReachServer.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server. Check your connection.'**
  String get errorCantReachServer;

  /// No description provided for @errorTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get errorTooManyAttempts;

  /// No description provided for @errorAccountLocked.
  ///
  /// In en, this message translates to:
  /// **'Your account is temporarily locked. Try again in a few minutes.'**
  String get errorAccountLocked;

  /// No description provided for @errorInvalidEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get errorInvalidEmailPassword;

  /// No description provided for @errorSignInExpired.
  ///
  /// In en, this message translates to:
  /// **'That sign-in attempt expired. Go back and enter your password again.'**
  String get errorSignInExpired;

  /// No description provided for @errorInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'That code is not valid. Check your authenticator app, or use a recovery code.'**
  String get errorInvalidCode;

  /// No description provided for @errorAccountExists.
  ///
  /// In en, this message translates to:
  /// **'An account with that email already exists.'**
  String get errorAccountExists;

  /// No description provided for @validationEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get validationEmailRequired;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get validationPasswordRequired;

  /// No description provided for @validationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get validationNameRequired;

  /// No description provided for @validationSurnameRequired.
  ///
  /// In en, this message translates to:
  /// **'Surname is required'**
  String get validationSurnameRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get validationPasswordMinLength;

  /// No description provided for @validationPasswordTooShortPeriod.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get validationPasswordTooShortPeriod;

  /// No description provided for @validationPasswordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match.'**
  String get validationPasswordsDontMatch;

  /// No description provided for @validationCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your authentication code'**
  String get validationCodeRequired;

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginWelcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re excited to see you again.'**
  String get loginSubtitle;

  /// No description provided for @loginNeedAccount.
  ///
  /// In en, this message translates to:
  /// **'Need an account? '**
  String get loginNeedAccount;

  /// No description provided for @registerLink.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerLink;

  /// No description provided for @fieldEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get fieldEmailLabel;

  /// No description provided for @fieldEmailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get fieldEmailHint;

  /// No description provided for @fieldPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPasswordLabel;

  /// No description provided for @loginSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginSubmitButton;

  /// No description provided for @loginSubmitButtonLoading.
  ///
  /// In en, this message translates to:
  /// **'Logging in…'**
  String get loginSubmitButtonLoading;

  /// No description provided for @registerAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get registerAlreadyHaveAccount;

  /// No description provided for @loginLink.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginLink;

  /// No description provided for @backToLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Back to Log In'**
  String get backToLoginButton;

  /// No description provided for @registerCheckEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get registerCheckEmailTitle;

  /// No description provided for @registerCheckEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a confirmation link to {email}. Click it to activate your account, then log in.'**
  String registerCheckEmailSubtitle(String email);

  /// No description provided for @registerCheckEmailFallbackEmail.
  ///
  /// In en, this message translates to:
  /// **'your email'**
  String get registerCheckEmailFallbackEmail;

  /// No description provided for @registerResendMessageSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent.'**
  String get registerResendMessageSent;

  /// No description provided for @registerResendMessageFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not resend right now. Try again shortly.'**
  String get registerResendMessageFailed;

  /// No description provided for @registerResendButton.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get registerResendButton;

  /// No description provided for @registerResendButtonLoading.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get registerResendButtonLoading;

  /// No description provided for @registerCreateAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get registerCreateAccountTitle;

  /// No description provided for @registerCreateAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join Concord and start chatting.'**
  String get registerCreateAccountSubtitle;

  /// No description provided for @fieldNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldNameLabel;

  /// No description provided for @fieldNameHint.
  ///
  /// In en, this message translates to:
  /// **'Jane'**
  String get fieldNameHint;

  /// No description provided for @fieldSurnameLabel.
  ///
  /// In en, this message translates to:
  /// **'Surname'**
  String get fieldSurnameLabel;

  /// No description provided for @fieldSurnameHint.
  ///
  /// In en, this message translates to:
  /// **'Doe'**
  String get fieldSurnameHint;

  /// No description provided for @passwordMinCharactersHint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters.'**
  String get passwordMinCharactersHint;

  /// No description provided for @registerSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerSubmitButton;

  /// No description provided for @registerSubmitButtonLoading.
  ///
  /// In en, this message translates to:
  /// **'Creating account…'**
  String get registerSubmitButtonLoading;

  /// No description provided for @resetInvalidLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Invalid reset link'**
  String get resetInvalidLinkTitle;

  /// No description provided for @resetInvalidLinkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This password reset link is missing its token.'**
  String get resetInvalidLinkSubtitle;

  /// No description provided for @resetLinkExpiredError.
  ///
  /// In en, this message translates to:
  /// **'This reset link is invalid or has expired. Request a new one.'**
  String get resetLinkExpiredError;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password for your account.'**
  String get resetPasswordSubtitle;

  /// No description provided for @fieldNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get fieldNewPasswordLabel;

  /// No description provided for @fieldConfirmNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get fieldConfirmNewPasswordLabel;

  /// No description provided for @resetPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordButton;

  /// No description provided for @resetPasswordButtonLoading.
  ///
  /// In en, this message translates to:
  /// **'Resetting…'**
  String get resetPasswordButtonLoading;

  /// No description provided for @twoFactorTitle.
  ///
  /// In en, this message translates to:
  /// **'Two-factor authentication'**
  String get twoFactorTitle;

  /// No description provided for @twoFactorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the code from your authenticator app, or one of your recovery codes.'**
  String get twoFactorSubtitle;

  /// No description provided for @twoFactorBackToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get twoFactorBackToSignIn;

  /// No description provided for @fieldAuthCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Authentication code'**
  String get fieldAuthCodeLabel;

  /// No description provided for @fieldAuthCodeHint.
  ///
  /// In en, this message translates to:
  /// **'123456 or ABCD-EFGH'**
  String get fieldAuthCodeHint;

  /// No description provided for @twoFactorVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get twoFactorVerifyButton;

  /// No description provided for @twoFactorVerifyButtonLoading.
  ///
  /// In en, this message translates to:
  /// **'Verifying…'**
  String get twoFactorVerifyButtonLoading;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @tryAgainButton.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgainButton;

  /// No description provided for @loadingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loadingEllipsis;

  /// No description provided for @someoneFallback.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get someoneFallback;

  /// No description provided for @someoneFallbackLower.
  ///
  /// In en, this message translates to:
  /// **'someone'**
  String get someoneFallbackLower;

  /// No description provided for @messagesTab.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesTab;

  /// No description provided for @friendsTab.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friendsTab;

  /// No description provided for @notificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTooltip;

  /// No description provided for @searchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTooltip;

  /// No description provided for @serversTooltip.
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get serversTooltip;

  /// No description provided for @voiceConnectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice connected'**
  String get voiceConnectedLabel;

  /// No description provided for @callConnectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Call connected'**
  String get callConnectedLabel;

  /// No description provided for @tapToReturnLabel.
  ///
  /// In en, this message translates to:
  /// **'Tap to return'**
  String get tapToReturnLabel;

  /// No description provided for @channelFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get channelFallbackTitle;

  /// No description provided for @leaveServerConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave {serverName}?'**
  String leaveServerConfirmTitle(String serverName);

  /// No description provided for @leaveServerConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This removes you from the server immediately. You\'ll need a new invite to rejoin later.'**
  String get leaveServerConfirmMessage;

  /// No description provided for @leaveServerButton.
  ///
  /// In en, this message translates to:
  /// **'Leave Server'**
  String get leaveServerButton;

  /// No description provided for @errorLeaveServerFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not leave server: {message}'**
  String errorLeaveServerFailed(String message);

  /// No description provided for @serverFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get serverFallbackTitle;

  /// No description provided for @membersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get membersTooltip;

  /// No description provided for @serverOptionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Server options'**
  String get serverOptionsTooltip;

  /// No description provided for @invitePeopleMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Invite People'**
  String get invitePeopleMenuItem;

  /// No description provided for @transferOwnershipMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Transfer Ownership'**
  String get transferOwnershipMenuItem;

  /// No description provided for @thisServerFallback.
  ///
  /// In en, this message translates to:
  /// **'this server'**
  String get thisServerFallback;

  /// No description provided for @couldNotLoadChannelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load channels'**
  String get couldNotLoadChannelsTitle;

  /// No description provided for @noChannelsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No channels yet'**
  String get noChannelsYetTitle;

  /// No description provided for @noChannelsYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Channels created on this server will show up here.'**
  String get noChannelsYetSubtitle;

  /// No description provided for @textChannelsLabel.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get textChannelsLabel;

  /// No description provided for @voiceChannelsLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voiceChannelsLabel;

  /// No description provided for @deleteChannelConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete #{channelName}?'**
  String deleteChannelConfirmTitle(String channelName);

  /// No description provided for @deleteChannelConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This removes the channel for everyone in the server immediately. All messages in it will be lost. This can\'t be undone.'**
  String get deleteChannelConfirmMessage;

  /// No description provided for @deleteChannelButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Channel'**
  String get deleteChannelButton;

  /// No description provided for @errorDeleteChannelFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete channel: {message}'**
  String errorDeleteChannelFailed(String message);

  /// No description provided for @renameChannelMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Rename Channel'**
  String get renameChannelMenuItem;

  /// No description provided for @createChannelTooltip.
  ///
  /// In en, this message translates to:
  /// **'Create {channelType} channel'**
  String createChannelTooltip(String channelType);

  /// No description provided for @noChannelsOfTypeYet.
  ///
  /// In en, this message translates to:
  /// **'No {channelType} channels yet.'**
  String noChannelsOfTypeYet(String channelType);

  /// No description provided for @channelOptionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Channel options'**
  String get channelOptionsTooltip;

  /// No description provided for @homeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Home (Messages & Friends)'**
  String get homeTooltip;

  /// No description provided for @couldNotLoadServersText.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load servers'**
  String get couldNotLoadServersText;

  /// No description provided for @addOrJoinServerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add or join a server'**
  String get addOrJoinServerTooltip;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @logOutTooltip.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOutTooltip;

  /// No description provided for @statusOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get statusOnline;

  /// No description provided for @statusIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get statusIdle;

  /// No description provided for @statusDoNotDisturb.
  ///
  /// In en, this message translates to:
  /// **'Do Not Disturb'**
  String get statusDoNotDisturb;

  /// No description provided for @statusInvisible.
  ///
  /// In en, this message translates to:
  /// **'Invisible'**
  String get statusInvisible;

  /// No description provided for @setStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Set status'**
  String get setStatusTitle;

  /// No description provided for @messageChannelHint.
  ///
  /// In en, this message translates to:
  /// **'Message this channel…'**
  String get messageChannelHint;

  /// No description provided for @errorAttachFileFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not attach file: {message}'**
  String errorAttachFileFailed(String message);

  /// No description provided for @attachFileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Attach a file'**
  String get attachFileTooltip;

  /// No description provided for @sendTooltip.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendTooltip;

  /// No description provided for @rateLimitedMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re sending messages too fast. Wait a moment and try again.'**
  String get rateLimitedMessage;

  /// No description provided for @messageTooLong.
  ///
  /// In en, this message translates to:
  /// **'Message is too long - trim it to {maxLength} characters or fewer to send.'**
  String messageTooLong(int maxLength);

  /// No description provided for @replyingToPrefix.
  ///
  /// In en, this message translates to:
  /// **'Replying to '**
  String get replyingToPrefix;

  /// No description provided for @cancelReplyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cancel reply'**
  String get cancelReplyTooltip;

  /// No description provided for @uploadingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get uploadingEllipsis;

  /// No description provided for @readyToSendLabel.
  ///
  /// In en, this message translates to:
  /// **'Ready to send'**
  String get readyToSendLabel;

  /// No description provided for @removeAttachmentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove attachment'**
  String get removeAttachmentTooltip;

  /// No description provided for @couldNotLoadMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load messages'**
  String get couldNotLoadMessagesTitle;

  /// No description provided for @noMessagesYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYetTitle;

  /// No description provided for @noMessagesYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Say something to get the conversation started.'**
  String get noMessagesYetSubtitle;

  /// No description provided for @loadOlderMessagesButton.
  ///
  /// In en, this message translates to:
  /// **'Load older messages'**
  String get loadOlderMessagesButton;

  /// No description provided for @reachedBeginningOfThread.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the beginning of this {threadNoun}.'**
  String reachedBeginningOfThread(String threadNoun);

  /// No description provided for @seenLabel.
  ///
  /// In en, this message translates to:
  /// **'Seen'**
  String get seenLabel;

  /// No description provided for @scrollToBottomTooltip.
  ///
  /// In en, this message translates to:
  /// **'Scroll to bottom'**
  String get scrollToBottomTooltip;

  /// No description provided for @channelThreadNoun.
  ///
  /// In en, this message translates to:
  /// **'channel'**
  String get channelThreadNoun;

  /// No description provided for @conversationThreadNoun.
  ///
  /// In en, this message translates to:
  /// **'conversation'**
  String get conversationThreadNoun;

  /// No description provided for @messageCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Message cannot be empty.'**
  String get messageCannotBeEmpty;

  /// No description provided for @messageTooLongChars.
  ///
  /// In en, this message translates to:
  /// **'Messages can be at most {maxLength} characters.'**
  String messageTooLongChars(int maxLength);

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @errorUpdatePinFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update pin: {message}'**
  String errorUpdatePinFailed(String message);

  /// No description provided for @errorReactFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not react: {message}'**
  String errorReactFailed(String message);

  /// No description provided for @deleteMessageConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete message?'**
  String get deleteMessageConfirmTitle;

  /// No description provided for @hideMessageConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide this message?'**
  String get hideMessageConfirmTitle;

  /// No description provided for @deleteMessageConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This deletes it for everyone in the {threadNoun}. This can\'t be undone.'**
  String deleteMessageConfirmMessage(String threadNoun);

  /// No description provided for @hideMessageConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'It\'ll disappear from your view only - everyone else can still see it. There\'s no way to unhide it yourself afterward.'**
  String get hideMessageConfirmMessage;

  /// No description provided for @deleteMessageButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Message'**
  String get deleteMessageButton;

  /// No description provided for @hideMessageButton.
  ///
  /// In en, this message translates to:
  /// **'Hide Message'**
  String get hideMessageButton;

  /// No description provided for @deletedForEveryoneNotice.
  ///
  /// In en, this message translates to:
  /// **'This was removed for everyone in the {threadNoun}, not just hidden for you.'**
  String deletedForEveryoneNotice(String threadNoun);

  /// No description provided for @hiddenOnlyForYouNotice.
  ///
  /// In en, this message translates to:
  /// **'You don\'t currently have permission to delete this for everyone, so it was only hidden for you.'**
  String get hiddenOnlyForYouNotice;

  /// No description provided for @errorRemoveMessageFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not remove message: {message}'**
  String errorRemoveMessageFailed(String message);

  /// No description provided for @replyAction.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get replyAction;

  /// No description provided for @forwardAction.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get forwardAction;

  /// No description provided for @editMessageAction.
  ///
  /// In en, this message translates to:
  /// **'Edit Message'**
  String get editMessageAction;

  /// No description provided for @copyTextAction.
  ///
  /// In en, this message translates to:
  /// **'Copy Text'**
  String get copyTextAction;

  /// No description provided for @unpinAction.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpinAction;

  /// No description provided for @pinAction.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pinAction;

  /// No description provided for @hideForMeAction.
  ///
  /// In en, this message translates to:
  /// **'Hide for me'**
  String get hideForMeAction;

  /// No description provided for @editedSuffix.
  ///
  /// In en, this message translates to:
  /// **'  (edited)'**
  String get editedSuffix;

  /// No description provided for @originalMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Original message'**
  String get originalMessageLabel;

  /// No description provided for @attachmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get attachmentLabel;

  /// No description provided for @forwardedFromLabel.
  ///
  /// In en, this message translates to:
  /// **'Forwarded from {name}'**
  String forwardedFromLabel(String name);

  /// No description provided for @typingSingular.
  ///
  /// In en, this message translates to:
  /// **'{name} is typing…'**
  String typingSingular(String name);

  /// No description provided for @typingTwo.
  ///
  /// In en, this message translates to:
  /// **'{name1} and {name2} are typing…'**
  String typingTwo(String name1, String name2);

  /// No description provided for @typingMany.
  ///
  /// In en, this message translates to:
  /// **'{name1}, {name2}, and others are typing…'**
  String typingMany(String name1, String name2);

  /// No description provided for @messageForwardedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Message forwarded.'**
  String get messageForwardedSnackbar;

  /// No description provided for @errorForwardMessageFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not forward that message.'**
  String get errorForwardMessageFailed;

  /// No description provided for @forwardMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Forward Message'**
  String get forwardMessageTitle;

  /// No description provided for @forwardMessageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a channel or a direct message to forward this to.'**
  String get forwardMessageSubtitle;

  /// No description provided for @forwardSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search channels or people…'**
  String get forwardSearchHint;

  /// No description provided for @channelsSectionHeader.
  ///
  /// In en, this message translates to:
  /// **'CHANNELS'**
  String get channelsSectionHeader;

  /// No description provided for @notInAnyServersText.
  ///
  /// In en, this message translates to:
  /// **'You\'re not in any servers.'**
  String get notInAnyServersText;

  /// No description provided for @noMatchingServersText.
  ///
  /// In en, this message translates to:
  /// **'No matching servers.'**
  String get noMatchingServersText;

  /// No description provided for @couldNotLoadYourServersText.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your servers.'**
  String get couldNotLoadYourServersText;

  /// No description provided for @directMessagesSectionHeader.
  ///
  /// In en, this message translates to:
  /// **'DIRECT MESSAGES'**
  String get directMessagesSectionHeader;

  /// No description provided for @noMatchingConversationsText.
  ///
  /// In en, this message translates to:
  /// **'No matching conversations.'**
  String get noMatchingConversationsText;

  /// No description provided for @noMatchingChannelsText.
  ///
  /// In en, this message translates to:
  /// **'No matching channels.'**
  String get noMatchingChannelsText;

  /// No description provided for @couldNotLoadChannelsPeriod.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load channels.'**
  String get couldNotLoadChannelsPeriod;

  /// No description provided for @sayHiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Say hi to start the conversation.'**
  String get sayHiSubtitle;

  /// No description provided for @messageEllipsisHint.
  ///
  /// In en, this message translates to:
  /// **'Message…'**
  String get messageEllipsisHint;

  /// No description provided for @messageUserHint.
  ///
  /// In en, this message translates to:
  /// **'Message @{name}…'**
  String messageUserHint(String name);

  /// No description provided for @settingsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsScreenTitle;

  /// No description provided for @myAccountTab.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get myAccountTab;

  /// No description provided for @privacyTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyTabLabel;

  /// No description provided for @voiceTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voiceTabLabel;

  /// No description provided for @editProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileButton;

  /// No description provided for @statusButton.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusButton;

  /// No description provided for @scanQrCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code to Log In on Web'**
  String get scanQrCodeButton;

  /// No description provided for @logOutButton.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOutButton;

  /// No description provided for @signOutDeviceConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out this device?'**
  String get signOutDeviceConfirmTitle;

  /// No description provided for @signOutDeviceConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'{label} will be signed out immediately.'**
  String signOutDeviceConfirmMessage(String label);

  /// No description provided for @signOutButton.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutButton;

  /// No description provided for @errorSignOutDeviceFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sign out that device: {error}'**
  String errorSignOutDeviceFailed(String error);

  /// No description provided for @signOutAllOthersConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out all other devices?'**
  String get signOutAllOthersConfirmTitle;

  /// No description provided for @signOutAllOthersConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Every other device signed into your account will be signed out immediately.'**
  String get signOutAllOthersConfirmMessage;

  /// No description provided for @signOutOthersButton.
  ///
  /// In en, this message translates to:
  /// **'Sign out others'**
  String get signOutOthersButton;

  /// No description provided for @errorSignOutOthersFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sign out other devices: {error}'**
  String errorSignOutOthersFailed(String error);

  /// No description provided for @activeSessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Active Sessions'**
  String get activeSessionsTitle;

  /// No description provided for @couldNotLoadSessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your sessions'**
  String get couldNotLoadSessionsTitle;

  /// No description provided for @unknownDeviceLabel.
  ///
  /// In en, this message translates to:
  /// **'Unknown device'**
  String get unknownDeviceLabel;

  /// No description provided for @thisDeviceBadge.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get thisDeviceBadge;

  /// No description provided for @lastActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Last active {time}'**
  String lastActiveLabel(String time);

  /// No description provided for @signOutDeviceTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sign out this device'**
  String get signOutDeviceTooltip;

  /// No description provided for @currentPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Current password is required.'**
  String get currentPasswordRequired;

  /// No description provided for @newPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'New password must be at least 8 characters.'**
  String get newPasswordTooShort;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitle;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPasswordLabel;

  /// No description provided for @passwordChangedNotice.
  ///
  /// In en, this message translates to:
  /// **'Password changed. Your other devices have been signed out.'**
  String get passwordChangedNotice;

  /// No description provided for @expiryNeverLabel.
  ///
  /// In en, this message translates to:
  /// **'Don\'t clear'**
  String get expiryNeverLabel;

  /// No description provided for @expiryThirtyMinLabel.
  ///
  /// In en, this message translates to:
  /// **'30 minutes'**
  String get expiryThirtyMinLabel;

  /// No description provided for @expiryOneHourLabel.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get expiryOneHourLabel;

  /// No description provided for @expiryFourHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'4 hours'**
  String get expiryFourHoursLabel;

  /// No description provided for @expiryTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get expiryTodayLabel;

  /// No description provided for @setCustomStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a custom status'**
  String get setCustomStatusTitle;

  /// No description provided for @customStatusTextHint.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind?'**
  String get customStatusTextHint;

  /// No description provided for @clearAfterLabel.
  ///
  /// In en, this message translates to:
  /// **'Clear after'**
  String get clearAfterLabel;

  /// No description provided for @clearButton.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearButton;

  /// No description provided for @nameRequiredPeriod.
  ///
  /// In en, this message translates to:
  /// **'Name is required.'**
  String get nameRequiredPeriod;

  /// No description provided for @surnameRequiredPeriod.
  ///
  /// In en, this message translates to:
  /// **'Surname is required.'**
  String get surnameRequiredPeriod;

  /// No description provided for @usernameRequiredPeriod.
  ///
  /// In en, this message translates to:
  /// **'Username is required.'**
  String get usernameRequiredPeriod;

  /// No description provided for @usernameInvalidFormat.
  ///
  /// In en, this message translates to:
  /// **'Only letters, numbers, and underscores - up to 32 characters.'**
  String get usernameInvalidFormat;

  /// No description provided for @errorUploadAvatarFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not upload avatar: {message}'**
  String errorUploadAvatarFailed(String message);

  /// No description provided for @usernameTakenError.
  ///
  /// In en, this message translates to:
  /// **'That username is already taken.'**
  String get usernameTakenError;

  /// No description provided for @checkFieldsError.
  ///
  /// In en, this message translates to:
  /// **'Please check the fields and try again.'**
  String get checkFieldsError;

  /// No description provided for @updateProfileFailedError.
  ///
  /// In en, this message translates to:
  /// **'Could not update profile.'**
  String get updateProfileFailedError;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @avatarLabel.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get avatarLabel;

  /// No description provided for @avatarFormatHint.
  ///
  /// In en, this message translates to:
  /// **'PNG, JPEG, WEBP or GIF, up to 5 MB.'**
  String get avatarFormatHint;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'Letters, numbers, and underscores only.'**
  String get usernameHint;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailCannotChangeNotice.
  ///
  /// In en, this message translates to:
  /// **'Email can\'t be changed yet.'**
  String get emailCannotChangeNotice;

  /// No description provided for @cameraAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera access'**
  String get cameraAccessTitle;

  /// No description provided for @cameraAccessRationale.
  ///
  /// In en, this message translates to:
  /// **'Concord needs camera access to scan the QR code shown on your other device.'**
  String get cameraAccessRationale;

  /// No description provided for @codeInvalidOrExpired.
  ///
  /// In en, this message translates to:
  /// **'That code is invalid or has expired.'**
  String get codeInvalidOrExpired;

  /// No description provided for @couldNotLookUpCode.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t look up that code.'**
  String get couldNotLookUpCode;

  /// No description provided for @deviceApprovedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Device approved.'**
  String get deviceApprovedSnackbar;

  /// No description provided for @errorApproveDeviceFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not approve that device.'**
  String get errorApproveDeviceFailed;

  /// No description provided for @signInRequestDeniedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Sign-in request denied.'**
  String get signInRequestDeniedSnackbar;

  /// No description provided for @errorDenyDeviceFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not deny that device.'**
  String get errorDenyDeviceFailed;

  /// No description provided for @linkDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Link a Device'**
  String get linkDeviceTitle;

  /// No description provided for @linkDeviceInstructions.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code shown on the device you want to sign in, or enter its code below.'**
  String get linkDeviceInstructions;

  /// No description provided for @requestingCameraAccess.
  ///
  /// In en, this message translates to:
  /// **'Requesting camera access…'**
  String get requestingCameraAccess;

  /// No description provided for @cameraAccessNeeded.
  ///
  /// In en, this message translates to:
  /// **'Camera access is needed to scan a QR code.'**
  String get cameraAccessNeeded;

  /// No description provided for @errorCameraAccessFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not access the camera: {detail}'**
  String errorCameraAccessFailed(String detail);

  /// No description provided for @enterCodeManuallyButton.
  ///
  /// In en, this message translates to:
  /// **'Enter code manually'**
  String get enterCodeManuallyButton;

  /// No description provided for @deviceCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Device code'**
  String get deviceCodeLabel;

  /// No description provided for @deviceCodeHint.
  ///
  /// In en, this message translates to:
  /// **'ABCD1234'**
  String get deviceCodeHint;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @scanQrInsteadButton.
  ///
  /// In en, this message translates to:
  /// **'Scan a QR code instead'**
  String get scanQrInsteadButton;

  /// No description provided for @approveDeviceWarning.
  ///
  /// In en, this message translates to:
  /// **'Only approve this if you just started signing in on the device shown above.'**
  String get approveDeviceWarning;

  /// No description provided for @approveButton.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approveButton;

  /// No description provided for @denyButton.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get denyButton;

  /// No description provided for @visibilityEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get visibilityEveryone;

  /// No description provided for @visibilityFriendsOfFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends of friends'**
  String get visibilityFriendsOfFriends;

  /// No description provided for @visibilityNobody.
  ///
  /// In en, this message translates to:
  /// **'Nobody'**
  String get visibilityNobody;

  /// No description provided for @visibilityFriendsOnly.
  ///
  /// In en, this message translates to:
  /// **'Friends only'**
  String get visibilityFriendsOnly;

  /// No description provided for @errorSavePrivacyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save privacy settings: {message}'**
  String errorSavePrivacyFailed(String message);

  /// No description provided for @privacySafetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Safety'**
  String get privacySafetyTitle;

  /// No description provided for @whoCanSendFriendRequests.
  ///
  /// In en, this message translates to:
  /// **'Who can send friend requests'**
  String get whoCanSendFriendRequests;

  /// No description provided for @whoCanDirectMessage.
  ///
  /// In en, this message translates to:
  /// **'Who can direct message you'**
  String get whoCanDirectMessage;

  /// No description provided for @whoCanSeeActivity.
  ///
  /// In en, this message translates to:
  /// **'Who can see your activity'**
  String get whoCanSeeActivity;

  /// No description provided for @readReceiptsLabel.
  ///
  /// In en, this message translates to:
  /// **'Read receipts'**
  String get readReceiptsLabel;

  /// No description provided for @readReceiptsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let others see when you\'ve read their messages.'**
  String get readReceiptsSubtitle;

  /// No description provided for @blockedUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked Users'**
  String get blockedUsersTitle;

  /// No description provided for @errorStartTwoFactorFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start two-factor setup.'**
  String get errorStartTwoFactorFailed;

  /// No description provided for @enterAuthCodeMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter the code from your authenticator app.'**
  String get enterAuthCodeMessage;

  /// No description provided for @twoFactorDisabledSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Two-factor authentication disabled.'**
  String get twoFactorDisabledSnackbar;

  /// No description provided for @errorDisableTwoFactorFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not disable two-factor authentication.'**
  String get errorDisableTwoFactorFailed;

  /// No description provided for @regenerateRecoveryCodesTitle.
  ///
  /// In en, this message translates to:
  /// **'Regenerate recovery codes'**
  String get regenerateRecoveryCodesTitle;

  /// No description provided for @regenerateRecoveryCodesDescription.
  ///
  /// In en, this message translates to:
  /// **'Your existing recovery codes will stop working. Confirm your password to continue.'**
  String get regenerateRecoveryCodesDescription;

  /// No description provided for @regenerateButton.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get regenerateButton;

  /// No description provided for @errorRegenerateCodesFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not regenerate recovery codes.'**
  String get errorRegenerateCodesFailed;

  /// No description provided for @twoFactorSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get twoFactorSectionTitle;

  /// No description provided for @couldNotLoadTwoFactorStatus.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load two-factor status'**
  String get couldNotLoadTwoFactorStatus;

  /// No description provided for @twoFactorOnDescription.
  ///
  /// In en, this message translates to:
  /// **'Two-factor authentication is on. Signing in also requires a code from your authenticator app.'**
  String get twoFactorOnDescription;

  /// No description provided for @twoFactorOffDescription.
  ///
  /// In en, this message translates to:
  /// **'Add an extra layer of security. Once enabled, signing in will require a code from an authenticator app.'**
  String get twoFactorOffDescription;

  /// No description provided for @recoveryCodesRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} recovery code remaining.} other{{count} recovery codes remaining.}}'**
  String recoveryCodesRemaining(int count);

  /// No description provided for @enableTwoFactorButton.
  ///
  /// In en, this message translates to:
  /// **'Enable Two-Factor Authentication'**
  String get enableTwoFactorButton;

  /// No description provided for @disableButton.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disableButton;

  /// No description provided for @scanQrWithAuthenticator.
  ///
  /// In en, this message translates to:
  /// **'Scan this QR code with your authenticator app.'**
  String get scanQrWithAuthenticator;

  /// No description provided for @couldNotRenderQr.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t render the QR code - enter the key below manually.'**
  String get couldNotRenderQr;

  /// No description provided for @enterKeyManually.
  ///
  /// In en, this message translates to:
  /// **'Or enter this key manually'**
  String get enterKeyManually;

  /// No description provided for @confirmationCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirmation code'**
  String get confirmationCodeLabel;

  /// No description provided for @confirmationCodeHint.
  ///
  /// In en, this message translates to:
  /// **'123456'**
  String get confirmationCodeHint;

  /// No description provided for @confirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmButton;

  /// No description provided for @saveRecoveryCodesTitle.
  ///
  /// In en, this message translates to:
  /// **'Save your recovery codes'**
  String get saveRecoveryCodesTitle;

  /// No description provided for @recoveryCodesWarning.
  ///
  /// In en, this message translates to:
  /// **'Each code can be used once to sign in if you lose access to your authenticator. They won\'t be shown again.'**
  String get recoveryCodesWarning;

  /// No description provided for @copiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copiedLabel;

  /// No description provided for @copyCodesButton.
  ///
  /// In en, this message translates to:
  /// **'Copy codes'**
  String get copyCodesButton;

  /// No description provided for @savedCodesButton.
  ///
  /// In en, this message translates to:
  /// **'I\'ve saved these codes'**
  String get savedCodesButton;

  /// No description provided for @disableTwoFactorDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Disable two-factor authentication'**
  String get disableTwoFactorDialogTitle;

  /// No description provided for @disableTwoFactorDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Disabling removes this extra layer of security from your account.'**
  String get disableTwoFactorDialogMessage;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @authOrRecoveryCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Authentication code or recovery code'**
  String get authOrRecoveryCodeLabel;

  /// No description provided for @enterPasswordMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get enterPasswordMessage;

  /// No description provided for @enterCurrentOrRecoveryCodeMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter a current code or a recovery code.'**
  String get enterCurrentOrRecoveryCodeMessage;

  /// No description provided for @voiceVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice & Video'**
  String get voiceVideoTitle;

  /// No description provided for @voiceInfoText.
  ///
  /// In en, this message translates to:
  /// **'Concord will ask for microphone access the first time you join a call, and camera access the first time you turn your camera on. There\'s no separate device picker on mobile - audio output (earpiece/speaker/Bluetooth) is controlled by your device, not this app.'**
  String get voiceInfoText;

  /// No description provided for @voiceNoAudioHint.
  ///
  /// In en, this message translates to:
  /// **'If a call connects with no audio, check your device Settings app for Concord\'s microphone permission.'**
  String get voiceNoAudioHint;

  /// No description provided for @twoFactorConfirmCodeFailed.
  ///
  /// In en, this message translates to:
  /// **'That code did not work. Try again.'**
  String get twoFactorConfirmCodeFailed;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageAzerbaijani.
  ///
  /// In en, this message translates to:
  /// **'Azərbaycan'**
  String get languageAzerbaijani;

  /// No description provided for @preferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesTitle;

  /// No description provided for @muteNotificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Mute notifications'**
  String get muteNotificationsLabel;

  /// No description provided for @muteNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Suppress in-app notification pop-ups.'**
  String get muteNotificationsSubtitle;

  /// No description provided for @notificationSoundLabel.
  ///
  /// In en, this message translates to:
  /// **'Notification sound'**
  String get notificationSoundLabel;

  /// No description provided for @notificationSoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Play a sound for new notifications.'**
  String get notificationSoundSubtitle;

  /// No description provided for @errorSavePreferenceFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save preference: {message}'**
  String errorSavePreferenceFailed(String message);

  /// No description provided for @addServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a Server'**
  String get addServerTitle;

  /// No description provided for @addServerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new server, or join one with an invite code.'**
  String get addServerSubtitle;

  /// No description provided for @createTab.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createTab;

  /// No description provided for @joinTab.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinTab;

  /// No description provided for @serverNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Server name is required.'**
  String get serverNameRequired;

  /// No description provided for @errorUploadIconFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not upload icon: {message}'**
  String errorUploadIconFailed(String message);

  /// No description provided for @serverNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'That server name is not valid.'**
  String get serverNameInvalid;

  /// No description provided for @errorCreateServerFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create server.'**
  String get errorCreateServerFailed;

  /// No description provided for @serverIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Server icon'**
  String get serverIconLabel;

  /// No description provided for @serverIconHint.
  ///
  /// In en, this message translates to:
  /// **'Optional. PNG, JPEG, WEBP or GIF, up to 5 MB.'**
  String get serverIconHint;

  /// No description provided for @serverNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Server name'**
  String get serverNameLabel;

  /// No description provided for @serverNameHint.
  ///
  /// In en, this message translates to:
  /// **'My Server'**
  String get serverNameHint;

  /// No description provided for @creatingServerLoading.
  ///
  /// In en, this message translates to:
  /// **'Creating…'**
  String get creatingServerLoading;

  /// No description provided for @createServerButton.
  ///
  /// In en, this message translates to:
  /// **'Create Server'**
  String get createServerButton;

  /// No description provided for @enterInviteCodeMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter an invite code.'**
  String get enterInviteCodeMessage;

  /// No description provided for @inviteCodeInvalidMessage.
  ///
  /// In en, this message translates to:
  /// **'That invite code is invalid, expired, or no longer works.'**
  String get inviteCodeInvalidMessage;

  /// No description provided for @errorJoinServerFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not join server.'**
  String get errorJoinServerFailed;

  /// No description provided for @inviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCodeLabel;

  /// No description provided for @inviteCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. aB3xQ9'**
  String get inviteCodeHint;

  /// No description provided for @joiningServerLoading.
  ///
  /// In en, this message translates to:
  /// **'Joining…'**
  String get joiningServerLoading;

  /// No description provided for @joinServerButton.
  ///
  /// In en, this message translates to:
  /// **'Join Server'**
  String get joinServerButton;

  /// No description provided for @channelNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Channel name is required.'**
  String get channelNameRequired;

  /// No description provided for @channelNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'That channel name is not valid.'**
  String get channelNameInvalid;

  /// No description provided for @errorCreateChannelFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create channel.'**
  String get errorCreateChannelFailed;

  /// No description provided for @createChannelTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Channel'**
  String get createChannelTitle;

  /// No description provided for @channelTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Channel type'**
  String get channelTypeLabel;

  /// No description provided for @channelNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Channel name'**
  String get channelNameLabel;

  /// No description provided for @channelNameHintVoice.
  ///
  /// In en, this message translates to:
  /// **'general-voice'**
  String get channelNameHintVoice;

  /// No description provided for @channelNameHintText.
  ///
  /// In en, this message translates to:
  /// **'general'**
  String get channelNameHintText;

  /// No description provided for @creatingChannelLoading.
  ///
  /// In en, this message translates to:
  /// **'Creating…'**
  String get creatingChannelLoading;

  /// No description provided for @expiryNeverOption.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get expiryNeverOption;

  /// No description provided for @expiryOneDayLabel.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get expiryOneDayLabel;

  /// No description provided for @expirySevenDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get expirySevenDaysLabel;

  /// No description provided for @maxUsesInvalidMessage.
  ///
  /// In en, this message translates to:
  /// **'Max uses must be a positive number.'**
  String get maxUsesInvalidMessage;

  /// No description provided for @errorGenerateInviteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not generate an invite.'**
  String get errorGenerateInviteFailed;

  /// No description provided for @inviteCodeCopiedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Invite code copied to clipboard'**
  String get inviteCodeCopiedSnackbar;

  /// No description provided for @expiresLabel.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get expiresLabel;

  /// No description provided for @maxUsesLabel.
  ///
  /// In en, this message translates to:
  /// **'Max uses'**
  String get maxUsesLabel;

  /// No description provided for @unlimitedHint.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get unlimitedHint;

  /// No description provided for @generateInviteLinkButton.
  ///
  /// In en, this message translates to:
  /// **'Generate invite link'**
  String get generateInviteLinkButton;

  /// No description provided for @couldNotLoadInvitesTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load invites'**
  String get couldNotLoadInvitesTitle;

  /// No description provided for @noInvitesYetText.
  ///
  /// In en, this message translates to:
  /// **'No invites generated yet.'**
  String get noInvitesYetText;

  /// No description provided for @copyButton.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyButton;

  /// No description provided for @inviteUsesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} use} other{{count} uses}}'**
  String inviteUsesCount(int count);

  /// No description provided for @inviteUsesOfMax.
  ///
  /// In en, this message translates to:
  /// **'{count} / {max} uses{exhausted}'**
  String inviteUsesOfMax(int count, int max, String exhausted);

  /// No description provided for @inviteExhaustedSuffix.
  ///
  /// In en, this message translates to:
  /// **' - exhausted'**
  String get inviteExhaustedSuffix;

  /// No description provided for @neverExpiresLabel.
  ///
  /// In en, this message translates to:
  /// **'Never expires'**
  String get neverExpiresLabel;

  /// No description provided for @expiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expiredLabel;

  /// No description provided for @expiresOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String expiresOnLabel(String date);

  /// No description provided for @errorModerationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not {action}: {message}'**
  String errorModerationFailed(String action, String message);

  /// No description provided for @actionUnmuteMember.
  ///
  /// In en, this message translates to:
  /// **'unmute this member'**
  String get actionUnmuteMember;

  /// No description provided for @actionMuteMember.
  ///
  /// In en, this message translates to:
  /// **'mute this member'**
  String get actionMuteMember;

  /// No description provided for @actionRemoveTimeout.
  ///
  /// In en, this message translates to:
  /// **'remove this timeout'**
  String get actionRemoveTimeout;

  /// No description provided for @actionTimeoutMember.
  ///
  /// In en, this message translates to:
  /// **'time out this member'**
  String get actionTimeoutMember;

  /// No description provided for @actionKickMember.
  ///
  /// In en, this message translates to:
  /// **'kick this member'**
  String get actionKickMember;

  /// No description provided for @actionBanMember.
  ///
  /// In en, this message translates to:
  /// **'ban this member'**
  String get actionBanMember;

  /// No description provided for @unknownErrorLabel.
  ///
  /// In en, this message translates to:
  /// **'unknown error'**
  String get unknownErrorLabel;

  /// No description provided for @unmuteAction.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmuteAction;

  /// No description provided for @muteAction.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get muteAction;

  /// No description provided for @removeTimeoutAction.
  ///
  /// In en, this message translates to:
  /// **'Remove Timeout'**
  String get removeTimeoutAction;

  /// No description provided for @timeoutAction.
  ///
  /// In en, this message translates to:
  /// **'Timeout'**
  String get timeoutAction;

  /// No description provided for @kickAction.
  ///
  /// In en, this message translates to:
  /// **'Kick'**
  String get kickAction;

  /// No description provided for @banAction.
  ///
  /// In en, this message translates to:
  /// **'Ban'**
  String get banAction;

  /// No description provided for @kickConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Kick {name}?'**
  String kickConfirmTitle(String name);

  /// No description provided for @kickConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} will be removed from the server. They can rejoin with a valid invite.'**
  String kickConfirmMessage(String name);

  /// No description provided for @timeoutFiveMin.
  ///
  /// In en, this message translates to:
  /// **'5 minutes'**
  String get timeoutFiveMin;

  /// No description provided for @timeoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Time out {name}?'**
  String timeoutConfirmTitle(String name);

  /// No description provided for @timeoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'They\'ll temporarily lose the ability to send messages and speak in voice channels.'**
  String get timeoutConfirmMessage;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabel;

  /// No description provided for @reasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reasonLabel;

  /// No description provided for @optionalHint.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optionalHint;

  /// No description provided for @banConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Ban {name}?'**
  String banConfirmTitle(String name);

  /// No description provided for @banConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This removes them from the server and blocks them from rejoining through any invite.'**
  String get banConfirmMessage;

  /// No description provided for @renameChannelTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename #{name}'**
  String renameChannelTitle(String name);

  /// No description provided for @errorRenameChannelFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not rename channel.'**
  String get errorRenameChannelFailed;

  /// No description provided for @membersTitle.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get membersTitle;

  /// No description provided for @couldNotLoadMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load members'**
  String get couldNotLoadMembersTitle;

  /// No description provided for @noMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'No members'**
  String get noMembersTitle;

  /// No description provided for @noMembersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This server has no members yet.'**
  String get noMembersSubtitle;

  /// No description provided for @memberGroupHeader.
  ///
  /// In en, this message translates to:
  /// **'{label} - {count}'**
  String memberGroupHeader(String label, int count);

  /// No description provided for @loadMoreButton.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMoreButton;

  /// No description provided for @memberCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} member} other{{count} members}}'**
  String memberCountLabel(int count);

  /// No description provided for @statusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get statusOffline;

  /// No description provided for @mutedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get mutedTooltip;

  /// No description provided for @timedOutUntilTooltip.
  ///
  /// In en, this message translates to:
  /// **'Timed out until {date}'**
  String timedOutUntilTooltip(String date);

  /// No description provided for @moderateMemberTooltip.
  ///
  /// In en, this message translates to:
  /// **'Moderate {name}'**
  String moderateMemberTooltip(String name);

  /// No description provided for @transferOwnershipConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer ownership of {serverName}?'**
  String transferOwnershipConfirmTitle(String serverName);

  /// No description provided for @transferOwnershipConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} will become the new owner. You\'ll remain a member and will then be able to leave the server yourself if you want to.'**
  String transferOwnershipConfirmMessage(String name);

  /// No description provided for @transferButton.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transferButton;

  /// No description provided for @errorTransferOwnershipFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not transfer ownership.'**
  String get errorTransferOwnershipFailed;

  /// No description provided for @transferOwnershipTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer ownership'**
  String get transferOwnershipTitle;

  /// No description provided for @transferOwnershipSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick another member to become the new owner of {serverName}.'**
  String transferOwnershipSubtitle(String serverName);

  /// No description provided for @filterMembersHint.
  ///
  /// In en, this message translates to:
  /// **'Filter members by username…'**
  String get filterMembersHint;

  /// No description provided for @couldNotLoadMembersPeriod.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load members.'**
  String get couldNotLoadMembersPeriod;

  /// No description provided for @noOtherMembersText.
  ///
  /// In en, this message translates to:
  /// **'There\'s nobody else in this server to transfer ownership to yet.'**
  String get noOtherMembersText;

  /// No description provided for @errorSendRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send request: {message}'**
  String errorSendRequestFailed(String message);

  /// No description provided for @errorAcceptRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not accept request: {message}'**
  String errorAcceptRequestFailed(String message);

  /// No description provided for @errorDeclineRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not decline request: {message}'**
  String errorDeclineRequestFailed(String message);

  /// No description provided for @alreadyFriendsBadge.
  ///
  /// In en, this message translates to:
  /// **'Already friends'**
  String get alreadyFriendsBadge;

  /// No description provided for @requestSentLabel.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get requestSentLabel;

  /// No description provided for @acceptButton.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptButton;

  /// No description provided for @declineButton.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineButton;

  /// No description provided for @addButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addButton;

  /// No description provided for @searchByUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter their exact username…'**
  String get searchByUsernameHint;

  /// No description provided for @keepTypingMessage.
  ///
  /// In en, this message translates to:
  /// **'Keep typing - at least {count} characters.'**
  String keepTypingMessage(int count);

  /// No description provided for @findFriendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Find friends by username'**
  String get findFriendsTitle;

  /// No description provided for @findFriendsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need their exact username - this isn\'t a browsable directory. You, existing friends, and blocked users won\'t show up here.'**
  String get findFriendsSubtitle;

  /// No description provided for @searchFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Search failed'**
  String get searchFailedTitle;

  /// No description provided for @noUsersFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFoundTitle;

  /// No description provided for @noUsersFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Nobody matches \"{query}\".'**
  String noUsersFoundSubtitle(String query);

  /// No description provided for @unblockConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Unblock {name}?'**
  String unblockConfirmTitle(String name);

  /// No description provided for @unblockConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'They will be able to see your profile, send you friend requests, and message you again.'**
  String get unblockConfirmMessage;

  /// No description provided for @unblockButton.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblockButton;

  /// No description provided for @unblockedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'{name} can interact with you again.'**
  String unblockedSnackbar(String name);

  /// No description provided for @errorUnblockFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not unblock user: {message}'**
  String errorUnblockFailed(String message);

  /// No description provided for @couldNotLoadBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load blocked users'**
  String get couldNotLoadBlockedTitle;

  /// No description provided for @noBlockedUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'No blocked users'**
  String get noBlockedUsersTitle;

  /// No description provided for @noBlockedUsersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Users you block will show up here. Blocking removes them from your friends and pending requests, and they can\'t message or friend-request you again unless you unblock them.'**
  String get noBlockedUsersSubtitle;

  /// No description provided for @sectionCountSuffix.
  ///
  /// In en, this message translates to:
  /// **' - {count}'**
  String sectionCountSuffix(int count);

  /// No description provided for @blockedHeader.
  ///
  /// In en, this message translates to:
  /// **'BLOCKED'**
  String get blockedHeader;

  /// No description provided for @allFriendsHeader.
  ///
  /// In en, this message translates to:
  /// **'ALL FRIENDS'**
  String get allFriendsHeader;

  /// No description provided for @incomingHeader.
  ///
  /// In en, this message translates to:
  /// **'INCOMING'**
  String get incomingHeader;

  /// No description provided for @outgoingHeader.
  ///
  /// In en, this message translates to:
  /// **'OUTGOING'**
  String get outgoingHeader;

  /// No description provided for @pendingTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingTabLabel;

  /// No description provided for @blockedTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blockedTabLabel;

  /// No description provided for @addFriendTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Friend'**
  String get addFriendTabLabel;

  /// No description provided for @errorStartConversationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start conversation: {message}'**
  String errorStartConversationFailed(String message);

  /// No description provided for @blockConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Block this user?'**
  String get blockConfirmTitle;

  /// No description provided for @blockConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} will be removed from your friends and won\'t be able to message you or see your profile. There\'s no separate \"unfriend\" - this is the only way to end the friendship.'**
  String blockConfirmMessage(String name);

  /// No description provided for @blockUserButton.
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get blockUserButton;

  /// No description provided for @blockedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'{name} was blocked.'**
  String blockedSnackbar(String name);

  /// No description provided for @errorBlockUserFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not block user: {message}'**
  String errorBlockUserFailed(String message);

  /// No description provided for @couldNotLoadFriendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load friends'**
  String get couldNotLoadFriendsTitle;

  /// No description provided for @noFriendsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get noFriendsYetTitle;

  /// No description provided for @noFriendsYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search for someone in the Add Friend tab to send a request.'**
  String get noFriendsYetSubtitle;

  /// No description provided for @messageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageTooltip;

  /// No description provided for @blockTooltip.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get blockTooltip;

  /// No description provided for @nowFriendsSnackbar.
  ///
  /// In en, this message translates to:
  /// **'You and {name} are now friends.'**
  String nowFriendsSnackbar(String name);

  /// No description provided for @thisUserFallback.
  ///
  /// In en, this message translates to:
  /// **'this user'**
  String get thisUserFallback;

  /// No description provided for @couldNotLoadIncomingTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load incoming requests'**
  String get couldNotLoadIncomingTitle;

  /// No description provided for @noIncomingRequestsText.
  ///
  /// In en, this message translates to:
  /// **'No incoming requests.'**
  String get noIncomingRequestsText;

  /// No description provided for @couldNotLoadOutgoingTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load outgoing requests'**
  String get couldNotLoadOutgoingTitle;

  /// No description provided for @noOutgoingRequestsText.
  ///
  /// In en, this message translates to:
  /// **'No outgoing requests.'**
  String get noOutgoingRequestsText;

  /// No description provided for @cancelRequestConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel friend request?'**
  String get cancelRequestConfirmTitle;

  /// No description provided for @cancelRequestConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This cancels your pending friend request to {name}. You\'ll need to send a new request if you change your mind.'**
  String cancelRequestConfirmMessage(String name);

  /// No description provided for @cancelRequestButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request'**
  String get cancelRequestButton;

  /// No description provided for @errorCancelRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel request: {message}'**
  String errorCancelRequestFailed(String message);

  /// No description provided for @pendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingSubtitle;

  /// No description provided for @couldNotLoadConversationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load conversations'**
  String get couldNotLoadConversationsTitle;

  /// No description provided for @noConversationsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversationsYetTitle;

  /// No description provided for @noConversationsYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Message a friend from the Friends tab to start one.'**
  String get noConversationsYetSubtitle;

  /// No description provided for @sentAttachmentPreview.
  ///
  /// In en, this message translates to:
  /// **'Sent an attachment'**
  String get sentAttachmentPreview;

  /// No description provided for @microphoneAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Microphone access'**
  String get microphoneAccessTitle;

  /// No description provided for @microphoneAccessRationale.
  ///
  /// In en, this message translates to:
  /// **'Concord needs microphone access so the other person can hear you on the call.'**
  String get microphoneAccessRationale;

  /// No description provided for @notificationAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationAccessTitle;

  /// No description provided for @notificationAccessRationale.
  ///
  /// In en, this message translates to:
  /// **'Concord can let you know about new messages and friend requests even when the app is closed. Turn on notifications?'**
  String get notificationAccessRationale;

  /// No description provided for @cameraAccessRationaleVideoCalls.
  ///
  /// In en, this message translates to:
  /// **'Concord needs camera access for video calls.'**
  String get cameraAccessRationaleVideoCalls;

  /// No description provided for @directMessageFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Direct Message'**
  String get directMessageFallbackTitle;

  /// No description provided for @startVoiceCallTooltip.
  ///
  /// In en, this message translates to:
  /// **'Start voice call'**
  String get startVoiceCallTooltip;

  /// No description provided for @startVideoCallTooltip.
  ///
  /// In en, this message translates to:
  /// **'Start video call'**
  String get startVideoCallTooltip;

  /// No description provided for @callingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Calling…'**
  String get callingEllipsis;

  /// No description provided for @reconnectingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get reconnectingEllipsis;

  /// No description provided for @inCallLabel.
  ///
  /// In en, this message translates to:
  /// **'In call'**
  String get inCallLabel;

  /// No description provided for @incomingVideoCallTitle.
  ///
  /// In en, this message translates to:
  /// **'Incoming video call'**
  String get incomingVideoCallTitle;

  /// No description provided for @incomingVoiceCallTitle.
  ///
  /// In en, this message translates to:
  /// **'Incoming voice call'**
  String get incomingVoiceCallTitle;

  /// No description provided for @participantYouSuffix.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String participantYouSuffix(String name);

  /// No description provided for @youFallback.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youFallback;

  /// No description provided for @memberFallback.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get memberFallback;

  /// No description provided for @unmuteMicTooltip.
  ///
  /// In en, this message translates to:
  /// **'Unmute microphone'**
  String get unmuteMicTooltip;

  /// No description provided for @muteMicTooltip.
  ///
  /// In en, this message translates to:
  /// **'Mute microphone'**
  String get muteMicTooltip;

  /// No description provided for @undeafenTooltip.
  ///
  /// In en, this message translates to:
  /// **'Undeafen'**
  String get undeafenTooltip;

  /// No description provided for @deafenTooltip.
  ///
  /// In en, this message translates to:
  /// **'Deafen'**
  String get deafenTooltip;

  /// No description provided for @turnOffCameraTooltip.
  ///
  /// In en, this message translates to:
  /// **'Turn off camera'**
  String get turnOffCameraTooltip;

  /// No description provided for @turnOnCameraTooltip.
  ///
  /// In en, this message translates to:
  /// **'Turn on camera'**
  String get turnOnCameraTooltip;

  /// No description provided for @leaveCallTooltip.
  ///
  /// In en, this message translates to:
  /// **'Leave call'**
  String get leaveCallTooltip;

  /// No description provided for @microphoneAccessRationaleChannel.
  ///
  /// In en, this message translates to:
  /// **'Concord needs microphone access so others in this channel can hear you.'**
  String get microphoneAccessRationaleChannel;

  /// No description provided for @joinChannelTitle.
  ///
  /// In en, this message translates to:
  /// **'Join {channelName}'**
  String joinChannelTitle(String channelName);

  /// No description provided for @joinVoiceChannelTitle.
  ///
  /// In en, this message translates to:
  /// **'Join voice channel'**
  String get joinVoiceChannelTitle;

  /// No description provided for @joinVoiceChannelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to start talking with everyone in this channel.'**
  String get joinVoiceChannelSubtitle;

  /// No description provided for @connectingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connectingEllipsis;

  /// No description provided for @joinVoiceButton.
  ///
  /// In en, this message translates to:
  /// **'Join Voice'**
  String get joinVoiceButton;

  /// No description provided for @notificationsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsScreenTitle;

  /// No description provided for @markAllReadButton.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllReadButton;

  /// No description provided for @couldNotLoadNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load notifications'**
  String get couldNotLoadNotificationsTitle;

  /// No description provided for @noNotificationsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYetTitle;

  /// No description provided for @noNotificationsYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Friend requests, missed calls, and mentions will show up here.'**
  String get noNotificationsYetSubtitle;

  /// No description provided for @notifFriendRequestReceived.
  ///
  /// In en, this message translates to:
  /// **'{name} sent you a friend request'**
  String notifFriendRequestReceived(String name);

  /// No description provided for @notifFriendRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'{name} accepted your friend request'**
  String notifFriendRequestAccepted(String name);

  /// No description provided for @notifMissedCall.
  ///
  /// In en, this message translates to:
  /// **'Missed call from {name}'**
  String notifMissedCall(String name);

  /// No description provided for @notifMention.
  ///
  /// In en, this message translates to:
  /// **'{name} mentioned you'**
  String notifMention(String name);

  /// No description provided for @notifMessageReceived.
  ///
  /// In en, this message translates to:
  /// **'{name} sent you a message'**
  String notifMessageReceived(String name);

  /// No description provided for @notifFriendRequestDeclined.
  ///
  /// In en, this message translates to:
  /// **'{name} declined your friend request'**
  String notifFriendRequestDeclined(String name);

  /// No description provided for @notifFriendRequestCancelled.
  ///
  /// In en, this message translates to:
  /// **'{name} cancelled their friend request'**
  String notifFriendRequestCancelled(String name);

  /// No description provided for @searchMessagesHint.
  ///
  /// In en, this message translates to:
  /// **'Search messages…'**
  String get searchMessagesHint;

  /// No description provided for @keepTypingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Keep typing…'**
  String get keepTypingEllipsis;

  /// No description provided for @couldNotSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t search'**
  String get couldNotSearchTitle;

  /// No description provided for @searchAcrossTitle.
  ///
  /// In en, this message translates to:
  /// **'Search across your servers and DMs'**
  String get searchAcrossTitle;

  /// No description provided for @searchMinCharsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Type at least 2 characters to start searching.'**
  String get searchMinCharsSubtitle;

  /// No description provided for @noResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResultsTitle;

  /// No description provided for @noTextContentPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'(no text content)'**
  String get noTextContentPlaceholder;

  /// No description provided for @hidePasswordTooltip.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePasswordTooltip;

  /// No description provided for @showPasswordTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPasswordTooltip;

  /// No description provided for @amLabel.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get amLabel;

  /// No description provided for @pmLabel.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get pmLabel;

  /// No description provided for @todayAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Today at {time}'**
  String todayAtLabel(String time);

  /// No description provided for @yesterdayAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Yesterday at {time}'**
  String yesterdayAtLabel(String time);

  /// No description provided for @justNowLabel.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNowLabel;

  /// No description provided for @minutesAgoLabel.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String minutesAgoLabel(int count);

  /// No description provided for @hoursAgoLabel.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String hoursAgoLabel(int count);

  /// No description provided for @daysAgoLabel.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String daysAgoLabel(int count);

  /// No description provided for @dangerZoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZoneTitle;

  /// No description provided for @deleteAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountButton;

  /// No description provided for @deleteAccountSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and all of your data.'**
  String get deleteAccountSectionDescription;

  /// No description provided for @deleteAccountDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountDialogTitle;

  /// No description provided for @deleteAccountConsequencesMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be logged out of every device immediately. Your account will be deactivated for 30 days - if you log back in during that time, the deletion is cancelled and your account is restored. After 30 days, it\'s permanently deleted and can\'t be recovered.'**
  String get deleteAccountConsequencesMessage;

  /// No description provided for @deleteAccountPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to confirm'**
  String get deleteAccountPasswordLabel;

  /// No description provided for @deleteAccountConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Delete My Account'**
  String get deleteAccountConfirmButton;

  /// No description provided for @deleteAccountIncorrectPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password.'**
  String get deleteAccountIncorrectPasswordError;

  /// No description provided for @deleteAccountFailedError.
  ///
  /// In en, this message translates to:
  /// **'Could not delete your account.'**
  String get deleteAccountFailedError;

  /// No description provided for @deleteAccountSuccessSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted. Log back in within 30 days to cancel the deletion.'**
  String get deleteAccountSuccessSnackbar;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['az', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'az':
      return AppLocalizationsAz();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
