// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Azerbaijani (`az`).
class AppLocalizationsAz extends AppLocalizations {
  AppLocalizationsAz([String locale = 'az']) : super(locale);

  @override
  String get errorCouldNotReachServer =>
      'Concord-a qoşula bilmədik — internet bağlantınızı yoxlayıb yenidən cəhd edin.';

  @override
  String get errorServerTrouble =>
      'Concord hazırda öz tərəfində problem yaşayır. Zəhmət olmasa bir az sonra yenidən cəhd edin.';

  @override
  String get errorSomethingWentWrong =>
      'Nəsə səhv getdi. Zəhmət olmasa yenidən cəhd edin.';

  @override
  String get errorCantReachServer =>
      'Serverə qoşula bilmirik. İnternet bağlantınızı yoxlayın.';

  @override
  String get errorTooManyAttempts =>
      'Çox sayda cəhd edildi. Zəhmət olmasa bir az gözləyib yenidən cəhd edin.';

  @override
  String get errorAccountLocked =>
      'Hesabınız müvəqqəti olaraq bloklanıb. Bir neçə dəqiqədən sonra yenidən cəhd edin.';

  @override
  String get errorInvalidEmailPassword => 'Yanlış e-poçt və ya şifrə';

  @override
  String get errorSignInExpired =>
      'Bu giriş cəhdinin vaxtı bitdi. Geri qayıdıb şifrənizi yenidən daxil edin.';

  @override
  String get errorInvalidCode =>
      'Bu kod düzgün deyil. Autentifikator tətbiqinizi yoxlayın və ya bərpa kodundan istifadə edin.';

  @override
  String get errorAccountExists => 'Bu e-poçt ilə artıq bir hesab mövcuddur.';

  @override
  String get validationEmailRequired => 'E-poçt tələb olunur';

  @override
  String get validationPasswordRequired => 'Şifrə tələb olunur';

  @override
  String get validationNameRequired => 'Ad tələb olunur';

  @override
  String get validationSurnameRequired => 'Soyad tələb olunur';

  @override
  String get validationEmailInvalid => 'Düzgün e-poçt ünvanı daxil edin';

  @override
  String get validationPasswordMinLength =>
      'Şifrə ən azı 8 simvoldan ibarət olmalıdır';

  @override
  String get validationPasswordTooShortPeriod =>
      'Şifrə ən azı 8 simvoldan ibarət olmalıdır.';

  @override
  String get validationPasswordsDontMatch => 'Şifrələr uyğun gəlmir.';

  @override
  String get validationCodeRequired => 'Autentifikasiya kodunuzu daxil edin';

  @override
  String get loginWelcomeBack => 'Yenidən xoş gəldiniz';

  @override
  String get loginSubtitle => 'Sizi yenidən görməyə çox sevindik.';

  @override
  String get loginNeedAccount => 'Hesabınız yoxdur? ';

  @override
  String get registerLink => 'Qeydiyyatdan keçin';

  @override
  String get fieldEmailLabel => 'E-poçt';

  @override
  String get fieldEmailHint => 'siz@numune.com';

  @override
  String get fieldPasswordLabel => 'Şifrə';

  @override
  String get loginSubmitButton => 'Daxil ol';

  @override
  String get loginSubmitButtonLoading => 'Daxil olunur…';

  @override
  String get registerAlreadyHaveAccount => 'Artıq hesabınız var? ';

  @override
  String get loginLink => 'Daxil ol';

  @override
  String get backToLoginButton => 'Girişə qayıt';

  @override
  String get registerCheckEmailTitle => 'E-poçtunuzu yoxlayın';

  @override
  String registerCheckEmailSubtitle(String email) {
    return 'Təsdiq linki $email ünvanına göndərildi. Hesabınızı aktivləşdirmək üçün ona klikləyin, sonra daxil olun.';
  }

  @override
  String get registerCheckEmailFallbackEmail => 'e-poçtunuza';

  @override
  String get registerResendMessageSent => 'Təsdiq e-poçtu göndərildi.';

  @override
  String get registerResendMessageFailed =>
      'Hazırda yenidən göndərmək mümkün olmadı. Bir az sonra yenidən cəhd edin.';

  @override
  String get registerResendButton => 'E-poçtu yenidən göndər';

  @override
  String get registerResendButtonLoading => 'Göndərilir…';

  @override
  String get registerCreateAccountTitle => 'Hesab yaradın';

  @override
  String get registerCreateAccountSubtitle =>
      'Concord-a qoşulun və söhbətə başlayın.';

  @override
  String get fieldNameLabel => 'Ad';

  @override
  String get fieldNameHint => 'Aysel';

  @override
  String get fieldSurnameLabel => 'Soyad';

  @override
  String get fieldSurnameHint => 'Əliyeva';

  @override
  String get passwordMinCharactersHint => 'Ən azı 8 simvol.';

  @override
  String get registerSubmitButton => 'Hesab yarat';

  @override
  String get registerSubmitButtonLoading => 'Hesab yaradılır…';

  @override
  String get resetInvalidLinkTitle => 'Yanlış sıfırlama linki';

  @override
  String get resetInvalidLinkSubtitle =>
      'Bu şifrə sıfırlama linkində token yoxdur.';

  @override
  String get resetLinkExpiredError =>
      'Bu sıfırlama linki etibarsızdır və ya vaxtı bitib. Yeni link tələb edin.';

  @override
  String get resetPasswordTitle => 'Şifrənizi sıfırlayın';

  @override
  String get resetPasswordSubtitle => 'Hesabınız üçün yeni şifrə seçin.';

  @override
  String get fieldNewPasswordLabel => 'Yeni şifrə';

  @override
  String get fieldConfirmNewPasswordLabel => 'Yeni şifrəni təsdiqləyin';

  @override
  String get resetPasswordButton => 'Şifrəni sıfırla';

  @override
  String get resetPasswordButtonLoading => 'Sıfırlanır…';

  @override
  String get twoFactorTitle => 'İki addımlı doğrulama';

  @override
  String get twoFactorSubtitle =>
      'Autentifikator tətbiqinizdəki kodu və ya bərpa kodlarınızdan birini daxil edin.';

  @override
  String get twoFactorBackToSignIn => 'Girişə qayıt';

  @override
  String get fieldAuthCodeLabel => 'Autentifikasiya kodu';

  @override
  String get fieldAuthCodeHint => '123456 və ya ABCD-EFGH';

  @override
  String get twoFactorVerifyButton => 'Təsdiqlə';

  @override
  String get twoFactorVerifyButtonLoading => 'Təsdiqlənir…';

  @override
  String get cancelButton => 'Ləğv et';

  @override
  String get saveButton => 'Yadda saxla';

  @override
  String get tryAgainButton => 'Yenidən cəhd et';

