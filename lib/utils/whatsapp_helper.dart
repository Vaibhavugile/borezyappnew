import 'package:url_launcher/url_launcher.dart';

Future<void> sendWhatsAppMessage(String phone, String message) async {

  if (phone.isEmpty) return;

  String formattedPhone =
      phone.startsWith("+91") ? phone : "+91$phone";

  final url = Uri.parse(
    "https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}",
  );

  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}