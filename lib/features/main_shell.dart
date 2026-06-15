import 'package:flutter/cupertino.dart';
import 'package:personal_assistant/core/localization/app_localizations.dart';
import 'morning/presentation/morning_screen.dart';
import 'capture/presentation/capture_screen.dart';
import 'focus/presentation/focus_screen.dart';
import 'evening/presentation/evening_screen.dart';
import 'schedule/presentation/schedule_screen.dart';
import 'progress/presentation/progress_screen.dart';
import 'settings/presentation/settings_screen.dart';
import 'stats/presentation/stats_screen.dart';
import 'search/presentation/search_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _tabs = <Widget>[
    CaptureScreen(),
    ScheduleScreen(),
    MorningScreen(),
    FocusScreen(),
    EveningScreen(),
    ProgressScreen(),
    SettingsScreen(),
    StatsScreen(),
  ];

  List<BottomNavigationBarItem> _buildTabItems(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: const Icon(CupertinoIcons.lightbulb),
        label: l10n.capture,
      ),
      BottomNavigationBarItem(
        icon: const Icon(CupertinoIcons.calendar),
        label: l10n.schedule,
      ),
      BottomNavigationBarItem(
        icon: const Icon(CupertinoIcons.sun_max),
        label: l10n.morning,
      ),
      BottomNavigationBarItem(
        icon: const Icon(CupertinoIcons.timer),
        label: l10n.focus,
      ),
      BottomNavigationBarItem(
        icon: const Icon(CupertinoIcons.moon),
        label: l10n.evening,
      ),
      BottomNavigationBarItem(
        icon: const Icon(CupertinoIcons.chart_bar_alt_fill),
        label: l10n.progress,
      ),
      BottomNavigationBarItem(
        icon: const Icon(CupertinoIcons.settings),
        label: l10n.settings,
      ),
      BottomNavigationBarItem(
        icon: const Icon(CupertinoIcons.chart_bar),
        label: l10n.stats,
      ),
    ];
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('拾光'),
        trailing: GestureDetector(
          onTap: () {
            final result = Navigator.of(context).push<int>(
              CupertinoPageRoute(builder: (_) => const SearchScreen()),
            );
            result.then((tabIndex) {
              if (tabIndex != null) {
                _navigateToTab(tabIndex);
              }
            });
          },
          child: const Icon(CupertinoIcons.search),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0.04, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOut,
                          ),
                        ),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_currentIndex),
                child: _tabs[_currentIndex],
              ),
            ),
          ),
          CupertinoTabBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            items: _buildTabItems(context),
          ),
        ],
      ),
    );
  }
}