  @override
  String get loadingEllipsis => 'Yüklənir…';

  @override
  String get someoneFallback => 'Kimsə';

  @override
  String get someoneFallbackLower => 'kimsə';

  @override
  String get messagesTab => 'Mesajlar';

  @override
  String get friendsTab => 'Dostlar';

  @override
  String get notificationsTooltip => 'Bildirişlər';

  @override
  String get searchTooltip => 'Axtarış';

  @override
  String get serversTooltip => 'Serverlər';

  @override
  String get voiceConnectedLabel => 'Səs bağlantısı qurulub';

  @override
  String get callConnectedLabel => 'Zəng bağlantısı qurulub';

  @override
  String get tapToReturnLabel => 'Qayıtmaq üçün toxunun';

  @override
  String get channelFallbackTitle => 'Kanal';

  @override
  String leaveServerConfirmTitle(String serverName) {
    return '$serverName tərk edilsin?';
  }

  @override
  String get leaveServerConfirmMessage =>
      'Bu, sizi dərhal serverdən çıxarır. Yenidən qoşulmaq üçün yeni dəvətə ehtiyacınız olacaq.';

  @override
  String get leaveServerButton => 'Serveri tərk et';

  @override
  String errorLeaveServerFailed(String message) {
    return 'Serveri tərk etmək mümkün olmadı: $message';
  }

  @override
  String get serverFallbackTitle => 'Server';

  @override
  String get membersTooltip => 'Üzvlər';

  @override
  String get serverOptionsTooltip => 'Server seçimləri';

  @override
  String get invitePeopleMenuItem => 'İnsanları dəvət et';

  @override
  String get transferOwnershipMenuItem => 'Sahibliyi ötür';

  @override
  String get thisServerFallback => 'bu server';

  @override
  String get couldNotLoadChannelsTitle => 'Kanallar yüklənə bilmədi';

  @override
  String get noChannelsYetTitle => 'Hələ kanal yoxdur';

  @override
  String get noChannelsYetSubtitle =>
      'Bu serverdə yaradılan kanallar burada görünəcək.';

  @override
  String get textChannelsLabel => 'Mətn';

  @override
  String get voiceChannelsLabel => 'Səs';

  @override
  String deleteChannelConfirmTitle(String channelName) {
    return '#$channelName silinsin?';
  }

  @override
  String get deleteChannelConfirmMessage =>
      'Bu, kanalı serverdəki hər kəs üçün dərhal silir. İçindəki bütün mesajlar itiriləcək. Bu geri qaytarıla bilməz.';

  @override
  String get deleteChannelButton => 'Kanalı sil';

  @override
  String errorDeleteChannelFailed(String message) {
    return 'Kanalı silmək mümkün olmadı: $message';
  }

  @override
  String get renameChannelMenuItem => 'Kanalı adlandır';

  @override
  String createChannelTooltip(String channelType) {
    return '$channelType kanalı yarat';
  }

  @override
  String noChannelsOfTypeYet(String channelType) {
    return 'Hələ $channelType kanalı yoxdur.';
  }

  @override
  String get channelOptionsTooltip => 'Kanal seçimləri';

  @override
  String get homeTooltip => 'Əsas (Mesajlar və Dostlar)';

  @override
  String get couldNotLoadServersText => 'Serverlər yüklənə bilmədi';

  @override
  String get addOrJoinServerTooltip => 'Server əlavə et və ya qoşul';

  @override
  String get settingsTooltip => 'Tənzimləmələr';

  @override
  String get logOutTooltip => 'Çıxış et';

  @override
  String get statusOnline => 'Aktiv';

  @override
  String get statusIdle => 'Aralıda';

  @override
  String get statusDoNotDisturb => 'Narahat etməyin';

  @override
  String get statusInvisible => 'Görünməz';

  @override
  String get setStatusTitle => 'Status təyin et';

  @override
  String get messageChannelHint => 'Bu kanala mesaj yazın…';

  @override
  String errorAttachFileFailed(String message) {
    return 'Fayl əlavə edilə bilmədi: $message';
  }

  @override
  String get attachFileTooltip => 'Fayl əlavə et';

  @override
  String get sendTooltip => 'Göndər';

  @override
  String get rateLimitedMessage =>
      'Çox sürətli mesaj göndərirsiniz. Bir az gözləyib yenidən cəhd edin.';

  @override
  String messageTooLong(int maxLength) {
    return 'Mesaj çox uzundur - göndərmək üçün $maxLength simvol və ya daha az olmalıdır.';
  }

  @override
  String get replyingToPrefix => 'Cavab verilir: ';

  @override
  String get cancelReplyTooltip => 'Cavabı ləğv et';

  @override
  String get uploadingEllipsis => 'Yüklənir…';

  @override
  String get readyToSendLabel => 'Göndərməyə hazırdır';

  @override
  String get removeAttachmentTooltip => 'Əlavəni sil';

  @override
  String get couldNotLoadMessagesTitle => 'Mesajlar yüklənə bilmədi';

  @override
  String get noMessagesYetTitle => 'Hələ mesaj yoxdur';

  @override
  String get noMessagesYetSubtitle => 'Söhbəti başlatmaq üçün nəsə yazın.';

  @override
  String get loadOlderMessagesButton => 'Köhnə mesajları yüklə';

  @override
  String reachedBeginningOfThread(String threadNoun) {
    return 'Bu $threadNoun başlanğıcına çatdınız.';
  }

  @override
  String get seenLabel => 'Görüldü';

  @override
  String get scrollToBottomTooltip => 'Aşağı sürüşdür';

  @override
  String get channelThreadNoun => 'kanal';

  @override
  String get conversationThreadNoun => 'söhbət';

  @override
  String get messageCannotBeEmpty => 'Mesaj boş ola bilməz.';

  @override
  String messageTooLongChars(int maxLength) {
    return 'Mesajlar ən çox $maxLength simvol ola bilər.';
  }

  @override
  String get copiedToClipboard => 'Buferə kopyalandı';

  @override
  String errorUpdatePinFailed(String message) {
    return 'Sancağı yeniləmək mümkün olmadı: $message';
  }

  @override
  String errorReactFailed(String message) {
    return 'Reaksiya vermək mümkün olmadı: $message';
  }

  @override
  String get deleteMessageConfirmTitle => 'Mesaj silinsin?';

  @override
  String get hideMessageConfirmTitle => 'Bu mesaj gizlədilsin?';

  @override
  String deleteMessageConfirmMessage(String threadNoun) {
    return 'Bu, mesajı $threadNoun daxilindəki hər kəs üçün silir. Bu geri qaytarıla bilməz.';
  }

  @override
  String get hideMessageConfirmMessage =>
      'Yalnız sizin görünüşünüzdən yox olacaq - digərləri hələ də görə biləcək. Sonradan öz-özünə gizlətməni geri qaytarmağın yolu yoxdur.';

