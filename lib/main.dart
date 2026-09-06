import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/storage_service.dart';
import 'services/theme_service.dart';
import 'services/notification_service.dart';
import 'services/ad_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/input_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/settings_screen.dart';

// グローバルナビゲーターキー
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// グローバルナビゲーション状態（現在のタブインデックス）
final ValueNotifier<int> currentTabIndex = ValueNotifier<int>(1);

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();

    // グローバルエラーハンドラ
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');
    };

    // ステータスバーのスタイル設定
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    runApp(const FinanceClarityApp());
  }, (error, stack) {
    debugPrint('Uncaught error: $error');
    debugPrint('Stack trace: $stack');
  });
}

class FinanceClarityApp extends StatelessWidget {
  const FinanceClarityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService(),
      builder: (context, child) {
        return MaterialApp(
          title: '家計簿ポン',
          debugShowCheckedModeBanner: false,
          theme: ThemeService().themeData,
          navigatorKey: navigatorKey,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ja', 'JP'),
            Locale('en', 'US'),
          ],
          locale: const Locale('ja', 'JP'),
          home: const MainNavigationScreen(),
        );
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 1; // 入力画面から開始
  bool _isInitialized = false;
  String? _initError;

  final List<Widget> _screens = const [
    AnalysisScreen(),
    InputScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeServices();
    // currentTabIndexの変更をリスン
    currentTabIndex.addListener(_onTabIndexChanged);
  }

  @override
  void dispose() {
    currentTabIndex.removeListener(_onTabIndexChanged);
    super.dispose();
  }

  void _onTabIndexChanged() {
    if (mounted && _currentIndex != currentTabIndex.value) {
      setState(() {
        _currentIndex = currentTabIndex.value;
      });
    }
  }

  Future<void> _initializeServices() async {
    try {
      debugPrint('Starting service initialization...');

      // MobileAds初期化（最優先）
      await MobileAds.instance.initialize();
      debugPrint('MobileAds initialized successfully');

      // 必須サービスの初期化（順序が重要）
      // StorageServiceを先に初期化（ThemeServiceがカスタムテーマ読み込みに必要）
      await StorageService().init().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('StorageService initialization timed out');
        },
      );

      // ThemeServiceはStorageService初期化後に実行
      await ThemeService().init().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('ThemeService initialization timed out');
        },
      );

      // 通知サービスは失敗しても続行（シミュレーターでは動作しないため）
      try {
        await NotificationService().init().timeout(
          const Duration(seconds: 5),
        );
        debugPrint('NotificationService initialized successfully');
      } catch (e) {
        debugPrint('NotificationService initialization failed (expected in simulator): $e');
      }

      // AdService初期化（失敗してもアプリ続行）
      try {
        await AdService().init().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw TimeoutException('AdService initialization timed out');
          },
        );
        debugPrint('AdService initialized successfully');
      } catch (e) {
        debugPrint('AdService initialization failed (app will continue without ads): $e');
      }

      debugPrint('Core services initialized successfully');

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Service initialization error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _initError = 'サービスの初期化に失敗しました:\n\n$e\n\nアプリを再起動するか、再試行ボタンを押してください。';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                '家計簿ポン',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '初期化中...',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_initError != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 48),
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  '初期化エラー',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      _initError!,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isInitialized = false;
                        _initError = null;
                      });
                      _initializeServices();
                    },
                    child: const Text('再試行'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            currentTabIndex.value = index;
          },
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_graph_outlined),
              activeIcon: Icon(Icons.auto_graph),
              label: '分析',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              activeIcon: Icon(Icons.add_circle),
              label: '入力',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: '設定',
            ),
          ],
        ),
      ),
    );
  }
}
