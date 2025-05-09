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
      'full_name': 'Full Name',
      'phone': 'Phone Number',
      'address': 'Address',
      'name_required': 'Please enter your name',
      'search_hint': 'Search for products...',
      'search_products': 'Search products',
      'all': 'All',
      'no_products_found': 'No products found',
      'scan': 'Scan',
      'share': 'Share',
      'manage_profile': 'Manage your profile',
      'notification_settings': 'Manage notifications',
      'location_settings': 'Manage location settings',
      'change_language': 'Change app language',
      'change_theme': 'Change app theme',
      'get_help': 'Get help and support',
      'about_app': 'About this app',
      'app_description': 'SWAP is your one-stop shop for comparing prices across different stores and finding the best deals.',
      'logout_confirm': 'Confirm Logout',
      'logout_message': 'Are you sure you want to log out?',
      'push_notifications': 'Push Notifications',
      'push_notifications_desc': 'Receive notifications about deals and offers',
      'email_notifications': 'Email Notifications',
      'email_notifications_desc': 'Receive email updates about your orders',
      'location_services': 'Location Services',
      'location_services_desc': 'Enable location services to find stores near you',
      'location_info': 'Location Information',
      'location_info_desc': 'We use your location to show you the best deals from stores near you.',
      'clear_all': 'Clear All',
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
      'full_name': 'पूरा नाम',
      'phone': 'फ़ोन नंबर',
      'address': 'पता',
      'name_required': 'कृपया अपना नाम दर्ज करें',
      'search_hint': 'उत्पाद खोजें...',
      'search_products': 'उत्पाद खोजें',
      'all': 'सभी',
      'no_products_found': 'कोई उत्पाद नहीं मिला',
      'scan': 'स्कैन',
      'share': 'शेयर',
      'manage_profile': 'अपनी प्रोफ़ाइल प्रबंधित करें',
      'notification_settings': 'सूचनाएं प्रबंधित करें',
      'location_settings': 'स्थान सेटिंग्स प्रबंधित करें',
      'change_language': 'ऐप की भाषा बदलें',
      'change_theme': 'ऐप थीम बदलें',
      'get_help': 'सहायता और समर्थन प्राप्त करें',
      'about_app': 'इस ऐप के बारे में',
      'app_description': 'स्वैप विभिन्न स्टोर की कीमतों की तुलना करने और सर्वोत्तम डील खोजने के लिए आपकी वन-स्टॉप शॉप है।',
      'logout_confirm': 'लॉगआउट की पुष्टि करें',
      'logout_message': 'क्या आप लॉगआउट करना चाहते हैं?',
      'push_notifications': 'पुश सूचनाएं',
      'push_notifications_desc': 'डील और ऑफ़र के बारे में सूचनाएं प्राप्त करें',
      'email_notifications': 'ईमेल सूचनाएं',
      'email_notifications_desc': 'अपने ऑर्डर के बारे में ईमेल अपडेट प्राप्त करें',
      'location_services': 'स्थान सेवाएं',
      'location_services_desc': 'आपके पास के स्टोर खोजने के लिए स्थान सेवाएं सक्षम करें',
      'location_info': 'स्थान जानकारी',
      'location_info_desc': 'हम आपके पास के स्टोर से सर्वोत्तम डील दिखाने के लिए आपका स्थान उपयोग करते हैं।',
      'clear_all': 'सभी साफ़ करें',
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
      'full_name': 'Nombre Completo',
      'phone': 'Número de Teléfono',
      'address': 'Dirección',
      'name_required': 'Por favor ingrese su nombre',
      'search_hint': 'Buscar productos...',
      'search_products': 'Buscar productos',
      'all': 'Todos',
      'no_products_found': 'No se encontraron productos',
      'scan': 'Escanear',
      'share': 'Compartir',
      'manage_profile': 'Administrar tu perfil',
      'notification_settings': 'Administrar notificaciones',
      'location_settings': 'Administrar configuración de ubicación',
      'change_language': 'Cambiar idioma de la aplicación',
      'change_theme': 'Cambiar tema de la aplicación',
      'get_help': 'Obtener ayuda y soporte',
      'about_app': 'Acerca de esta aplicación',
      'app_description': 'SWAP es tu tienda única para comparar precios entre diferentes tiendas y encontrar las mejores ofertas.',
      'logout_confirm': 'Confirmar Cierre de Sesión',
      'logout_message': '¿Estás seguro de que quieres cerrar sesión?',
      'push_notifications': 'Notificaciones Push',
      'push_notifications_desc': 'Recibir notificaciones sobre ofertas y promociones',
      'email_notifications': 'Notificaciones por Correo',
      'email_notifications_desc': 'Recibir actualizaciones por correo sobre tus pedidos',
      'location_services': 'Servicios de Ubicación',
      'location_services_desc': 'Habilitar servicios de ubicación para encontrar tiendas cercanas',
      'location_info': 'Información de Ubicación',
      'location_info_desc': 'Usamos tu ubicación para mostrarte las mejores ofertas de tiendas cercanas.',
      'clear_all': 'Limpiar Todo',
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