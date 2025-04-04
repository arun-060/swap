import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _currentLocale = const Locale('en');
  final Map<String, Map<String, String>> _translations = {
    'en': {
      'app_name': 'SWAP',
      'login': 'Login',
      'sign_up': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'forgot_password': 'Forgot Password?',
      'no_account': 'Don\'t have an account?',
      'have_account': 'Already have an account?',
      'home': 'Home',
      'categories': 'Categories',
      'cart': 'Cart',
      'profile': 'Profile',
      'settings': 'Settings',
      'notifications': 'Notifications',
      'location': 'Location',
      'search': 'Search',
      'popular_products': 'Popular Products',
      'all_categories': 'All Categories',
      'rewards': 'Rewards',
      'help_center': 'Help Center',
      'about': 'About',
      'logout': 'Logout',
      'language': 'Language',
      'theme': 'Theme',
      'dark_mode': 'Dark Mode',
      'light_mode': 'Light Mode',
      'system_default': 'System Default',
      'scan_barcode': 'Scan Barcode',
      'compare_prices': 'Compare Prices',
      'add_to_cart': 'Add to Cart',
      'remove_from_cart': 'Remove from Cart',
      'checkout': 'Checkout',
      'total': 'Total',
      'empty_cart': 'Your cart is empty',
      'no_products': 'No products found',
      'error_occurred': 'An error occurred',
      'try_again': 'Try Again',
      'success': 'Success',
      'error': 'Error',
      'loading': 'Loading...',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'update': 'Update',
      'confirm': 'Confirm',
    },
    'hi': {
      'app_name': 'स्वैप',
      'login': 'लॉग इन',
      'sign_up': 'साइन अप',
      'email': 'ईमेल',
      'password': 'पासवर्ड',
      'confirm_password': 'पासवर्ड की पुष्टि करें',
      'forgot_password': 'पासवर्ड भूल गए?',
      'no_account': 'खाता नहीं है?',
      'have_account': 'पहले से खाता है?',
      'home': 'होम',
      'categories': 'श्रेणियाँ',
      'cart': 'कार्ट',
      'profile': 'प्रोफ़ाइल',
      'settings': 'सेटिंग्स',
      'notifications': 'सूचनाएं',
      'location': 'स्थान',
      'search': 'खोजें',
      'popular_products': 'लोकप्रिय उत्पाद',
      'all_categories': 'सभी श्रेणियाँ',
      'rewards': 'रिवॉर्ड्स',
      'help_center': 'सहायता केंद्र',
      'about': 'के बारे में',
      'logout': 'लॉग आउट',
      'language': 'भाषा',
      'theme': 'थीम',
      'dark_mode': 'डार्क मोड',
      'light_mode': 'लाइट मोड',
      'system_default': 'सिस्टम डिफ़ॉल्ट',
      'scan_barcode': 'बारकोड स्कैन करें',
      'compare_prices': 'कीमतों की तुलना करें',
      'add_to_cart': 'कार्ट में जोड़ें',
      'remove_from_cart': 'कार्ट से हटाएं',
      'checkout': 'चेकआउट',
      'total': 'कुल',
      'empty_cart': 'आपका कार्ट खाली है',
      'no_products': 'कोई उत्पाद नहीं मिला',
      'error_occurred': 'एक त्रुटि हुई',
      'try_again': 'पुनः प्रयास करें',
      'success': 'सफलता',
      'error': 'त्रुटि',
      'loading': 'लोड हो रहा है...',
      'save': 'सहेजें',
      'cancel': 'रद्द करें',
      'delete': 'हटाएं',
      'edit': 'संपादित करें',
      'update': 'अपडेट करें',
      'confirm': 'पुष्टि करें',
    },
    'es': {
      'app_name': 'SWAP',
      'login': 'Iniciar Sesión',
      'sign_up': 'Registrarse',
      'email': 'Correo Electrónico',
      'password': 'Contraseña',
      'confirm_password': 'Confirmar Contraseña',
      'forgot_password': '¿Olvidaste tu contraseña?',
      'no_account': '¿No tienes una cuenta?',
      'have_account': '¿Ya tienes una cuenta?',
      'home': 'Inicio',
      'categories': 'Categorías',
      'cart': 'Carrito',
      'profile': 'Perfil',
      'settings': 'Configuración',
      'notifications': 'Notificaciones',
      'location': 'Ubicación',
      'search': 'Buscar',
      'popular_products': 'Productos Populares',
      'all_categories': 'Todas las Categorías',
      'rewards': 'Recompensas',
      'help_center': 'Centro de Ayuda',
      'about': 'Acerca de',
      'logout': 'Cerrar Sesión',
      'language': 'Idioma',
      'theme': 'Tema',
      'dark_mode': 'Modo Oscuro',
      'light_mode': 'Modo Claro',
      'system_default': 'Predeterminado del Sistema',
      'scan_barcode': 'Escanear Código',
      'compare_prices': 'Comparar Precios',
      'add_to_cart': 'Agregar al Carrito',
      'remove_from_cart': 'Quitar del Carrito',
      'checkout': 'Pagar',
      'total': 'Total',
      'empty_cart': 'Tu carrito está vacío',
      'no_products': 'No se encontraron productos',
      'error_occurred': 'Ocurrió un error',
      'try_again': 'Intentar de nuevo',
      'success': 'Éxito',
      'error': 'Error',
      'loading': 'Cargando...',
      'save': 'Guardar',
      'cancel': 'Cancelar',
      'delete': 'Eliminar',
      'edit': 'Editar',
      'update': 'Actualizar',
      'confirm': 'Confirmar',
    },
  };

  Locale get currentLocale => _currentLocale;

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode') ?? 'en';
    _currentLocale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    _currentLocale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', languageCode);
    notifyListeners();
  }

  String getTranslatedText(String key) {
    return _translations[_currentLocale.languageCode]?[key] ?? key;
  }
} 