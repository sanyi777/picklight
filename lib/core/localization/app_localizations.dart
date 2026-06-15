import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // ==================== Tab names ====================
  String get capture => _getString('捕捉', 'Capture');
  String get schedule => _getString('日程', 'Schedule');
  String get morning => _getString('晨间', 'Morning');
  String get focus => _getString('专注', 'Focus');
  String get evening => _getString('复盘', 'Review');
  String get progress => _getString('项目', 'Projects');
  String get stats => _getString('统计', 'Stats');
  String get settings => _getString('设置', 'Settings');

  // ==================== Common buttons ====================
  String get save => _getString('保存', 'Save');
  String get cancel => _getString('取消', 'Cancel');
  String get delete => _getString('删除', 'Delete');
  String get confirm => _getString('确认', 'Confirm');
  String get start => _getString('开始', 'Start');
  String get pause => _getString('暂停', 'Pause');
  String get skip => _getString('跳过', 'Skip');
  String get search => _getString('搜索', 'Search');

  // ==================== App name ====================
  String get appName => '拾光';

  // ==================== Internal ====================
  String _getString(String zh, String en) {
    if (locale.languageCode == 'en') return en;
    return zh;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'zh' || locale.languageCode == 'en';

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant _AppLocalizationsDelegate old) => false;
}
