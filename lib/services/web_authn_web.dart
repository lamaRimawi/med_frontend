import 'dart:js_util' as js_util;
import 'package:js/js.dart';
import 'dart:html' as html;

@JS('webauthnJSON')
class WebAuthnJSON {
  external static dynamic create(dynamic options);
  external static dynamic get(dynamic options);
}

class WebAuthnService {
  static bool get isSupported {
    return html.window.navigator.credentials != null &&
           html.window.isSecureContext == true;
  }

  static Future<Map<String, dynamic>?> createCredential(Map<String, dynamic> options) async {
    try {
      // Create a JS object from the options map
      final jsOptions = js_util.jsify({'publicKey': options});
      
      // Call create from webauthn-json library (which returns a promise)
      final promise = WebAuthnJSON.create(jsOptions);
      
      // Await the promise
      final result = await js_util.promiseToFuture(promise);
      
      // Convert back to Dart Map
      return (js_util.dartify(result) as Map).cast<String, dynamic>();
    } catch (e) {
      print('WebAuthn Registration Error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getAssertion(Map<String, dynamic> options) async {
    try {
      // Create a JS object from the options map
      final jsOptions = js_util.jsify({'publicKey': options});
      
      // Call get from webauthn-json library
      final promise = WebAuthnJSON.get(jsOptions);
      
      // Await
      final result = await js_util.promiseToFuture(promise);
      
      // Convert back to Dart Map
      return (js_util.dartify(result) as Map).cast<String, dynamic>();
    } catch (e) {
      print('WebAuthn Login Error: $e');
      return null;
    }
  }
}