  @override
  String get deleteMessageButton => 'Mesajı sil';

  @override
  String get hideMessageButton => 'Mesajı gizlət';

  @override
  String deletedForEveryoneNotice(String threadNoun) {
    return 'Bu, $threadNoun daxilindəki hər kəs üçün silindi, sadəcə sizdən gizlədilmədi.';
  }

  @override
  String get hiddenOnlyForYouNotice =>
      'Hazırda bunu hər kəs üçün silmək icazəniz yoxdur, ona görə yalnız sizdən gizlədildi.';

  @override
  String errorRemoveMessageFailed(String message) {
    return 'Mesajı silmək mümkün olmadı: $message';
  }

  @override
  String get replyAction => 'Cavabla';

  @override
  String get forwardAction => 'Yönləndir';

  @override
  String get editMessageAction => 'Mesajı redaktə et';

  @override
  String get copyTextAction => 'Mətni kopyala';

  @override
  String get unpinAction => 'Sancaqdan çıxar';

  @override
  String get pinAction => 'Sancaqla';

  @override
  String get hideForMeAction => 'Məndən gizlət';

  @override
  String get editedSuffix => '  (redaktə edilib)';

  @override
  String get originalMessageLabel => 'Orijinal mesaj';

  @override
  String get attachmentLabel => 'Əlavə';

  @override
  String forwardedFromLabel(String name) {
    return '$name tərəfindən yönləndirilib';
  }

  @override
  String typingSingular(String name) {
    return '$name yazır…';
  }

  @override
  String typingTwo(String name1, String name2) {
    return '$name1 və $name2 yazır…';
  }

  @override
  String typingMany(String name1, String name2) {
    return '$name1, $name2 və başqaları yazır…';
  }

  @override
  String get messageForwardedSnackbar => 'Mesaj yönləndirildi.';

  @override
  String get errorForwardMessageFailed =>
      'Bu mesajı yönləndirmək mümkün olmadı.';

  @override
  String get forwardMessageTitle => 'Mesajı yönləndir';

  @override
  String get forwardMessageSubtitle =>
      'Bunu yönləndirmək üçün bir kanal və ya birbaşa mesaj seçin.';

  @override
  String get forwardSearchHint => 'Kanal və ya insan axtar…';

  @override
  String get channelsSectionHeader => 'KANALLAR';

  @override
  String get notInAnyServersText => 'Heç bir serverdə deyilsiniz.';

  @override
  String get noMatchingServersText => 'Uyğun server yoxdur.';

  @override
  String get couldNotLoadYourServersText => 'Serverləriniz yüklənə bilmədi.';

  @override
  String get directMessagesSectionHeader => 'BİRBAŞA MESAJLAR';

  @override
  String get noMatchingConversationsText => 'Uyğun söhbət yoxdur.';

  @override
  String get noMatchingChannelsText => 'Uyğun kanal yoxdur.';

  @override
  String get couldNotLoadChannelsPeriod => 'Kanallar yüklənə bilmədi.';

  @override
  String get sayHiSubtitle => 'Söhbətə başlamaq üçün salam deyin.';

  @override
  String get messageEllipsisHint => 'Mesaj…';

  @override
  String messageUserHint(String name) {
    return '@$name istifadəçisinə mesaj yazın…';
  }

  @override
  String get settingsScreenTitle => 'Tənzimləmələr';

  @override
  String get myAccountTab => 'Hesabım';

  @override
  String get privacyTabLabel => 'Məxfilik';

  @override
  String get voiceTabLabel => 'Səs';

  @override
  String get billingTabLabel => 'Ödəniş';

  @override
  String get editProfileButton => 'Profili redaktə et';

  @override
  String get statusButton => 'Status';

  @override
  String get scanQrCodeButton => 'Vebdə giriş üçün QR kodu skan edin';

  @override
  String get logOutButton => 'Çıxış et';

  @override
  String get logOutConfirmTitle => 'Çıxış etmək istəyirsiniz?';

  @override
  String get logOutConfirmMessage =>
      'Bu cihazda Concord-dan yenidən istifadə etmək üçün yenidən daxil olmalı olacaqsınız.';

  @override
  String get signOutDeviceConfirmTitle => 'Bu cihazdan çıxılsın?';

  @override
  String signOutDeviceConfirmMessage(String label) {
    return '$label dərhal sistemdən çıxarılacaq.';
  }

  @override
  String get signOutButton => 'Çıxış et';

  @override
  String errorSignOutDeviceFailed(String error) {
    return 'Bu cihazdan çıxmaq mümkün olmadı: $error';
  }

  @override
  String get signOutAllOthersConfirmTitle =>
      'Bütün digər cihazlardan çıxılsın?';

  @override
  String get signOutAllOthersConfirmMessage =>
      'Hesabınıza daxil olmuş digər bütün cihazlar dərhal sistemdən çıxarılacaq.';

  @override
  String get signOutOthersButton => 'Digərlərindən çıxış et';

  @override
  String errorSignOutOthersFailed(String error) {
    return 'Digər cihazlardan çıxmaq mümkün olmadı: $error';
  }

  @override
  String get activeSessionsTitle => 'Aktiv Sessiyalar';

  @override
  String get couldNotLoadSessionsTitle => 'Sessiyalarınız yüklənə bilmədi';

  @override
  String get unknownDeviceLabel => 'Naməlum cihaz';

  @override
  String get thisDeviceBadge => 'Bu cihaz';

  @override
  String lastActiveLabel(String time) {
    return 'Son aktivlik $time';
  }

  @override
  String get signOutDeviceTooltip => 'Bu cihazdan çıxış et';

  @override
  String get billingLoadErrorTitle => 'Abunəliyiniz yüklənə bilmədi';

  @override
  String get billingPremiumTitle => 'Concord Premium';

  @override
  String get billingPremiumDescription =>
      'Concord-da əlavə imkanların kilidini açan aylıq abunəlik üçün Premium-a keçin.';

  @override
  String get billingBenefitsTitle => 'Premium ilə əldə etdikləriniz';

  @override
  String get billingBenefitHdVoice => 'Hər zəngdə aydın, HD keyfiyyətli səs';

  @override
  String get billingBenefitVoiceCapacity =>
      'Səs kanallarında daha yüksək iştirakçı limiti';

  @override
  String get billingBenefitUploadLimit =>
      'Söhbətdə paylaşarkən daha böyük fayl yükləmə limiti';

  @override
  String get billingBenefitMessageLength =>
      'Mesajlarınız üçün daha uzun simvol limiti';

  @override
  String get billingCanceledNotice =>
      'Əvvəlki abunəliyiniz başa çatıb. İstədiyiniz zaman yenidən abunə olub davam edə bilərsiniz.';

