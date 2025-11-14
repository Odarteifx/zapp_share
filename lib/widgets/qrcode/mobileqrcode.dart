import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/colors/app_colors.dart';
import '../../core/provider/theme_provider.dart';

Future<dynamic> buildMobileQrCodeDialog(
  BuildContext context,
  String pin,
) async {
  return showDialog(
    barrierDismissible: false,
    context: context,
    builder: (context) {
      final isDarkMode =
          Provider.of<ThemeProvider>(context, listen: false).themeMode ==
          ThemeMode.dark;
      final tileColor = isDarkMode ? Colors.white : Colors.black;
      return AlertDialog(
        backgroundColor: isDarkMode
            ? const Color(0xFF1F2937)
            : const Color(0xFFF9FAFB),
        titlePadding: const EdgeInsets.all(0),
        title: Container(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 20.0),
          decoration: BoxDecoration(
            color: connectionColor('paired device').withAlpha(50),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28.0),
              topRight: Radius.circular(28.0),
            ),
          ),
          child: Text(
            'Pair with a device',
            style: TextStyle(
              color: connectionColor('paired device'),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(
                data: pin,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            Text(
             pin,
              style: TextStyle(
                color: tileColor,
                fontSize: 32,   
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              'Share this pin or QR code to let others\npair with your device',
              style: TextStyle(
                color: tileColor,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Divider(color: tileColor, thickness: 1),
            const SizedBox(height: 5),
            Text(
              'OR',
              style: TextStyle(
                color: tileColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Pinput(
              length: 4,
              separatorBuilder: (index) => const SizedBox(width: 15),
              onCompleted: (value) {
                debugPrint(value);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a valid pin';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text('Enter pin from another device to pair', style: TextStyle(color: tileColor, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center,),
            // const SizedBox(height: 5),
          ],
        ),
        actions: [
          Row(
            spacing: 10,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: connectionColor('paired device'),
                  foregroundColor: isDarkMode ? Colors.black : Colors.white,
                ),
                onPressed: () {
                  debugPrint('Pair with device');
                },
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    'Pair with device',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, ),
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.red,
                  foregroundColor: AppColors.whiteColor,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    'Close',
                    style: TextStyle(color: AppColors.whiteColor, fontWeight: FontWeight.bold, ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

Future<dynamic> buildMobilePublicRoomQrCodeDialog(
  BuildContext context,
  String pin,
) async {
  return showDialog(
    barrierDismissible: false,
    context: context,
    builder: (context) {
      final isDarkMode =
          Provider.of<ThemeProvider>(context, listen: false).themeMode ==
          ThemeMode.dark;
      final tileColor = isDarkMode ? Colors.white : Colors.black;

      return AlertDialog(
        backgroundColor: isDarkMode
            ? const Color(0xFF1F2937)
            : const Color(0xFFF9FAFB),
        titlePadding: const EdgeInsets.all(0),
        title: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          decoration: BoxDecoration(
            color: connectionColor('public room').withAlpha(50),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Text(
            'Public Room',
            style: TextStyle(
              color: connectionColor('public room'),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(
                data: pin,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            Text(
               '${pin.substring(0, 3)} ${pin.substring(3, 6)}',
              style: TextStyle(
                color: tileColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              'Share this pin or QR code to let others\njoin the public room',
              style: TextStyle(
                color: tileColor,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Divider(color: tileColor, thickness: 1),
            const SizedBox(height: 5),
            Text(
              'OR',
              style: TextStyle(
                color: tileColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Pinput(
              length: 6,
              separatorBuilder: (index) => index == 2 ? const SizedBox(width: 20) : const SizedBox(width: 5),
              onCompleted: (value) {
                debugPrint(value);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a valid pin';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text('Enter pin from another device to join room', style: TextStyle(color: tileColor, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center,),
            // const SizedBox(height: 5),
          ],
        ),
        actions: [
          Row(
            spacing: 10,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: connectionColor('public room'),
                  foregroundColor: isDarkMode ? Colors.black : Colors.white,
                ),
                onPressed: () {
                  debugPrint('Join room');
                },
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    'Join Room',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, ),
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.red,
                  foregroundColor: AppColors.whiteColor,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    'Close',
                    style: TextStyle(color: AppColors.whiteColor, fontWeight: FontWeight.bold, ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

Color connectionColor(String connectionType) {
  if (connectionType == 'on this network') {
    return Colors.blue;
  } else if (connectionType == 'public room') {
    return Colors.green;
  } else if (connectionType == 'paired device') {
    return Colors.orange;
  } else {
    return Colors.grey;
  }
}

String connectionTypeText(String connectionType) {
  if (connectionType == 'on this network') {
    return 'On this network';
  } else if (connectionType == 'public room') {
    return 'In a public room';
  } else if (connectionType == 'paired device') {
    return 'Paired with a device';
  } else {
    return 'Unknown';
  }
}
