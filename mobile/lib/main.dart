import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/ai_coach_screen.dart';
import 'screens/health_library_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const ClarityMobileApp());
}

class ClarityMobileApp extends StatelessWidget {
  const ClarityMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return MaterialApp(
            title: 'Clarity',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appState.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

class ClarityAppShell extends StatefulWidget {
  const ClarityAppShell({super.key});

  @override
  State<ClarityAppShell> createState() => _ClarityAppShellState();
}

class _ClarityAppShellState extends State<ClarityAppShell> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToIndex(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (appState.isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isDark ? AppColors.sageLight : AppColors.sageDark,
            ),
          ),
        ),
      );
    }

    // Horizontal swipe stack following user's finger
    // Home ↔ Progress ↔ Coach ↔ Learn
    // Profile & Settings are accessed from top-level navigation, not trapped in the swipe stack.
    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const ClampingScrollPhysics(),
          children: [
            HomeScreen(
              onNavigateToPatterns: () => _navigateToIndex(1),
              onNavigateToCoach: () => _navigateToIndex(2),
              onNavigateToProfile: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              onNavigateToSettings: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            const AnalyticsScreen(),
            const AICoachScreen(),
            const HealthLibraryScreen(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                width: 1.0,
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _navigateToIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            selectedItemColor: isDark ? AppColors.sageLight : AppColors.sageDark,
            unselectedItemColor: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.show_chart_outlined),
                activeIcon: Icon(Icons.show_chart),
                label: 'Progress',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                activeIcon: Icon(Icons.chat_bubble),
                label: 'Coach',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_outlined),
                activeIcon: Icon(Icons.menu_book),
                label: 'Learn',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