  @override
  String get billingSubscribeButton => 'Abunə ol';

  @override
  String get billingManageSubscriptionButton => 'Abunəliyi idarə et';

  @override
  String get billingActiveTitle => 'Abunəliyiniz aktivdir';

  @override
  String get billingActiveBadge => 'Aktiv';

  @override
  String get billingEndingBadge => 'Tezliklə bitir';

  @override
  String get billingPastDueBadge => 'Ödəniş uğursuz oldu';

  @override
  String billingRenewsOn(String date) {
    return '$date tarixində yenilənir';
  }

  @override
  String billingEndsOn(String date) {
    return 'Premium girişi $date tarixində bitir';
  }

  @override
  String get billingPerksReminderTitle => 'Premium üstünlükləriniz';

  @override
  String get billingPastDueTitle => 'Son ödənişiniz uğursuz oldu';

  @override
  String get billingPastDueDescription =>
      'Premium üstünlüklərinizi saxlamaq üçün ödəniş metodunuzu yeniləyin.';

  @override
  String get billingLaunchFailedError =>
      'Ödəniş səhifəsi açıla bilmədi. Brauzerinizin quraşdırıldığından əmin olub yenidən cəhd edin.';

  @override
  String get currentPasswordRequired => 'Cari şifrə tələb olunur.';

  @override
  String get newPasswordTooShort =>
      'Yeni şifrə ən azı 8 simvoldan ibarət olmalıdır.';

  @override
  String get changePasswordTitle => 'Şifrəni dəyiş';

  @override
  String get currentPasswordLabel => 'Cari şifrə';

  @override
  String get passwordChangedNotice =>
      'Şifrə dəyişdirildi. Digər cihazlarınız sistemdən çıxarıldı.';

  @override
  String get expiryNeverLabel => 'Təmizlənməsin';

  @override
  String get expiryThirtyMinLabel => '30 dəqiqə';

  @override
  String get expiryOneHourLabel => '1 saat';

  @override
  String get expiryFourHoursLabel => '4 saat';

  @override
  String get expiryTodayLabel => 'Bu gün';

  @override
  String get setCustomStatusTitle => 'Fərdi status təyin edin';

  @override
  String get customStatusTextHint => 'Nə düşünürsünüz?';

  @override
  String get clearAfterLabel => 'Sonra təmizlə';

  @override
  String get clearButton => 'Təmizlə';

  @override
  String get nameRequiredPeriod => 'Ad tələb olunur.';

  @override
  String get surnameRequiredPeriod => 'Soyad tələb olunur.';

  @override
  String get usernameRequiredPeriod => 'İstifadəçi adı tələb olunur.';

  @override
  String get usernameInvalidFormat =>
      'Yalnız hərflər, rəqəmlər və alt xətt - ən çox 32 simvol.';

  @override
  String errorUploadAvatarFailed(String message) {
    return 'Avatar yüklənə bilmədi: $message';
  }

  @override
  String get usernameTakenError => 'Bu istifadəçi adı artıq tutulub.';

  @override
  String get checkFieldsError =>
      'Zəhmət olmasa sahələri yoxlayıb yenidən cəhd edin.';

  @override
  String get updateProfileFailedError => 'Profili yeniləmək mümkün olmadı.';

  @override
  String get editProfileTitle => 'Profili redaktə et';

  @override
  String get avatarLabel => 'Avatar';

  @override
  String get avatarFormatHint => 'PNG, JPEG, WEBP və ya GIF, maksimum 5 MB.';

  @override
  String get usernameLabel => 'İstifadəçi adı';

  @override
  String get usernameHint => 'Yalnız hərflər, rəqəmlər və alt xətt.';

  @override
  String get emailLabel => 'E-poçt';

  @override
  String get emailCannotChangeNotice => 'E-poçt hələ dəyişdirilə bilməz.';

  @override
  String get cameraAccessTitle => 'Kamera girişi';

  @override
  String get cameraAccessRationale =>
      'Concord digər cihazınızda göstərilən QR kodu skan etmək üçün kamera girişinə ehtiyac duyur.';

  @override
  String get codeInvalidOrExpired => 'Bu kod etibarsızdır və ya vaxtı bitib.';

  @override
  String get couldNotLookUpCode => 'Bu kodu axtarmaq mümkün olmadı.';

  @override
  String get deviceApprovedSnackbar => 'Cihaz təsdiqləndi.';

  @override
  String get errorApproveDeviceFailed => 'Bu cihazı təsdiqləmək mümkün olmadı.';

  @override
  String get signInRequestDeniedSnackbar => 'Giriş sorğusu rədd edildi.';

  @override
  String get errorDenyDeviceFailed => 'Bu cihazı rədd etmək mümkün olmadı.';

  @override
  String get linkDeviceTitle => 'Cihaz bağla';

  @override
  String get linkDeviceInstructions =>
      'Daxil olmaq istədiyiniz cihazda göstərilən QR kodu skan edin və ya kodunu aşağıda daxil edin.';

  @override
  String get requestingCameraAccess => 'Kamera girişi sorğulanır…';

  @override
  String get cameraAccessNeeded =>
      'QR kod skan etmək üçün kamera girişi lazımdır.';

  @override
  String errorCameraAccessFailed(String detail) {
    return 'Kameraya giriş mümkün olmadı: $detail';
  }

  @override
  String get enterCodeManuallyButton => 'Kodu əl ilə daxil et';

  @override
  String get deviceCodeLabel => 'Cihaz kodu';

  @override
  String get deviceCodeHint => 'ABCD1234';

  @override
  String get continueButton => 'Davam et';

  @override
  String get scanQrInsteadButton => 'Bunun əvəzinə QR kod skan et';

  @override
  String get approveDeviceWarning =>
      'Bunu yalnız yuxarıda göstərilən cihazda giriş etməyə yeni başlamısınızsa təsdiqləyin.';

  @override
  String get approveButton => 'Təsdiqlə';

  @override
  String get denyButton => 'Rədd et';

  @override
  String get visibilityEveryone => 'Hamı';

  @override
  String get visibilityFriendsOfFriends => 'Dostların dostları';

  @override
  String get visibilityNobody => 'Heç kim';

  @override
  String get visibilityFriendsOnly => 'Yalnız dostlar';

  @override
  String errorSavePrivacyFailed(String message) {
    return 'Məxfilik tənzimləmələri yadda saxlanıla bilmədi: $message';
  }

  @override
  String get privacySafetyTitle => 'Məxfilik və Təhlükəsizlik';

  @override
  String get whoCanSendFriendRequests => 'Kim dostluq sorğusu göndərə bilər';

  @override
  String get whoCanDirectMessage => 'Kim sizə birbaşa mesaj göndərə bilər';

  @override
  String get whoCanSeeActivity => 'Kim fəaliyyətinizi görə bilər';

