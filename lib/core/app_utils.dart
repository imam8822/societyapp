import 'package:flutter/material.dart';

class AppUtils {
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  static void showError(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  static void showInfo(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  static void showUpiAppsBottomSheet(BuildContext context, String upiDeepLink, Function(Uri) launchApp) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Payment App',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.payment, color: Colors.blue),
                  title: const Text('GPay'),
                  onTap: () {
                    Navigator.pop(ctx);
                    launchApp(Uri.parse(upiDeepLink.replaceFirst('upi://pay', 'tez://upi/pay')));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.payment, color: Colors.purple),
                  title: const Text('PhonePe'),
                  onTap: () {
                    Navigator.pop(ctx);
                    launchApp(Uri.parse(upiDeepLink.replaceFirst('upi://pay', 'phonepe://pay')));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.payment, color: Colors.lightBlue),
                  title: const Text('Paytm'),
                  onTap: () {
                    Navigator.pop(ctx);
                    launchApp(Uri.parse(upiDeepLink.replaceFirst('upi://pay', 'paytmmp://pay')));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.apps, color: Colors.grey),
                  title: const Text('Other UPI Apps'),
                  onTap: () {
                    Navigator.pop(ctx);
                    launchApp(Uri.parse(upiDeepLink));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
