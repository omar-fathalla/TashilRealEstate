/// Emirates used to choose the rental-dispute authority on a legal notice.
enum UaeEmirate {
  dubai,
  abuDhabi,
  sharjah,
  ajman,
  ummAlQuwain,
  rasAlKhaimah,
  fujairah,

  /// UAE property whose emirate could not be read. The notice stays generic.
  unspecified,
}

UaeEmirate resolveUaeEmirate({
  String? cityCode,
  String district = '',
  String city = '',
}) {
  switch ((cityCode ?? '').trim().toLowerCase()) {
    case 'dubai':
      return UaeEmirate.dubai;
    case 'abu_dhabi':
      return UaeEmirate.abuDhabi;
    case 'sharjah':
      return UaeEmirate.sharjah;
    case 'ajman':
      return UaeEmirate.ajman;
    case 'umm_al_quwain':
      return UaeEmirate.ummAlQuwain;
    case 'ras_al_khaimah':
      return UaeEmirate.rasAlKhaimah;
    case 'fujairah':
      return UaeEmirate.fujairah;
  }

  final text = '$district $city'.toLowerCase();
  if (_has(text, ['أبو ظبي', 'ابو ظبي', 'أبوظبي', 'ابوظبي', 'abu dhabi'])) {
    return UaeEmirate.abuDhabi;
  }
  if (_has(text, ['الشارقة', 'شارقة', 'sharjah'])) {
    return UaeEmirate.sharjah;
  }
  if (_has(text, ['عجمان', 'ajman'])) {
    return UaeEmirate.ajman;
  }
  if (_has(text, ['أم القيوين', 'ام القيوين', 'umm al quwain', 'uaq'])) {
    return UaeEmirate.ummAlQuwain;
  }
  if (_has(text, ['رأس الخيمة', 'راس الخيمة', 'ras al khaimah'])) {
    return UaeEmirate.rasAlKhaimah;
  }
  if (_has(text, ['الفجيرة', 'فجيرة', 'fujairah'])) {
    return UaeEmirate.fujairah;
  }
  if (_has(text, ['دبي', 'dubai', 'مارينا', 'marina'])) {
    return UaeEmirate.dubai;
  }
  return UaeEmirate.unspecified;
}

bool _has(String text, List<String> needles) {
  for (final needle in needles) {
    if (text.contains(needle)) return true;
  }
  return false;
}

/// Localization key for the notice body. Unverified emirates share one generic key.
String legalNoticeBodyKey(UaeEmirate emirate) {
  switch (emirate) {
    case UaeEmirate.dubai:
      return 'legalNoticeBody_ae';
    case UaeEmirate.abuDhabi:
      return 'legalNoticeBody_ad';
    case UaeEmirate.sharjah:
      return 'legalNoticeBody_shj';
    case UaeEmirate.ajman:
    case UaeEmirate.ummAlQuwain:
    case UaeEmirate.rasAlKhaimah:
    case UaeEmirate.fujairah:
    case UaeEmirate.unspecified:
      return 'legalNoticeBody_ae_other';
  }
}

String rentalDisputeAuthorityKey(UaeEmirate emirate) {
  switch (emirate) {
    case UaeEmirate.dubai:
      return 'rentalDisputeAuthority_dubai';
    case UaeEmirate.abuDhabi:
      return 'rentalDisputeAuthority_ad';
    case UaeEmirate.sharjah:
      return 'rentalDisputeAuthority_shj';
    case UaeEmirate.ajman:
    case UaeEmirate.ummAlQuwain:
    case UaeEmirate.rasAlKhaimah:
    case UaeEmirate.fujairah:
    case UaeEmirate.unspecified:
      return 'rentalDisputeAuthority_other';
  }
}