  @override
  String get readReceiptsLabel => 'Oxunma bildirişləri';

  @override
  String get readReceiptsSubtitle =>
      'Digərləri mesajlarını oxuduğunuzu görsün.';

  @override
  String get blockedUsersTitle => 'Bloklanmış İstifadəçilər';

  @override
  String get errorStartTwoFactorFailed =>
      'İki addımlı doğrulama qurulumu başladıla bilmədi.';

  @override
  String get enterAuthCodeMessage =>
      'Autentifikator tətbiqinizdəki kodu daxil edin.';

  @override
  String get twoFactorDisabledSnackbar => 'İki addımlı doğrulama söndürüldü.';

  @override
  String get errorDisableTwoFactorFailed =>
      'İki addımlı doğrulamanı söndürmək mümkün olmadı.';

  @override
  String get regenerateRecoveryCodesTitle => 'Bərpa kodlarını yenilə';

  @override
  String get regenerateRecoveryCodesDescription =>
      'Mövcud bərpa kodlarınız artıq işləməyəcək. Davam etmək üçün şifrənizi təsdiqləyin.';

  @override
  String get regenerateButton => 'Yenilə';

  @override
  String get errorRegenerateCodesFailed =>
      'Bərpa kodlarını yeniləmək mümkün olmadı.';

  @override
  String get twoFactorSectionTitle => 'İki Addımlı Doğrulama';

  @override
  String get couldNotLoadTwoFactorStatus =>
      'İki addımlı doğrulama statusu yüklənə bilmədi';

  @override
  String get twoFactorOnDescription =>
      'İki addımlı doğrulama aktivdir. Daxil olmaq üçün autentifikator tətbiqinizdən kod tələb olunur.';

  @override
  String get twoFactorOffDescription =>
      'Əlavə təhlükəsizlik qatı əlavə edin. Aktiv edildikdən sonra daxil olmaq üçün autentifikator tətbiqindən kod tələb olunacaq.';

