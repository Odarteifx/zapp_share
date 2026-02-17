import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/colors/app_colors.dart';
import '../../core/provider/theme_provider.dart';
import '../../core/provider/webrtc_provider.dart';

Future<dynamic> buildMobileQrCodeDialog(
  BuildContext context,
  String pin, {
  required WebRTCProvider webrtcProvider,
}) async {
  // Instantly join the room so the creator is already waiting.
  webrtcProvider.joinRoom(pin);

  final isMobileDevice = defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  final pinController = TextEditingController();
  final result = showDialog(
    barrierDismissible: isMobileDevice,
    context: context,
    builder: (context) {
      final isDarkMode =
          Provider.of<ThemeProvider>(context, listen: false).themeMode ==
          ThemeMode.dark;
      final tileColor = isDarkMode ? Colors.white : Colors.black;
      final screenWidth = MediaQuery.of(context).size.width;
      final isMobile = screenWidth < 400;
      
      // Create a ScrollController to control scrolling
      final scrollController = ScrollController();
      
      // Scroll to bottom after the dialog is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
      
      return AlertDialog(
        backgroundColor: isDarkMode
            ? const Color(0xFF1F2937)
            : const Color(0xFFF9FAFB).withValues(alpha: 0.98),
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16.sp : 24,
            vertical: isMobile ? 16.sp : 20,
          ),
          decoration: BoxDecoration(
            color: connectionColor('paired device').withValues(alpha: 0.2),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border(
              bottom: BorderSide(
                color: isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
              ),
            ),
          ),
          child: Text(
            'Pair with a device',
            style: TextStyle(
              color: connectionColor('paired device'),
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        contentPadding: EdgeInsets.all(isMobile ? 16.sp : 24),
        content: Consumer<WebRTCProvider>(
          builder: (context, webrtc, _) {
            // Auto-close when a peer connects via data channel (1:1 pairing complete).
            if (webrtc.isDataChannelOpen) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              });
            }
            return SingleChildScrollView(
              controller: scrollController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: isMobile ? 184 : 232,
                    height: isMobile ? 184 : 232,
                    child: Container(
                      padding: EdgeInsets.all(isMobile ? 12.sp : 16),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF374151).withValues(alpha: 0.5)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDarkMode
                              ? const Color(0xFF374151)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: QrImageView(
                        data: pin,
                        version: QrVersions.auto,
                        size: isMobile ? 160.sp : 200,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: isMobile ? 4 : 5),
                  Text(
                    pin,
                    style: TextStyle(
                      color: tileColor,
                      fontSize: isMobile ? 28 : 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: isMobile ? 3 : 4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isMobile ? 4 : 5),
                  Text(
                    'Share this pin or QR code to let others\npair with your device',
                    style: TextStyle(
                      color: tileColor,
                      fontSize: isMobile ? 13 : 14,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isMobile ? 4 : 5),
                  Divider(color: tileColor, thickness: 1),
                  SizedBox(height: isMobile ? 4 : 5),
                  Text(
                    'OR',
                    style: TextStyle(
                      color: tileColor,
                      fontSize: isMobile ? 13 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isMobile ? 8 : 10),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 8.0 : 0),
                    child: Pinput(
                      controller: pinController,
                      length: 4,
                      defaultPinTheme: PinTheme(
                        width: isMobile ? 45 : 60,
                        height: isMobile ? 45 : 60,
                        decoration: BoxDecoration(
                          border: Border.all(color: tileColor.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: TextStyle(
                          fontSize: isMobile ? 18 : 20,
                          color: tileColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      separatorBuilder: (index) => SizedBox(width: isMobile ? 8 : 15),
                      onCompleted: (value) {
                        if (value.length == 4) {
                          webrtcProvider.joinRoom(value);
                          Navigator.of(context).pop();
                        }
                      },
                      validator: (value) =>
                          (value == null || value.isEmpty) ? 'Please enter a valid pin' : null,
                    ),
                  ),
                  SizedBox(height: isMobile ? 16 : 20),
                  Text(
                    'Enter pin from another device to pair instantly',
                    style: TextStyle(
                      color: tileColor,
                      fontSize: isMobile ? 11 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
        actionsPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8.0 : 24.0,
          vertical: isMobile ? 8.0 : 16.0,
        ),
        actions: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: isMobile ? 8 : 10,
            runSpacing: 8,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: connectionColor('paired device'),
                  foregroundColor: isDarkMode ? Colors.black : Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12.0 : 16.0,
                    vertical: isMobile ? 10.0 : 12.0,
                  ),
                ),
                onPressed: () {
                  final entered = pinController.text.replaceAll(' ', '');
                  if (entered.length == 4) {
                    webrtcProvider.joinRoom(entered);
                    Navigator.of(context).pop();
                  }
                },
                child: Text(
                  'Join',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12.0 : 16.0,
                    vertical: isMobile ? 10.0 : 12.0,
                  ),
                ),
                onPressed: () {
                  webrtcProvider.leaveRoom();
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Close',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
  result.then((_) => pinController.dispose());
  return result;
}

Future<dynamic> buildMobilePublicRoomQrCodeDialog(
  BuildContext context,
  String pin, {
  required WebRTCProvider webrtcProvider,
}) async {
  final isMobileDevice = defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  final pinController = TextEditingController();
  final result = showDialog(
    barrierDismissible: isMobileDevice,
    context: context,
    builder: (context) {
      final isDarkMode =
          Provider.of<ThemeProvider>(context, listen: false).themeMode ==
          ThemeMode.dark;
      final tileColor = isDarkMode ? Colors.white : Colors.black;
      final screenWidth = MediaQuery.of(context).size.width;
      final isMobile = screenWidth < 400;

      // Create a ScrollController to control scrolling
      final scrollController = ScrollController();
      
      // Scroll to bottom after the dialog is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      return AlertDialog(
        backgroundColor: isDarkMode
            ? const Color(0xFF1F2937)
            : const Color(0xFFF9FAFB).withValues(alpha: 0.98),
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16.sp : 24,
            vertical: isMobile ? 16.sp : 20,
          ),
          decoration: BoxDecoration(
            color: connectionColor('public room').withValues(alpha: 0.2),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border(
              bottom: BorderSide(
                color: isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
              ),
            ),
          ),
          child: Text(
            'Public room',
            style: TextStyle(
              color: connectionColor('public room'),
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        contentPadding: EdgeInsets.all(isMobile ? 16.sp : 24),
        content: Consumer<WebRTCProvider>(
          builder: (context, webrtc, _) {
            final activeRoomId = webrtc.roomId;
            if (activeRoomId != null && activeRoomId.isNotEmpty) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Active room',
                      style: TextStyle(
                        color: tileColor,
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: isMobile ? 12.sp : 16),
                    SizedBox(
                      width: isMobile ? 184 : 232,
                      height: isMobile ? 184 : 232,
                      child: Container(
                        padding: EdgeInsets.all(isMobile ? 12.sp : 16),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF374151).withValues(alpha: 0.5)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDarkMode
                                ? const Color(0xFF374151)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: QrImageView(
                          data: activeRoomId,
                          version: QrVersions.auto,
                          size: isMobile ? 160.sp : 200,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 12.sp : 16),
                    Text(
                      activeRoomId.length == 6
                          ? '${activeRoomId.substring(0, 3)} ${activeRoomId.substring(3, 6)}'
                          : activeRoomId,
                      style: TextStyle(
                        color: tileColor,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isMobile ? 16 : 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          webrtc.leaveRoom();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Exit room'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: Colors.red,
                          foregroundColor: AppColors.whiteColor,
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12.0 : 16.0,
                            vertical: isMobile ? 12.0 : 14.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return SingleChildScrollView(
              controller: scrollController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: isMobile ? 184 : 232,
                    height: isMobile ? 184 : 232,
                    child: Container(
                      padding: EdgeInsets.all(isMobile ? 12.sp : 16),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF374151).withValues(alpha: 0.5)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDarkMode
                              ? const Color(0xFF374151)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: QrImageView(
                        data: pin,
                        version: QrVersions.auto,
                        size: isMobile ? 160.sp : 200,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: isMobile ? 12.sp : 16),
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
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 8.0 : 0),
                    child: Pinput(
                      controller: pinController,
                      length: 6,
                      defaultPinTheme: PinTheme(
                        decoration: BoxDecoration(
                          border: Border.all(color: tileColor.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        width: isMobile ? 40 : 60,
                        height: isMobile ? 40 : 60,
                        textStyle: TextStyle(
                          fontSize: isMobile ? 18 : 20,
                          color: tileColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      separatorBuilder: (index) => SizedBox(
                        width: index == 2
                            ? (isMobile ? 10 : 20)
                            : (isMobile ? 3 : 5),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a valid pin';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Enter pin from another device to join room',
                    style: TextStyle(
                      color: tileColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
        actionsPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8.0 : 24.0,
          vertical: isMobile ? 8.0 : 16.0,
        ),
        actions: [
          Consumer<WebRTCProvider>(
          builder: (context, webrtc, _) {
            if (webrtc.roomId != null && webrtc.roomId!.isNotEmpty) {
              return const SizedBox.shrink();
            }
            return Wrap(
              alignment: WrapAlignment.center,
              spacing: isMobile ? 8 : 10,
            runSpacing: 8,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: connectionColor('public room'),
                  foregroundColor: isDarkMode ? Colors.black : Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12.0 : 16.0,
                    vertical: isMobile ? 10.0 : 12.0,
                  ),
                ),
                onPressed: () {
                  final entered = pinController.text.replaceAll(' ', '');
                  final roomPin = (entered.length == 6) ? entered : pin;
                  webrtcProvider.joinRoom(roomPin);
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Join',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 12 : 14,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.red,
                  foregroundColor: AppColors.whiteColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12.0 : 16.0,
                    vertical: isMobile ? 10.0 : 12.0,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: AppColors.whiteColor,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 12 : 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            );
          },
        ),
        ],
      );
    },
  );
  result.then((_) => pinController.dispose());
  return result;
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
