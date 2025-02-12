import 'package:flutter/foundation.dart' show kIsWeb;

Future<String> fetchSystemLocale() async {
  if (kIsWeb) {
    // Use the web implementation
    return await findSystemLocale();
  } else {
    // Default for non-web
    return 'en_US';
  }
}

// This function would need to be implemented if you're using intl
Future<String> findSystemLocale() async {
  // This would usually call window.navigator.language in a web app
  return 'en_US'; // Return a default value or implement your logic here
}