  @override
  String recoveryCodesRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bərpa kodu qalıb.',
      one: '$count bərpa kodu qalıb.',
    );
    return '$_temp0';
  }

  @override
  String get enableTwoFactorButton => 'İki Addımlı Doğrulamanı Aktivləşdir';

  @override
  String get disableButton => 'Söndür';

  @override
  String get scanQrWithAuthenticator =>
      'Bu QR kodu autentifikator tətbiqinizlə skan edin.';

  @override
  String get couldNotRenderQr =>
      'QR kod göstərilə bilmədi - açarı aşağıda əl ilə daxil edin.';

  @override
  String get enterKeyManually => 'Və ya bu açarı əl ilə daxil edin';

  @override
  String get confirmationCodeLabel => 'Təsdiq kodu';

  @override
  String get confirmationCodeHint => '123456';

  @override
  String get confirmButton => 'Təsdiqlə';

  @override
  String get saveRecoveryCodesTitle => 'Bərpa kodlarınızı yadda saxlayın';

  @override
  String get recoveryCodesWarning =>
      'Hər kod autentifikatora girişi itirdiyiniz halda yalnız bir dəfə istifadə edilə bilər. Yenidən göstərilməyəcək.';

  @override
  String get copiedLabel => 'Kopyalandı';

  @override
  String get copyCodesButton => 'Kodları kopyala';

  @override
  String get savedCodesButton => 'Bu kodları saxladım';

  @override
  String get disableTwoFactorDialogTitle => 'İki addımlı doğrulamanı söndür';

  @override
  String get disableTwoFactorDialogMessage =>
      'Söndürmək hesabınızdan bu əlavə təhlükəsizlik qatını çıxarır.';

  @override
  String get passwordLabel => 'Şifrə';

  @override
  String get authOrRecoveryCodeLabel => 'Autentifikasiya kodu və ya bərpa kodu';

  @override
  String get enterPasswordMessage => 'Şifrənizi daxil edin.';

  @override
  String get enterCurrentOrRecoveryCodeMessage =>
      'Cari kod və ya bərpa kodu daxil edin.';

  @override
  String get voiceVideoTitle => 'Səs və Video';

  @override
  String get voiceInfoText =>
      'Concord zənglərə qoşulduğunuz ilk dəfə mikrofon girişi, kameranı ilk dəfə açdığınızda isə kamera girişi istəyəcək. Mobil cihazda ayrıca cihaz seçicisi yoxdur - səs çıxışı (qulaqcıq/spiker/Bluetooth) tətbiq tərəfindən deyil, cihazınız tərəfindən idarə olunur.';

  @override
  String get voiceNoAudioHint =>
      'Zəng səssiz qoşulursa, cihazınızın Tənzimləmələr tətbiqindən Concord-un mikrofon icazəsini yoxlayın.';

  @override
  String get twoFactorConfirmCodeFailed =>
      'Bu kod işləmədi. Yenidən cəhd edin.';

  @override
  String get languageLabel => 'Dil';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageAzerbaijani => 'Azərbaycan';

  @override
  String get preferencesTitle => 'Seçimlər';

  @override
  String get muteNotificationsLabel => 'Bildirişləri səssiz et';

  @override
  String get muteNotificationsSubtitle =>
      'Tətbiq daxili bildiriş pəncərələrini gizlədir.';

  @override
  String get notificationSoundLabel => 'Bildiriş səsi';

  @override
  String get notificationSoundSubtitle => 'Yeni bildirişlər üçün səs çal.';

  @override
  String errorSavePreferenceFailed(String message) {
    return 'Seçim yadda saxlanıla bilmədi: $message';
  }

  @override
  String get addServerTitle => 'Server əlavə et';

  @override
  String get addServerSubtitle =>
      'Yeni server yaradın və ya dəvət kodu ilə birinə qoşulun.';

  @override
  String get createTab => 'Yarat';

  @override
  String get joinTab => 'Qoşul';

  @override
  String get serverNameRequired => 'Server adı tələb olunur.';

  @override
  String errorUploadIconFailed(String message) {
    return 'Nişan yüklənə bilmədi: $message';
  }

  @override
  String get serverNameInvalid => 'Bu server adı düzgün deyil.';

  @override
  String get errorCreateServerFailed => 'Server yaradıla bilmədi.';

  @override
  String get serverIconLabel => 'Server nişanı';

  @override
  String get serverIconHint =>
      'İstəyə bağlı. PNG, JPEG, WEBP və ya GIF, maksimum 5 MB.';

  @override
  String get serverNameLabel => 'Server adı';

  @override
  String get serverNameHint => 'Mənim Serverim';

  @override
  String get creatingServerLoading => 'Yaradılır…';

  @override
  String get createServerButton => 'Server yarat';

  @override
  String get enterInviteCodeMessage => 'Dəvət kodu daxil edin.';

  @override
  String get inviteCodeInvalidMessage =>
      'Bu dəvət kodu etibarsızdır, vaxtı bitib və ya artıq işləmir.';

  @override
  String get errorJoinServerFailed => 'Serverə qoşulmaq mümkün olmadı.';

  @override
  String get inviteCodeLabel => 'Dəvət kodu';

  @override
  String get inviteCodeHint => 'məs. aB3xQ9';

  @override
  String get joiningServerLoading => 'Qoşulur…';

  @override
  String get joinServerButton => 'Serverə qoşul';

  @override
  String get channelNameRequired => 'Kanal adı tələb olunur.';

  @override
  String get channelNameInvalid => 'Bu kanal adı düzgün deyil.';

  @override
  String get errorCreateChannelFailed => 'Kanal yaradıla bilmədi.';

  @override
  String get createChannelTitle => 'Kanal yarat';

  @override
  String get channelTypeLabel => 'Kanal növü';

  @override
  String get channelNameLabel => 'Kanal adı';

  @override
  String get channelNameHintVoice => 'umumi-ses';

  @override
  String get channelNameHintText => 'umumi';

  @override
  String get creatingChannelLoading => 'Yaradılır…';

  @override
  String get expiryNeverOption => 'Heç vaxt';

  @override
  String get expiryOneDayLabel => '1 gün';

  @override
  String get expirySevenDaysLabel => '7 gün';

  @override
  String get maxUsesInvalidMessage =>
      'Maksimum istifadə müsbət ədəd olmalıdır.';

  @override
  String get errorGenerateInviteFailed => 'Dəvət yaradıla bilmədi.';

  @override
  String get inviteCodeCopiedSnackbar => 'Dəvət kodu buferə kopyalandı';

  @override
  String get expiresLabel => 'Bitmə vaxtı';

  @override
  String get maxUsesLabel => 'Maksimum istifadə';

  @override
  String get unlimitedHint => 'Limitsiz';

  @override
  String get generateInviteLinkButton => 'Dəvət linki yarat';

  @override
  String get couldNotLoadInvitesTitle => 'Dəvətlər yüklənə bilmədi';

  @override
  String get noInvitesYetText => 'Hələ dəvət yaradılmayıb.';

  @override
  String get copyButton => 'Kopyala';

  @override
  String inviteUsesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count istifadə',
      one: '$count istifadə',
    );
    return '$_temp0';
  }

  @override
  String inviteUsesOfMax(int count, int max, String exhausted) {
    return '$count / $max istifadə$exhausted';
  }

  @override
  String get inviteExhaustedSuffix => ' - tükənib';

  @override
  String get neverExpiresLabel => 'Heç vaxt bitmir';

  @override
  String get expiredLabel => 'Vaxtı bitib';

  @override
  String expiresOnLabel(String date) {
    return 'Bitmə vaxtı $date';
  }

  @override
  String errorModerationFailed(String action, String message) {
    return '$action mümkün olmadı: $message';
  }

  @override
  String get actionUnmuteMember => 'bu üzvün səsini aç';

  @override
  String get actionMuteMember => 'bu üzvü səssiz et';

  @override
  String get actionRemoveTimeout => 'bu fasiləni ləğv et';

  @override
  String get actionTimeoutMember => 'bu üzvə fasilə ver';

  @override
  String get actionKickMember => 'bu üzvü at';

  @override
  String get actionBanMember => 'bu üzvü blokla';

  @override
  String get unknownErrorLabel => 'naməlum xəta';

  @override
  String get unmuteAction => 'Səsini aç';

  @override
  String get muteAction => 'Səssiz et';

  @override
  String get removeTimeoutAction => 'Fasiləni ləğv et';

  @override
  String get timeoutAction => 'Fasilə ver';

  @override
  String get kickAction => 'At';

  @override
  String get banAction => 'Blokla';

  @override
  String kickConfirmTitle(String name) {
    return '$name atılsın?';
  }

  @override
  String kickConfirmMessage(String name) {
    return '$name serverdən çıxarılacaq. Etibarlı dəvətlə yenidən qoşula bilər.';
  }

  @override
  String get timeoutFiveMin => '5 dəqiqə';

  @override
  String timeoutConfirmTitle(String name) {
    return '$name istifadəçisinə fasilə verilsin?';
  }

  @override
  String get timeoutConfirmMessage =>
      'Müvəqqəti olaraq mesaj göndərmək və səs kanallarında danışmaq imkanını itirəcək.';

  @override
  String get durationLabel => 'Müddət';

  @override
  String get reasonLabel => 'Səbəb';

  @override
  String get optionalHint => 'İstəyə bağlı';

  @override
  String banConfirmTitle(String name) {
    return '$name bloklansın?';
  }

  @override
  String get banConfirmMessage =>
      'Bu, onları serverdən çıxarır və hər hansı dəvətlə yenidən qoşulmalarının qarşısını alır.';

  @override
  String renameChannelTitle(String name) {
    return '#$name adlandır';
  }

  @override
  String get errorRenameChannelFailed => 'Kanalı adlandırmaq mümkün olmadı.';

  @override
  String get membersTitle => 'Üzvlər';

  @override
  String get couldNotLoadMembersTitle => 'Üzvlər yüklənə bilmədi';

  @override
  String get noMembersTitle => 'Üzv yoxdur';

  @override
  String get noMembersSubtitle => 'Bu serverdə hələ üzv yoxdur.';

  @override
  String memberGroupHeader(String label, int count) {
    return '$label - $count';
  }

  @override
  String get loadMoreButton => 'Daha çox yüklə';

  @override
  String memberCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count üzv',
      one: '$count üzv',
    );
    return '$_temp0';
  }

  @override
  String get statusOffline => 'Oflayn';

  @override
  String get mutedTooltip => 'Səssiz edilib';

  @override
  String timedOutUntilTooltip(String date) {
    return '$date tarixinə qədər fasilədədir';
  }

  @override
  String moderateMemberTooltip(String name) {
    return '$name üçün moderasiya';
  }

  @override
  String transferOwnershipConfirmTitle(String serverName) {
    return '$serverName sahibliyi ötürülsün?';
  }

  @override
  String transferOwnershipConfirmMessage(String name) {
    return '$name yeni sahib olacaq. Siz üzv olaraq qalacaqsınız və istəsəniz sonra serveri özünüz tərk edə bilərsiniz.';
  }

  @override
  String get transferButton => 'Ötür';

  @override
  String get errorTransferOwnershipFailed => 'Sahibliyi ötürmək mümkün olmadı.';

  @override
  String get transferOwnershipTitle => 'Sahibliyi ötür';

  @override
  String transferOwnershipSubtitle(String serverName) {
    return '$serverName serverinin yeni sahibi olacaq başqa üzv seçin.';
  }

  @override
  String get filterMembersHint => 'İstifadəçi adına görə üzvləri filtrləyin…';

  @override
  String get couldNotLoadMembersPeriod => 'Üzvlər yüklənə bilmədi.';

  @override
  String get noOtherMembersText =>
      'Bu serverdə sahibliyi ötürə biləcəyiniz başqa heç kim yoxdur.';

  @override
  String errorSendRequestFailed(String message) {
    return 'Sorğu göndərilə bilmədi: $message';
  }

  @override
  String errorAcceptRequestFailed(String message) {
    return 'Sorğu qəbul edilə bilmədi: $message';
  }

  @override
  String errorDeclineRequestFailed(String message) {
    return 'Sorğu rədd edilə bilmədi: $message';
  }

  @override
  String get alreadyFriendsBadge => 'Artıq dostsunuz';

  @override
  String get requestSentLabel => 'Sorğu göndərildi';

  @override
  String get acceptButton => 'Qəbul et';

  @override
  String get declineButton => 'Rədd et';

  @override
  String get addButton => 'Əlavə et';

  @override
  String get searchByUsernameHint => 'Onların tam istifadəçi adını daxil edin…';

  @override
  String keepTypingMessage(int count) {
    return 'Yazmağa davam edin - ən azı $count simvol.';
  }

  @override
  String get findFriendsTitle => 'İstifadəçi adı ilə dost tapın';

  @override
  String get findFriendsSubtitle =>
      'Onların tam istifadəçi adı lazımdır - bu, gözdən keçirilə bilən siyahı deyil. Siz, mövcud dostlarınız və blokladığınız istifadəçilər burada görünməyəcək.';

  @override
  String get searchFailedTitle => 'Axtarış uğursuz oldu';

  @override
  String get noUsersFoundTitle => 'İstifadəçi tapılmadı';

  @override
  String noUsersFoundSubtitle(String query) {
    return '\"$query\" ilə heç kim uyğun gəlmir.';
  }

  @override
  String unblockConfirmTitle(String name) {
    return '$name blokdan çıxarılsın?';
  }

  @override
  String get unblockConfirmMessage =>
      'Onlar profilinizi görə, sizə dostluq sorğusu göndərə və yenidən sizə mesaj yaza biləcək.';

  @override
  String get unblockButton => 'Blokdan çıxar';

  @override
  String unblockedSnackbar(String name) {
    return '$name yenidən sizinlə əlaqə saxlaya bilər.';
  }

  @override
  String errorUnblockFailed(String message) {
    return 'İstifadəçini blokdan çıxarmaq mümkün olmadı: $message';
  }

  @override
  String get couldNotLoadBlockedTitle =>
      'Bloklanmış istifadəçilər yüklənə bilmədi';

  @override
  String get noBlockedUsersTitle => 'Bloklanmış istifadəçi yoxdur';

  @override
  String get noBlockedUsersSubtitle =>
      'Blokladığınız istifadəçilər burada görünəcək. Bloklamaq onları dostlarınızdan və gözləyən sorğulardan çıxarır, siz blokdan çıxarana qədər sizə mesaj və ya dostluq sorğusu göndərə bilməzlər.';

  @override
  String sectionCountSuffix(int count) {
    return ' - $count';
  }

  @override
  String get blockedHeader => 'BLOKLANMIŞLAR';

  @override
  String get allFriendsHeader => 'BÜTÜN DOSTLAR';

  @override
  String get incomingHeader => 'GƏLƏN';

  @override
  String get outgoingHeader => 'GEDƏN';

  @override
  String get pendingTabLabel => 'Gözləyən';

  @override
  String get blockedTabLabel => 'Bloklanmış';

  @override
  String get addFriendTabLabel => 'Dost Əlavə Et';

  @override
  String errorStartConversationFailed(String message) {
    return 'Söhbət başlamaq mümkün olmadı: $message';
  }

  @override
  String get blockConfirmTitle => 'Bu istifadəçi bloklansın?';

  @override
  String blockConfirmMessage(String name) {
    return '$name dostlarınızdan çıxarılacaq və sizə mesaj yaza və ya profilinizi görə bilməyəcək. Ayrıca \"dostluqdan çıxar\" seçimi yoxdur - dostluğu bitirməyin yeganə yolu budur.';
  }

  @override
  String get blockUserButton => 'İstifadəçini blokla';

  @override
  String blockedSnackbar(String name) {
    return '$name bloklandı.';
  }

  @override
  String errorBlockUserFailed(String message) {
    return 'İstifadəçini bloklamaq mümkün olmadı: $message';
  }

  @override
  String get couldNotLoadFriendsTitle => 'Dostlar yüklənə bilmədi';

  @override
  String get noFriendsYetTitle => 'Hələ dost yoxdur';

  @override
  String get noFriendsYetSubtitle =>
      'Sorğu göndərmək üçün Dost Əlavə Et bölməsində kimisə axtarın.';

  @override
  String get messageTooltip => 'Mesaj';

  @override
  String get blockTooltip => 'Blokla';

  @override
  String nowFriendsSnackbar(String name) {
    return 'Siz və $name artıq dostsunuz.';
  }

  @override
  String get thisUserFallback => 'bu istifadəçi';

  @override
  String get couldNotLoadIncomingTitle => 'Gələn sorğular yüklənə bilmədi';

  @override
  String get noIncomingRequestsText => 'Gələn sorğu yoxdur.';

  @override
  String get couldNotLoadOutgoingTitle => 'Gedən sorğular yüklənə bilmədi';

  @override
  String get noOutgoingRequestsText => 'Gedən sorğu yoxdur.';

  @override
  String get cancelRequestConfirmTitle => 'Dostluq sorğusu ləğv edilsin?';

  @override
  String cancelRequestConfirmMessage(String name) {
    return 'Bu, $name istifadəçisinə göndərdiyiniz gözləyən dostluq sorğusunu ləğv edir. Fikrinizi dəyişsəniz yeni sorğu göndərməli olacaqsınız.';
  }

  @override
  String get cancelRequestButton => 'Sorğunu ləğv et';

  @override
  String errorCancelRequestFailed(String message) {
    return 'Sorğunu ləğv etmək mümkün olmadı: $message';
  }

  @override
  String get pendingSubtitle => 'Gözləyir';

  @override
  String get couldNotLoadConversationsTitle => 'Söhbətlər yüklənə bilmədi';

  @override
  String get noConversationsYetTitle => 'Hələ söhbət yoxdur';

  @override
  String get noConversationsYetSubtitle =>
      'Söhbətə başlamaq üçün Dostlar bölməsindən bir dosta mesaj yazın.';

  @override
  String get sentAttachmentPreview => 'Əlavə göndərildi';

  @override
  String get microphoneAccessTitle => 'Mikrofon girişi';

  @override
  String get microphoneAccessRationale =>
      'Concord digər şəxsin sizi zəngdə eşitməsi üçün mikrofon girişinə ehtiyac duyur.';

  @override
  String get notificationAccessTitle => 'Bildirişlər';

  @override
  String get notificationAccessRationale =>
      'Tətbiq bağlı olsa belə, Concord yeni mesajlar və dostluq sorğuları haqqında sizə məlumat verə bilər. Bildirişləri aktivləşdirmək istəyirsiniz?';

  @override
  String get cameraAccessRationaleVideoCalls =>
      'Concord video zənglər üçün kamera girişinə ehtiyac duyur.';

  @override
  String get directMessageFallbackTitle => 'Birbaşa Mesaj';

  @override
  String get startVoiceCallTooltip => 'Səs zəngi başlat';

  @override
  String get startVideoCallTooltip => 'Video zəng başlat';

  @override
  String get callingEllipsis => 'Zəng edilir…';

  @override
  String get reconnectingEllipsis => 'Yenidən qoşulur…';

  @override
  String get inCallLabel => 'Zəngdə';

  @override
  String get incomingVideoCallTitle => 'Gələn video zəng';

  @override
  String get incomingVoiceCallTitle => 'Gələn səs zəngi';

  @override
  String participantYouSuffix(String name) {
    return '$name (siz)';
  }

  @override
  String get youFallback => 'Siz';

  @override
  String get memberFallback => 'Üzv';

  @override
  String get unmuteMicTooltip => 'Mikrofonu aç';

  @override
  String get muteMicTooltip => 'Mikrofonu səssiz et';

  @override
  String get undeafenTooltip => 'Səsi aç';

  @override
  String get deafenTooltip => 'Səsi bağla';

  @override
  String get turnOffCameraTooltip => 'Kameranı söndür';

  @override
  String get turnOnCameraTooltip => 'Kameranı aç';

  @override
  String get leaveCallTooltip => 'Zəngi tərk et';

  @override
  String get microphoneAccessRationaleChannel =>
      'Concord bu kanaldakı digərlərinin sizi eşitməsi üçün mikrofon girişinə ehtiyac duyur.';

  @override
  String joinChannelTitle(String channelName) {
    return '$channelName qoşulun';
  }

  @override
  String get joinVoiceChannelTitle => 'Səs kanalına qoşulun';

  @override
  String get joinVoiceChannelSubtitle =>
      'Bu kanaldakı hər kəslə danışmağa başlamaq üçün qoşulun.';

  @override
  String get connectingEllipsis => 'Qoşulur…';

  @override
  String get joinVoiceButton => 'Səsə qoşul';

  @override
  String get notificationsScreenTitle => 'Bildirişlər';

  @override
  String get markAllReadButton => 'Hamısını oxunmuş et';

  @override
  String get couldNotLoadNotificationsTitle => 'Bildirişlər yüklənə bilmədi';

  @override
  String get noNotificationsYetTitle => 'Hələ bildiriş yoxdur';

  @override
  String get noNotificationsYetSubtitle =>
      'Dostluq sorğuları, buraxılmış zənglər və qeyd olunmalar burada görünəcək.';

  @override
  String notifFriendRequestReceived(String name) {
    return '$name sizə dostluq sorğusu göndərdi';
  }

  @override
  String notifFriendRequestAccepted(String name) {
    return '$name dostluq sorğunuzu qəbul etdi';
  }

  @override
  String notifMissedCall(String name) {
    return '$name tərəfindən buraxılmış zəng';
  }

  @override
  String notifMention(String name) {
    return '$name sizi qeyd etdi';
  }

  @override
  String notifMessageReceived(String name) {
    return '$name sizə mesaj göndərdi';
  }

  @override
  String notifFriendRequestDeclined(String name) {
    return '$name dostluq sorğunuzu rədd etdi';
  }

  @override
  String notifFriendRequestCancelled(String name) {
    return '$name dostluq sorğusunu ləğv etdi';
  }

  @override
  String get searchMessagesHint => 'Mesajları axtar…';

  @override
  String get keepTypingEllipsis => 'Yazmağa davam edin…';

  @override
  String get couldNotSearchTitle => 'Axtarış edilə bilmədi';

  @override
  String get searchAcrossTitle =>
      'Serverləriniz və birbaşa mesajlarınız daxilində axtarın';

  @override
  String get searchMinCharsSubtitle =>
      'Axtarışa başlamaq üçün ən azı 2 simvol yazın.';

  @override
  String get noResultsTitle => 'Nəticə yoxdur';

  @override
  String get noTextContentPlaceholder => '(mətn məzmunu yoxdur)';

  @override
  String get hidePasswordTooltip => 'Şifrəni gizlət';

  @override
  String get showPasswordTooltip => 'Şifrəni göstər';

  @override
  String get amLabel => 'AM';

  @override
  String get pmLabel => 'PM';

  @override
  String todayAtLabel(String time) {
    return 'Bu gün, saat $time';
  }

  @override
  String yesterdayAtLabel(String time) {
    return 'Dünən, saat $time';
  }

  @override
  String get justNowLabel => 'indicə';

  @override
  String minutesAgoLabel(int count) {
    return '${count}d əvvəl';
  }

  @override
  String hoursAgoLabel(int count) {
    return '${count}s əvvəl';
  }

  @override
  String daysAgoLabel(int count) {
    return '${count}g əvvəl';
  }

  @override
  String get dangerZoneTitle => 'Təhlükəli zona';

  @override
  String get deleteAccountButton => 'Hesabı sil';

  @override
  String get deleteAccountSectionDescription =>
      'Hesabınızı və bütün məlumatlarınızı həmişəlik silin.';

  @override
  String get deleteAccountDialogTitle =>
      'Hesabınızı silmək istədiyinizə əminsiniz?';

  @override
  String get deleteAccountConsequencesMessage =>
      'Dərhal bütün cihazlardan çıxış ediləcəksiniz. Hesabınız 30 gün ərzində deaktiv olunacaq - bu müddət ərzində yenidən daxil olsanız, silinmə ləğv olunacaq və hesabınız bərpa ediləcək. 30 gündən sonra hesab həmişəlik silinir və bərpa edilə bilməz.';

  @override
  String get deleteAccountPasswordLabel =>
      'Təsdiqləmək üçün şifrənizi daxil edin';

  @override
  String get deleteAccountConfirmButton => 'Hesabımı sil';

  @override
  String get deleteAccountIncorrectPasswordError => 'Şifrə yanlışdır.';

  @override
  String get deleteAccountFailedError => 'Hesab silinə bilmədi.';

  @override
  String get deleteAccountSuccessSnackbar =>
      'Hesabınız silindi. Silinməni ləğv etmək üçün 30 gün ərzində yenidən daxil olun.';
}
