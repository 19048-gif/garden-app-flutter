import 'package:url_launcher/url_launcher.dart';

class LauncherService {
  LauncherService._();

  static Future<bool> makePhoneCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    if (cleanPhone.isEmpty) return false;
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }

  static Future<bool> openWhatsApp(String phone, String message) async {
    var cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.isEmpty) return false;
    if (!cleanPhone.startsWith('351') && cleanPhone.length == 9) {
      cleanPhone = '351$cleanPhone';
    }
    final encodedMsg = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMsg');
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  static Future<bool> openAddressInMaps(String address) async {
    if (address.trim().isEmpty) return false;
    final query = Uri.encodeComponent(address.trim());
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
