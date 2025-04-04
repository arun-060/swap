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
            initialRoute: '/login',
            routes: {
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
              '/main': (context) => const MainScreen(),
              '/scanner': (context) => const ScannerScreen(),
              '/product': (context) => const ProductDetailScreen(),
              '/category': (context) => const CategoryProductsScreen(),
              '/cart': (context) => const CartScreen(),
              '/rewards': (context) => const RewardsScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/help': (context) => const HelpCenterScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/notifications': (context) => const NotificationsScreen(),
              '/location': (context) => const LocationScreen(),
            },
          );
        },
      ),
    );
  }
}

