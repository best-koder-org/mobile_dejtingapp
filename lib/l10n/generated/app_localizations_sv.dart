// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appTitle => 'DejTing';

  @override
  String get appName => 'DejTing';

  @override
  String get continueButton => 'Fortsätt';

  @override
  String get nextButton => 'Nästa';

  @override
  String get cancelButton => 'Avbryt';

  @override
  String get saveButton => 'Spara';

  @override
  String get doneButton => 'Klar';

  @override
  String get skipButton => 'Hoppa över';

  @override
  String get backButton => 'Tillbaka';

  @override
  String get retryButton => 'Försök igen';

  @override
  String get okButton => 'OK';

  @override
  String get deleteButton => 'Ta bort';

  @override
  String get reportButton => 'Rapportera';

  @override
  String get blockButton => 'Blockera';

  @override
  String get gotItButton => 'Uppfattat';

  @override
  String get closeButton => 'Stäng';

  @override
  String get goBackButton => 'Gå tillbaka';

  @override
  String get tryAgainButton => 'Försök igen';

  @override
  String get refreshButton => 'Uppdatera';

  @override
  String get upgradeButton => 'Uppgradera';

  @override
  String get manageButton => 'Hantera';

  @override
  String get unblockButton => 'Avblockera';

  @override
  String get logoutButton => 'Logga ut';

  @override
  String get skipForNow => 'Hoppa över för nu';

  @override
  String get notNow => 'Inte nu';

  @override
  String get comingSoon => 'Kommer snart';

  @override
  String get orDivider => 'eller';

  @override
  String get navDiscover => 'Utforska';

  @override
  String get navMatches => 'Matchningar';

  @override
  String get navProfile => 'Profil';

  @override
  String get loginTitle => 'Logga in';

  @override
  String get registerTitle => 'Skapa konto';

  @override
  String get loginTagline => 'Hitta din perfekta match';

  @override
  String get noPasswordsNeeded => 'Inga lösenord behövs';

  @override
  String get phoneSignInDescription =>
      'Logga in med ditt telefonnummer.\nVi skickar en verifieringskod via SMS.';

  @override
  String get continueWithPhone => 'Fortsätt med telefonnummer';

  @override
  String get continueWithApple => 'Fortsätt med Apple';

  @override
  String get continueWithGoogle => 'Fortsätt med Google';

  @override
  String get signInWithBrowser => 'Logga in via webbläsare';

  @override
  String get signInWithPhone => 'Logga in med telefonnummer';

  @override
  String get browserLoginFailed =>
      'Inloggning via webbläsare misslyckades. Försök igen.';

  @override
  String get backToLogin => 'Tillbaka till inloggning';

  @override
  String get troubleLoggingIn => 'Problem att logga in?';

  @override
  String get logoutConfirmation => 'Är du säker på att du vill logga ut?';

  @override
  String get authRequired => 'Autentisering krävs';

  @override
  String get authRequiredDetail => 'Autentisering krävs. Logga in igen.';

  @override
  String get createAccount => 'Skapa konto';

  @override
  String get termsIntro =>
      'Genom att trycka Logga in eller Fortsätt godkänner du våra ';

  @override
  String get termsLink => 'Villkor';

  @override
  String get privacyIntro => '. Läs hur vi behandlar dina uppgifter i vår ';

  @override
  String get privacyPolicyLink => 'Integritetspolicy';

  @override
  String get onboardingPhoneTitle => 'Kan vi få ditt nummer?';

  @override
  String get phoneVerificationExplainer =>
      'Vi skickar ett SMS med en verifieringskod. Vanliga meddelandekostnader kan tillkomma.';

  @override
  String get phoneNumberHint => 'Telefonnummer';

  @override
  String get phoneVerificationMobileOnly =>
      'Telefonverifiering kräver en mobil enhet (Android/iOS).';

  @override
  String get failedToSendCode =>
      'Kunde inte skicka verifieringskod. Försök igen.';

  @override
  String get selectCountry => 'Välj land';

  @override
  String get useDifferentSim => 'Använd ett annat SIM-nummer';

  @override
  String get continueInfoBox =>
      'När du trycker \"Fortsätt\" skickar vi ett SMS med en verifieringskod.';

  @override
  String get enterVerificationCode => 'Ange verifieringskod';

  @override
  String codeSentToPhone(String phone) {
    return 'Vi skickade en 6-siffrig kod till $phone';
  }

  @override
  String get codeSentToPhoneFallback =>
      'Vi skickade en 6-siffrig kod till ditt telefonnummer.';

  @override
  String get verificationSessionExpired =>
      'Verifieringssessionen har gått ut. Gå tillbaka och försök igen.';

  @override
  String get invalidCode => 'Ogiltig kod. Försök igen.';

  @override
  String get verificationFailed => 'Verifiering misslyckades. Försök igen.';

  @override
  String get loginFailed => 'Inloggning misslyckades. Försök igen.';

  @override
  String get couldNotCompleteLogin =>
      'Kunde inte slutföra telefoninloggning. Försök igen.';

  @override
  String get verifying => 'Verifierar...';

  @override
  String get resendCode => 'Fick du ingen kod? Skicka igen';

  @override
  String get maxResendReached => 'Max antal omsändningar nått';

  @override
  String resendCodeIn(int seconds) {
    return 'Skicka kod igen om ${seconds}s';
  }

  @override
  String codeResent(int remaining) {
    return 'Koden skickad igen ($remaining kvar)';
  }

  @override
  String get smsRatesInfo =>
      'Vanliga SMS-kostnader kan tillkomma. Koden löper ut om 10 minuter.';

  @override
  String get welcomeToDejTing => 'Välkommen till DejTing.';

  @override
  String get followHouseRules => 'Följ dessa husregler.';

  @override
  String get ruleBeYourself => 'Var dig själv';

  @override
  String get ruleBeYourselfDesc =>
      'Använd autentiska foton och korrekt information om dig själv.';

  @override
  String get ruleStaySafe => 'Var försiktig';

  @override
  String get ruleStaySafeDesc =>
      'Skydda din personliga information och rapportera misstänkt beteende.';

  @override
  String get rulePlayItCool => 'Ta det lugnt';

  @override
  String get rulePlayItCoolDesc => 'Behandla alla med respekt och vänlighet.';

  @override
  String get ruleBeProactive => 'Var aktiv';

  @override
  String get ruleBeProactiveDesc =>
      'Ta initiativ och skapa meningsfulla kontakter.';

  @override
  String get iAgreeButton => 'Jag godkänner';

  @override
  String get whatsYourFirstName => 'Vad heter du i förnamn?';

  @override
  String get nameAppearOnProfile => 'Så här visas det på din profil.';

  @override
  String get firstNameHint => 'Förnamn';

  @override
  String get yourBirthday => 'Din födelsedag?';

  @override
  String get birthdayExplainer =>
      'Din profil visar din ålder, inte ditt födelsedatum.\nDu kan inte ändra detta senare.';

  @override
  String get monthLabel => 'Månad';

  @override
  String get dayLabel => 'Dag';

  @override
  String get yearLabel => 'År';

  @override
  String youAreNYearsOld(int age) {
    return 'Du är $age år gammal';
  }

  @override
  String get ageRequirement => 'Ålderskrav';

  @override
  String get mustBe18 =>
      'Du måste vara 18 år eller äldre för att använda appen.';

  @override
  String get whatsYourGender => 'Vad är ditt\nkön?';

  @override
  String get genderMan => 'Man';

  @override
  String get genderWoman => 'Kvinna';

  @override
  String get genderNonBinary => 'Icke-binär';

  @override
  String get genderOther => 'Annat';

  @override
  String get moreOptions => 'Fler';

  @override
  String get selectGenderSheet => 'Välj det som bäst\nrepresenterar dig';

  @override
  String get showGenderOnProfile => 'Visa mitt kön på min profil';

  @override
  String get whatsYourOrientation => 'Vad är din sexuella\nläggning?';

  @override
  String get selectOrientations =>
      'Välj alla som beskriver dig för att återspegla din identitet.';

  @override
  String get showOrientationOnProfile => 'Visa min läggning på min profil';

  @override
  String get whatAreYouLookingFor => 'Vad söker\ndu?';

  @override
  String get notShownUnlessYouChoose =>
      'Visas inte på profilen om du inte väljer det';

  @override
  String get showMe => 'Visa mig';

  @override
  String get prefMen => 'Män';

  @override
  String get prefWomen => 'Kvinnor';

  @override
  String get prefEveryone => 'Alla';

  @override
  String get addPhotos => 'Lägg till foton';

  @override
  String get photosSubtitle =>
      'Lägg till minst 2 foton för att fortsätta. Ditt första foto är din profilbild.';

  @override
  String get takeAPhoto => 'Ta ett foto';

  @override
  String get chooseFromGallery => 'Välj från galleri';

  @override
  String get uploading => 'Laddar upp...';

  @override
  String photosReady(int count) {
    return '$count/6 foton · Klart!';
  }

  @override
  String addMorePhotos(int count, int remaining) {
    return '$count/6 foton · Lägg till $remaining till';
  }

  @override
  String get tapToRetry => 'Tryck för att försöka igen';

  @override
  String get mainPhotoBadge => 'Huvud';

  @override
  String get notAuthenticated => 'Inte autentiserad';

  @override
  String get photoUploadedSuccess => 'Foto uppladdat!';

  @override
  String get photoDeletedSuccess => 'Foto borttaget';

  @override
  String get primaryPhotoUpdated => 'Huvudfoto uppdaterat';

  @override
  String get selectPhotoSource => 'Välj fotokälla';

  @override
  String get camera => 'Kamera';

  @override
  String get gallery => 'Galleri';

  @override
  String get deletePhotoTitle => 'Ta bort foto';

  @override
  String get deletePhotoConfirmation =>
      'Är du säker på att du vill ta bort detta foto?';

  @override
  String get primaryPhoto => 'Huvudfoto';

  @override
  String photoNumber(int number) {
    return 'Foto $number';
  }

  @override
  String get requiredLabel => 'Obligatoriskt';

  @override
  String get primaryLabel => 'Huvudbild';

  @override
  String get replacePhoto => 'Byt foto';

  @override
  String get setAsPrimary => 'Ange som huvudbild';

  @override
  String get deletePhoto => 'Ta bort foto';

  @override
  String get photoTips => 'Fototips';

  @override
  String get photoTipsBody =>
      '• Använd tydliga foton av hög kvalitet\n• Se till att ditt ansikte syns\n• Undvik gruppfoton som huvudbild\n• Visa din personlighet och dina intressen\n• Håll det aktuellt och autentiskt';

  @override
  String get lifestyleHabits => 'Livsstilsvanor';

  @override
  String get lifestyleSubtitle =>
      'Dessa är valfria men hjälper till att hitta bättre matchningar.';

  @override
  String get whatAreYouInto => 'Vad gillar du?';

  @override
  String get whatMakesYouYou => 'Vad mer gör\ndig till dig?';

  @override
  String get authenticitySubtitle =>
      'Håll inte tillbaka. Äkthet attraherar äkthet.';

  @override
  String get letsGo => 'Kör igång! 🎉';

  @override
  String get skipAndFinish => 'Hoppa över & avsluta';

  @override
  String get enableLocation => 'Aktivera plats';

  @override
  String get locationDescription =>
      'Vi använder din plats för att visa potentiella matchningar i närheten. Ju närmare de är, desto enklare att träffas!';

  @override
  String get enableLocationBtn => 'Aktivera plats';

  @override
  String get enableNotifications => 'Aktivera notiser';

  @override
  String get neverMissAMatch => 'Missa aldrig en match';

  @override
  String get notificationDescription =>
      'Bli notifierad när någon gillar dig, när du får en ny match eller ett meddelande. Håll dig uppdaterad!';

  @override
  String get enableNotificationsBtn => 'Aktivera notiser';

  @override
  String get settingUpProfile => 'Skapar din profil...';

  @override
  String get youreAllSet => 'Allt är klart!';

  @override
  String get profileReadySubtitle =>
      'Din profil är redo. Dags att börja\nträffa fantastiska människor.';

  @override
  String get startExploring => 'Börja utforska';

  @override
  String get discoverTitle => 'Utforska';

  @override
  String get findingPeopleNearYou => 'Letar efter personer nära dig...';

  @override
  String get somethingWentWrong => 'Något gick fel';

  @override
  String get checkConnectionRetry =>
      'Kontrollera din anslutning och försök igen';

  @override
  String get seenEveryone => 'Du har sett alla!';

  @override
  String get checkBackLater => 'Kom tillbaka senare för nya personer';

  @override
  String get interestsHeader => 'INTRESSEN';

  @override
  String get likeButton => 'Gilla';

  @override
  String get skipAction => 'Hoppa över';

  @override
  String get addComment => 'Lägg till en kommentar?';

  @override
  String get standOutComment =>
      'Stick ut genom att berätta varför du gillade detta';

  @override
  String get saySomethingNice => 'Skriv något trevligt...';

  @override
  String get likeOnly => 'Bara gilla';

  @override
  String get sendWithComment => 'Skicka med kommentar';

  @override
  String get matchesTitle => 'Matchningar';

  @override
  String get newMatches => 'Nya matchningar';

  @override
  String get messagesTab => 'Meddelanden';

  @override
  String get noMatchesYet => 'Inga matchningar ännu';

  @override
  String get keepSwiping => 'Fortsätt swipea för att hitta din perfekta match!';

  @override
  String get unknownUser => 'Okänd';

  @override
  String get readyToChat => 'Redo att chatta';

  @override
  String get noConversationsYet => 'Inga konversationer ännu';

  @override
  String get startChattingMatches => 'Börja chatta med dina matchningar!';

  @override
  String get sayHello => 'Säg hej!';

  @override
  String get replyAction => 'Svara';

  @override
  String get refreshMessages => 'Uppdatera meddelanden';

  @override
  String get videoCallComingSoon => 'Videosamtal kommer snart!';

  @override
  String get safetyNotice =>
      'Din säkerhet är viktig. Denna konversation övervakas för olämpligt innehåll.';

  @override
  String get startConversation => 'Starta din konversation!';

  @override
  String sayHelloTo(String name) {
    return 'Säg hej till $name';
  }

  @override
  String get typeMessage => 'Skriv ett meddelande...';

  @override
  String get failedToSendMessage =>
      'Kunde inte skicka meddelande. Försök igen.';

  @override
  String get reportUser => 'Rapportera användare';

  @override
  String get blockUser => 'Blockera användare';

  @override
  String get safetyTips => 'Säkerhetstips';

  @override
  String get reportDialogContent =>
      'Rapportera denna användare för olämpligt beteende. Vårt team granskar din rapport.';

  @override
  String get userReported =>
      'Användare rapporterad. Tack för att du håller vår community säker.';

  @override
  String get blockDialogContent =>
      'Detta förhindrar att de skickar meddelanden till dig och döljer deras profil.';

  @override
  String get userBlocked => 'Användare blockerad.';

  @override
  String get staySafe => 'Var försiktig';

  @override
  String get safetyTip1 =>
      '• Dela aldrig personlig information som telefonnummer, adress eller ekonomiska uppgifter';

  @override
  String get safetyTip2 => '• Träffas på offentliga platser vid första dejten';

  @override
  String get safetyTip3 =>
      '• Lita på din magkänsla – om något känns fel, rapportera det';

  @override
  String get safetyTip4 =>
      '• Vår AI övervakar konversationer för olämpligt innehåll';

  @override
  String get safetyTip5 =>
      '• Rapportera misstänkt eller stötande beteende omedelbart';

  @override
  String get timeNow => 'nu';

  @override
  String get statusConnected => 'Ansluten';

  @override
  String get statusConnecting => 'Ansluter...';

  @override
  String get statusReconnecting => 'Återansluter...';

  @override
  String get aboutMeLabel => 'OM MIG';

  @override
  String get interestsLabel => 'INTRESSEN';

  @override
  String get lifestyleLabel => 'LIVSSTIL';

  @override
  String get languagesLabel => 'SPRÅK';

  @override
  String percentCompatible(int percent) {
    return '$percent% Kompatibel';
  }

  @override
  String get basedOnPreferences => 'baserat på dina preferenser';

  @override
  String get drinkingLabel => 'Alkohol';

  @override
  String get smokingLabel => 'Rökning';

  @override
  String get workoutLabel => 'Träning';

  @override
  String kmAway(int km) {
    return '$km km bort';
  }

  @override
  String get sendAMessage => 'Skicka ett meddelande';

  @override
  String get reportProfile => 'Rapportera profil';

  @override
  String get reportSubmitted => 'Rapport skickad. Tack.';

  @override
  String userHasBeenBlocked(String name) {
    return '$name har blockerats.';
  }

  @override
  String get getMore => 'Få mer';

  @override
  String get safety => 'Säkerhet';

  @override
  String get myDejTing => 'Min DejTing';

  @override
  String get dejTingPlus => 'DejTing Plus';

  @override
  String get dejTingPlusSubtitle =>
      'Obegränsade Sparks, veckovis Spotlight,\noch se vem som gillar dig först.';

  @override
  String get spotlight => 'Spotlight';

  @override
  String get spotlightSubtitle =>
      'Hamna först — bli sedd av 10× fler i 30 min.';

  @override
  String get sparks => 'Sparks';

  @override
  String get sparkSubtitle =>
      'Skicka en Spark med ett meddelande — 3× troligare match.';

  @override
  String get profileStrength => 'Profilstyrka';

  @override
  String get selfieVerification => 'Selfieverifiering';

  @override
  String get youAreVerified => 'Du är verifierad ✓';

  @override
  String get verifyYourIdentity => 'Verifiera din identitet';

  @override
  String get messageFilter => 'Meddelandefilter';

  @override
  String get messageFilterSubtitle =>
      'Döljer meddelanden med respektlöst språk.';

  @override
  String get blockList => 'Blocklista';

  @override
  String contactsBlocked(int count) {
    return '$count kontakt(er) blockerade.';
  }

  @override
  String get safetyResources => 'Säkerhetsresurser';

  @override
  String get crisisHotlines => 'Krislinjer';

  @override
  String get freshStart => 'Nystart';

  @override
  String get freshStartSubtitle =>
      'Uppdatera dina texter och foton\nför att starta nya konversationer.';

  @override
  String get editProfile => 'Redigera profil';

  @override
  String get datingTips => 'Dejtingtips';

  @override
  String get datingTipsSubtitle => 'Expertråd för bättre dejter';

  @override
  String get helpCentre => 'Hjälpcenter';

  @override
  String get helpCentreSubtitle => 'Vanliga frågor, säkerhet och kontosupport';

  @override
  String get settingsTitle => 'Inställningar';

  @override
  String get settingsSubtitle => 'Upptäckt, notiser, integritet';

  @override
  String get noBlockedContacts => 'Inga blockerade kontakter';

  @override
  String featureComingSoon(String feature) {
    return '$feature — kommer snart!';
  }

  @override
  String get sectionAccount => 'Konto';

  @override
  String get editProfileSubtitle => 'Uppdatera dina foton och bio';

  @override
  String get verifyAccount => 'Verifiera ditt konto';

  @override
  String get verifyAccountSubtitle => 'Få en blå verifieringsmarkering';

  @override
  String get privacySecurity => 'Integritet & Säkerhet';

  @override
  String get privacySecuritySubtitle => 'Hantera dina integritetsinställningar';

  @override
  String get sectionDiscovery => 'Upptäcktsinställningar';

  @override
  String get locationLabel => 'Plats';

  @override
  String get locationSubtitle => 'Uppdatera din plats';

  @override
  String maxDistance(int km) {
    return 'Maximalt avstånd: $km km';
  }

  @override
  String ageRangeLabel(int min, int max) {
    return 'Åldersintervall: $min - $max';
  }

  @override
  String get showMeOnDejTing => 'Visa mig på DejTing';

  @override
  String get pauseAccountSubtitle => 'Stäng av för att pausa ditt konto';

  @override
  String get sectionNotifications => 'Notiser';

  @override
  String get pushNotifications => 'Pushnotiser';

  @override
  String get pushNotificationsSubtitle => 'Nya matchningar och meddelanden';

  @override
  String get sectionProfileDisplay => 'Profilvisning';

  @override
  String get showAge => 'Visa ålder';

  @override
  String get showAgeSubtitle => 'Visa din ålder på din profil';

  @override
  String get showDistance => 'Visa avstånd';

  @override
  String get showDistanceSubtitle => 'Visa avstånd på din profil';

  @override
  String get sectionSupportAbout => 'Support & Om';

  @override
  String get helpSupport => 'Hjälp & Support';

  @override
  String get aboutLabel => 'Om';

  @override
  String get rateUs => 'Betygsätt oss';

  @override
  String get aboutAppTitle => 'Om DatingApp';

  @override
  String get versionNumber => 'Version: 1.0.0';

  @override
  String get aboutAppDescription =>
      'Hitta din perfekta match med vår AI-drivna dejtingapp.';

  @override
  String get madeByTeam => 'Gjord med ❤️ av DatingApp-teamet';

  @override
  String get verifyIdentityTitle => 'Verifiera din identitet';

  @override
  String get takeSelfieToVerify => 'Ta en selfie för att verifiera';

  @override
  String get selfieVerifyDescription =>
      'Vi jämför din selfie med ditt profilfoto för att bekräfta att det verkligen är du. Detta håller alla säkra.';

  @override
  String get selfieTip1 => 'Bra belysning, ansiktet tydligt synligt';

  @override
  String get selfieTip2 => 'Titta rakt in i kameran';

  @override
  String get selfieTip3 => 'Inga solglasögon, masker eller tunga filter';

  @override
  String attemptsRemainingToday(int count) {
    return '$count försök kvar idag';
  }

  @override
  String get takeSelfie => 'Ta selfie';

  @override
  String get lookingGood => 'Ser bra ut?';

  @override
  String get selfiePreviewDescription =>
      'Se till att ditt ansikte syns tydligt och matchar ditt profilfoto.';

  @override
  String get verifyingIdentity => 'Verifierar din identitet...';

  @override
  String get submitForVerification => 'Skicka in för verifiering';

  @override
  String get retakePhoto => 'Ta om foto';

  @override
  String get verified => 'Verifierad!';

  @override
  String get underReview => 'Under granskning';

  @override
  String get verificationFailedResult => 'Verifiering misslyckades';

  @override
  String get alreadyVerified => 'Du är redan verifierad!';

  @override
  String get alreadyVerifiedDescription =>
      'Din identitet har bekräftats. Andra användare kan se din blå verifieringsmarkering.';

  @override
  String get verifiedProfile => 'Verifierad profil';

  @override
  String get getVerified => 'Bli verifierad';

  @override
  String get profileComplete => 'Profilen klar! 🎉';

  @override
  String get profileAlmostThere =>
      'Nästan klar — lägg till några fler detaljer';

  @override
  String get profileLookingGood => 'Ser bra ut — fortsätt!';

  @override
  String get addMoreInfoForMatches =>
      'Lägg till mer info för att få matchningar';

  @override
  String get completeLabel => 'klar';

  @override
  String get addPhoto => 'Lägg till foto';

  @override
  String get failedToLoad => 'Kunde inte ladda';

  @override
  String get errorGeneric => 'Något gick fel. Försök igen.';

  @override
  String get errorNetworkUnavailable =>
      'Nätverket är inte tillgängligt. Kontrollera din anslutning.';

  @override
  String get errorSessionExpired => 'Din session har gått ut. Logga in igen.';

  @override
  String get errorFieldRequired => 'Detta fält är obligatoriskt';

  @override
  String errorLoadingMessages(String error) {
    return 'Kunde inte ladda meddelanden: $error';
  }

  @override
  String errorSendingMessage(String error) {
    return 'Fel vid sändning av meddelande: $error';
  }

  @override
  String get profileTab => 'Profil';

  @override
  String get settingsTab => 'Inställningar';

  @override
  String get noNewPeople => 'Kom tillbaka senare för nya personer';

  @override
  String get connectionError => 'Kontrollera din anslutning och försök igen';

  @override
  String get connected => 'Ansluten';

  @override
  String get connecting => 'Ansluter...';

  @override
  String get aboutApp => 'Om DatingApp';

  @override
  String get accountSection => 'Konto';

  @override
  String get privacySettings => 'Hantera dina integritetsinställningar';

  @override
  String get privacySettingsTitle => 'Sekretessinställningar';

  @override
  String get privacySettingsComingSoon => 'Sekretessinställningar kommer snart';

  @override
  String get onboardingPhoneHint => 'Ange ditt telefonnummer';

  @override
  String get onboardingVerifyCode => 'Verifiera kod';

  @override
  String get onboardingVerifying => 'Verifierar...';

  @override
  String onboardingCodeResent(int remaining) {
    return 'Koden skickad igen ($remaining kvar)';
  }

  @override
  String get onboardingSelectCountry => 'Välj land';

  @override
  String get onboardingFirstNameTitle => 'Vad heter du i förnamn?';

  @override
  String get onboardingBirthdayTitle => 'När fyller du år?';

  @override
  String get onboardingGenderTitle => 'Vad är ditt kön?';

  @override
  String get onboardingOrientationTitle => 'Vad är din läggning?';

  @override
  String get onboardingRelationshipGoalsTitle => 'Vad söker du?';

  @override
  String get onboardingMatchPrefsTitle => 'Matchpreferenser';

  @override
  String get onboardingPhotosTitle => 'Lägg till foton';

  @override
  String get onboardingLifestyleTitle => 'Livsstil';

  @override
  String get onboardingInterestsTitle => 'Intressen';

  @override
  String get onboardingAboutMeTitle => 'Om mig';

  @override
  String get onboardingLocationTitle => 'Aktivera plats';

  @override
  String get onboardingLocationSubtitle =>
      'Vi använder din plats för att visa potentiella matchningar nära dig';

  @override
  String get enableLocationButton => 'Aktivera plats';

  @override
  String get maybeLaterButton => 'Kanske senare';

  @override
  String get onboardingNotificationsTitle => 'Aktivera notiser';

  @override
  String get onboardingNotificationsSubtitle =>
      'Bli notifierad när någon gillar dig eller skickar ett meddelande';

  @override
  String get enableNotificationsButton => 'Aktivera notiser';

  @override
  String get onboardingCompleteTitle => 'Allt är klart!';

  @override
  String get onboardingCompleteSubtitle =>
      'Din profil är redo. Börja upptäcka fantastiska människor!';

  @override
  String get startDiscoveringButton => 'Börja utforska';

  @override
  String photoAdded(int index) {
    return 'Foto $index tillagt (platshållare)';
  }

  @override
  String addUpToInterests(int max) {
    return 'Lägg till upp till $max intressen att visa på din profil.';
  }

  @override
  String get verificationSubtitle => 'Få en blå bock';

  @override
  String get notificationsSubtitle => 'Nya matchningar och meddelanden';

  @override
  String get getMoreSparks => 'Skaffa fler Sparks';

  @override
  String get matchFound => 'Det är en match!';

  @override
  String get continueBtn => 'Fortsätt';

  @override
  String get voicePromptTitle => 'Röstmeddelande';

  @override
  String get voicePromptInstruction =>
      'Spela in en kort röstintro så dina matchningar kan höra din stämning';

  @override
  String get voicePromptRecording => 'Spelar in… tryck stopp när du är klar';

  @override
  String get voicePromptReview =>
      'Lyssna på din inspelning och välj att spara eller spela in igen';

  @override
  String get readyToMatch => 'Jag är redo att matcha';

  @override
  String get signInButton => 'Logga in';

  @override
  String get welcomeBack => 'Välkommen tillbaka';

  @override
  String get signInWithPhoneDescription =>
      'Logga in med telefonnumret du använde när du registrerade dig.';

  @override
  String get accountNotFound =>
      'Inget konto hittades med detta nummer. Gå tillbaka och tryck \"Jag är redo att matcha\" för att skapa ett.';

  @override
  String get alwaysVisibleOnProfile => 'Alltid synligt på profilen';

  @override
  String get visibilityExplanation =>
      'Alla som ser din profil kan se detta innehåll.';

  @override
  String get ageRangeTitle => 'Hur gammal är din ideala match?';

  @override
  String get yearsOld => 'år';

  @override
  String get editableInSettings => 'Kan ändras i Inställningar';

  @override
  String get notVisibleOnProfile => 'Inte synligt på profilen';

  @override
  String get orientationStraightDesc => 'Attraherad av det motsatta könet';

  @override
  String get orientationGayDesc => 'Attraherad av samma kön';

  @override
  String get orientationLesbianDesc => 'Kvinnor attraherade av kvinnor';

  @override
  String get orientationBisexualDesc => 'Attraherad av mer än ett kön';

  @override
  String get orientationAsexualDesc => 'Liten eller ingen sexuell attraktion';

  @override
  String get orientationDemisexualDesc =>
      'Attraktion efter känslomässig koppling';

  @override
  String get orientationPansexualDesc => 'Attraktion oavsett kön';

  @override
  String get orientationQueerDesc => 'Inte heterosexuell eller cis';

  @override
  String get orientationQuestioningDesc => 'Utforskar eller osäker';

  @override
  String get lifestyleSmokingTitle => 'Hur ofta röker du?';

  @override
  String get lifestyleExerciseTitle => 'Tränar du?';

  @override
  String get lifestylePetsTitle => 'Har du husdjur?';

  @override
  String get aboutMeCommunicationStyle => 'Kommunikationsstil';

  @override
  String get aboutMeLoveLanguage => 'Kärleksspråk';

  @override
  String get aboutMeEducationLevel => 'Utbildningsnivå';

  @override
  String get interestCategoryOutdoors => 'Utomhus & äventyr';

  @override
  String get interestCategoryValues => 'Värderingar & engagemang';

  @override
  String get interestCategoryStayingIn => 'Hemma';

  @override
  String get interestCategoryTvMovies => 'TV & film';

  @override
  String get interestCategoryMusic => 'Musik';

  @override
  String get interestCategoryFoodDrink => 'Mat & dryck';

  @override
  String get interestCategoryGoingOut => 'Uteliv';

  @override
  String interestsSelectedCount(int count, int max) {
    return '$count / $max valda';
  }

  @override
  String get nameNotAllowed => 'Det namnet är inte tillåtet. Välj ett annat.';

  @override
  String get messageWarningTitle => 'Är du säker?';

  @override
  String get messageWarningBody =>
      'Det här meddelandet kan vara sårande. Vill du redigera det?';

  @override
  String get messageWarningEdit => 'Redigera meddelande';

  @override
  String get messageWarningSendAnyway => 'Skicka ändå';

  @override
  String get consentTitle => 'Välj ett konto';

  @override
  String consentSubtitle(String provider) {
    return 'Logga in med $provider';
  }

  @override
  String get consentAnotherAccount => 'Använd ett annat konto';

  @override
  String get consentLegalText => 'Innan du använder appen kan du läsa igenom ';

  @override
  String get consentPrivacyPolicy => 'integritetspolicyn';

  @override
  String get consentAnd => ' och ';

  @override
  String get consentTermsOfUse => 'användarvillkoren';

  @override
  String get consentForApp => ' för DejTing.';

  @override
  String get consentHelp => 'Hjälp';

  @override
  String get consentPrivacy => 'Integritet';

  @override
  String get consentTerms => 'Villkor';

  @override
  String get consentProviderPhone => 'Telefon';

  @override
  String get helpScreenTitle => 'Hjälp och support';

  @override
  String get locationSettings => 'Platsinställningar';

  @override
  String hearVoice(String name) {
    return 'Hör ${name}s röst';
  }

  @override
  String blockedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kontakter blockerade.',
      one: '1 kontakt blockerad.',
    );
    return '$_temp0';
  }

  @override
  String get voicePromptSubtitle => 'Spela in en röstintro till din profil';

  @override
  String get voicePromptSaved => 'Röstprompt sparad!';

  @override
  String get yourSparks => 'Dina Gnistor';

  @override
  String get howItWorks => 'Så här fungerar det';

  @override
  String get spotlightActivated =>
      '🔦 Spotlight aktiverat! 30 min med ökad synlighet.';

  @override
  String failedToLoadBlockList(String error) {
    return 'Det gick inte att ladda blocklistan: $error';
  }

  @override
  String get couldNotOpenStore =>
      'Det gick inte att öppna butikssidan. Försök igen senare.';
}
