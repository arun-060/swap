import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_2/providers/language_provider.dart';
import 'package:flutter_application_2/providers/theme_provider.dart';
import 'package:flutter_application_2/providers/search_history_provider.dart';
import 'package:flutter_application_2/providers/cart_provider.dart';
import 'package:flutter_application_2/screens/login_screen.dart';
import 'package:flutter_application_2/screens/signup_screen.dart';
import 'package:flutter_application_2/screens/main_screen.dart';
import 'package:flutter_application_2/screens/scanner_screen.dart';
import 'package:flutter_application_2/screens/product_detail_screen.dart';
import 'package:flutter_application_2/screens/category_products_screen.dart';
import 'package:flutter_application_2/screens/cart_screen.dart';
import 'package:flutter_application_2/screens/rewards_screen.dart';
import 'package:flutter_application_2/screens/settings_screen.dart';
import 'package:flutter_application_2/screens/help_center_screen.dart';
import 'package:flutter_application_2/screens/profile_screen.dart';
import 'package:flutter_application_2/screens/notifications_screen.dart'; 
import 'package:flutter_application_2/screens/location_screen.dart';
import 'package:flutter_application_2/screens/grocery_products_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SearchHistoryProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: Consumer2<LanguageProvider, ThemeProvider>(
        builder: (context, languageProvider, themeProvider, _) {
          return MaterialApp(
            title: languageProvider.getTranslatedText('app_name'),
            theme: themeProvider.theme,
            locale: languageProvider.currentLocale,
            initialRoute: '/',
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/':
                  return MaterialPageRoute(
                    builder: (_) => const SplashScreen(),
                  );
                case '/login':
                  return MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  );
                case '/signup':
                  return MaterialPageRoute(
                    builder: (_) => const SignupScreen(),
                  );
                case '/main':
                  return MaterialPageRoute(
                    builder: (_) => const MainScreen(),
                  );
                case '/scanner':
                  return MaterialPageRoute(
                    builder: (_) => const ScannerScreen(),
                  );
                case '/product':
                  final productId = (settings.arguments as Map<String, dynamic>)['id'];
                  return MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(productId: productId),
                  );
                case '/category':
                  return MaterialPageRoute(
                    builder: (_) => const CategoryProductsScreen(),
                  );
                case '/cart':
                  return MaterialPageRoute(
                    builder: (_) => const CartScreen(),
                  );
                case '/rewards':
                  return MaterialPageRoute(
                    builder: (_) => const RewardsScreen(),
                  );
                case '/groceries':
                  return MaterialPageRoute(
                    builder: (_) => const GroceryProductsScreen(),
                  );
                case '/settings':
                  return MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  );
                case '/help':
                  return MaterialPageRoute(
                    builder: (_) => const HelpCenterScreen(),
                  );
                case '/profile':
                  return MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  );
                case '/notifications':
                  return MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  );
                case '/location':
                  return MaterialPageRoute(
                    builder: (_) => const LocationScreen(),
                  );
                default:
                  return MaterialPageRoute(
                    builder: (_) => const SplashScreen(),
                  );
              }
            },
          );
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2)); // Show splash for 2 seconds
    
    if (!mounted) return;

    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    if (session != null) {
      // User is already logged in
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      // No active session, go to login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/swap.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

