import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../core/colors/app_colors.dart';
import '../core/provider/theme_provider.dart';
import '../core/username/username.dart';
import '../services/nearby_services.dart';
import '../widgets/file_picker.dart';
import '../widgets/qrcode/mobileqrcode.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> pickedFiles = [];
  final nearby = NearbyService();
  bool connected = false;
  late String randomUsername;
  bool inPublicRoom = false;
  bool inPairedDevice = false;

  @override
  void initState() {
    super.initState();
    randomUsername = usernames[Random().nextInt(usernames.length)];
  }

  Future<void> _selectFiles() async {
    final files = await FileHelper.pickFiles();
    if (files != null) {
      setState(() {
        pickedFiles = files.map((f) => f.name).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    final isWeb = kIsWeb;
    final isMobile =
        !isWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final screenWidth = MediaQuery.of(context).size.width;
    final useMobileLayout = isMobile || (isWeb && screenWidth < 600);

    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            Padding(
              padding: useMobileLayout
                  ? EdgeInsets.only(
                      left: 12.sp,
                      right: 12.sp,
                      top: (isWeb && screenWidth < 600) ? 20.sp : 60.sp,
                      bottom: 12.sp,
                    )
                  : const EdgeInsets.only(
                      left: 40,
                      right: 40,
                      top: 32,
                      bottom: 12,
                    ),
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 1024,
                  maxHeight: 78,
                ),
                width: double.infinity,
                height: 78,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF1F2937)
                      : const Color(0xFFF9FAFB).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(
                    useMobileLayout ? 20.sp : 20,
                  ),
                  border: Border.all(
                    color: isDarkMode
                        ? const Color(0xFF374151)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Image.asset(
                        'assets/icons/ZpS.png',
                        width: useMobileLayout ? 40.sp : 45,
                      ),
                    ),
                    SizedBox(width: 5.sp),
                    Text(
                      'ZappShare',
                      style: TextStyle(
                        fontSize: useMobileLayout ? 14.sp : 18,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: EdgeInsets.only(right: 12.sp),
                      child: useMobileLayout
                          ? IconButton(
                              onPressed: () {
                                themeProvider.toggleTheme();
                              },
                              icon: Icon(
                                isDarkMode ? Iconsax.sun_1 : Iconsax.moon,
                                size: 20.sp,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            )
                          : Row(
                              spacing: isMobile ? 4.sp : 8,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      inPairedDevice = !inPairedDevice;
                                    });
                                    WoltModalSheet.show(
                                      context: context,
                                      pageListBuilder: (context) {
                                        return [
                                          _buildQrCodePage(context, isDarkMode),
                                        ];
                                      },
                                    );
                                  },
                                  icon: const Icon(Iconsax.people),
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      inPublicRoom = !inPublicRoom;
                                    });
                                    WoltModalSheet.show(
                                      context: context,
                                      pageListBuilder: (context) {
                                        return [
                                          _buildPublicRoomQrCodePage(
                                            context,
                                            isDarkMode,
                                          ),
                                        ];
                                      },
                                    );
                                  },
                                  icon: Icon(
                                    Iconsax.link_21,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    themeProvider.toggleTheme();
                                  },
                                  icon: Icon(
                                    isDarkMode ? Iconsax.sun_1 : Iconsax.moon,
                                    weight: 500,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    WoltModalSheet.show(
                                      context: context,
                                      pageListBuilder: (context) {
                                        return [
                                          _buildAboutSheet(context, isDarkMode),
                                        ];
                                      },
                                    );
                                  },
                                  icon: Icon(
                                    Iconsax.info_circle_copy,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: Center(
                child: Padding(
                  padding: useMobileLayout
                      ? EdgeInsets.only(
                          left: 12.sp,
                          right: 12.sp,
                          bottom: (isWeb && screenWidth < 600) ? 12.sp : 35.sp,
                        )
                      : const EdgeInsets.only(left: 40, right: 40, bottom: 35),
                  child: InkWell(
                    onTap: _selectFiles,
                    borderRadius: BorderRadius.circular(
                      useMobileLayout ? 20.sp : 20,
                    ),
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: 1024,
                        maxHeight: 1000,
                      ),
                      width: double.infinity,
                      // height: 980,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          useMobileLayout ? 20.sp : 20,
                        ),
                        color: isDarkMode
                            ? const Color(0xFF1F2937)
                            : const Color(0xFFF9FAFB).withValues(alpha: 0.8),
                        border: Border.all(
                          color: isDarkMode
                              ? const Color(0xFF374151)
                              : const Color(0xFFE5E7EB),
                          width: 1,
                          strokeAlign: BorderSide.strokeAlignInside,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          // horizontal: 48,
                          // vertical: 80,
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(isMobile ? 5.sp : 5),
                              child: Container(
                                width: isMobile ? double.infinity : 500,
                                height: isMobile ? 50.sp : 60,
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? const Color(0xFF1F2937)
                                      : const Color(
                                          0xFFF9FAFB,
                                        ).withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(
                                    isMobile ? 20.sp : 15,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  spacing: isMobile ? 5.sp : 5,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'You are connected as: ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w400,
                                            fontSize: isMobile ? 10.sp : 12,
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                        Text(
                                          randomUsername,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: isMobile ? 10.sp : 12,
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      spacing: isMobile ? 5.sp : 8,
                                      children: [
                                        connectionType(
                                          isMobile,
                                          'on this network',
                                        ),
                                        inPublicRoom
                                            ? connectionType(
                                                isMobile,
                                                'public room',
                                              )
                                            : SizedBox.shrink(),
                                        inPairedDevice
                                            ? connectionType(
                                                isMobile,
                                                'paired device',
                                              )
                                            : SizedBox.shrink(),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Open ZappShare on other devices to transfer files',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width >
                                              600
                                          ? 14
                                          : 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),

                                  Text(
                                    'Only devices in the same network are shown.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width >
                                              600
                                          ? 12
                                          : 10,
                                      color: AppColors.softGray,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: useMobileLayout
          ? SpeedDial(
              icon: Iconsax.add_copy,
              activeIcon: Icons.close,
              backgroundColor: isDarkMode
                  ? const Color(0xFF1F2937)
                  : const Color(0xFFF9FAFB).withValues(alpha: 0.8),
              overlayColor: isDarkMode
                  ? const Color(0xFF1F2937)
                  : const Color(0xFFF9FAFB).withValues(alpha: 0.8),
              elevation: 0,
              activeForegroundColor: null,

              foregroundColor: isDarkMode ? Colors.white : Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.sp),
              ),
              children: [
                SpeedDialChild(
                  child: const Icon(Iconsax.people),
                  label: 'Pair with device',
                  labelStyle: TextStyle(fontSize: 12.sp),
                  onTap: () {
                    setState(() {
                      inPairedDevice = !inPairedDevice;
                    });
                    final pin = (1000 + Random().nextInt(9000)).toString();
                    buildMobileQrCodeDialog(context, pin);
                  },
                ),
                SpeedDialChild(
                  child: const Icon(Iconsax.link_21),
                  label: 'Public room',
                  labelStyle: TextStyle(fontSize: 12.sp),
                  onTap: () {
                    setState(() {
                      inPublicRoom = !inPublicRoom;
                    });
                    final pin = (100000 + Random().nextInt(900000)).toString();
                    buildMobilePublicRoomQrCodeDialog(context, pin);
                  },
                ),
                SpeedDialChild(
                  child: const Icon(Iconsax.info_circle_copy),
                  label: 'About',
                  labelStyle: TextStyle(fontSize: 12.sp),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: isDarkMode
                            ? const Color(0xFF1F2937)
                            : const Color(0xFFF9FAFB),
                        title: Text(
                          'About ZappShare',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        content: Text(
                          'ZappShare v1.0.0',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            )
          : null,
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

  Row connectionType(bool isMobile, String connectionType) {
    final color = connectionColor(connectionType);
    return Row(
      spacing: isMobile ? 4.sp : 4,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 10.sp : 10,
            vertical: isMobile ? 5.sp : 5,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10.sp),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: isMobile ? 9.sp : 9,
                  child: Icon(
                    Icons.circle,
                    size: isMobile ? 10.sp : 10,
                    color: color,
                  ),
                ),
                SizedBox(width: isMobile ? 4.sp : 4),
                Text(
                  connectionTypeText(connectionType),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 10.sp : 10,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  WoltModalSheetPage _buildQrCodePage(BuildContext context, bool isDarkMode) {
    final tileColor = isDarkMode ? Colors.white : Colors.black;
    final pin = (1000 + Random().nextInt(9000)).toString();
    return WoltModalSheetPage(
      hasSabGradient: false,
      isTopBarLayerAlwaysVisible: true,
      hasTopBarLayer: true,
      topBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        color: connectionColor('paired device').withValues(alpha: 0.2),
        child: Text(
          'Pair with a device',
          style: TextStyle(
            color: connectionColor('paired device').withValues(alpha: 0.8),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      backgroundColor: isDarkMode
          ? const Color(0xFF1F2937)
          : const Color(0xFFF9FAFB),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            QrImageView(
              data: pin,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 10),
            Text(
              pin,
              style: TextStyle(
                color: tileColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Share this pin or QR code to let others\npair with your device',
              style: TextStyle(
                color: tileColor,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Divider(color: tileColor, thickness: 1),
            const SizedBox(height: 10),
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
              defaultPinTheme: PinTheme(
                width: 60,
                height: 60,
                textStyle: TextStyle(
                  fontSize: 20,
                  color: tileColor,
                  fontWeight: FontWeight.w600,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: tileColor.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
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
            Text(
              'Enter pin from another device to pair',
              style: TextStyle(
                color: tileColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: connectionColor('paired device'),
                      ),
                      onPressed: () {
                        debugPrint('Pair with device');
                        // TODO: Implement pairing logic
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'Pair with device',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'Close',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  WoltModalSheetPage _buildPublicRoomQrCodePage(
    BuildContext context,
    bool isDarkMode,
  ) {
    final tileColor = isDarkMode ? Colors.white : Colors.black;
    final pin = (100000 + Random().nextInt(900000)).toString();
    return WoltModalSheetPage(
      isTopBarLayerAlwaysVisible: true,
      hasTopBarLayer: true,
      hasSabGradient: false,
      topBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        color: connectionColor('public room').withValues(alpha: 0.2),
        child: Text(
          'Public room',
          style: TextStyle(
            color: connectionColor('public room').withValues(alpha: 0.8),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      backgroundColor: isDarkMode
          ? const Color(0xFF1F2937)
          : const Color(0xFFF9FAFB),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            QrImageView(
              data: pin,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 10),
            Text(
              '${pin.substring(0, 3)} ${pin.substring(3, 6)}',
              style: TextStyle(
                color: tileColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Share this pin or QR code to let others\njoin the public room',
              style: TextStyle(
                color: tileColor,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Divider(color: tileColor, thickness: 1),
            const SizedBox(height: 10),
            Text(
              'OR',
              style: TextStyle(
                color: tileColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Pinput(
              length: 6,
              defaultPinTheme: PinTheme(
                width: 60,
                height: 60,
                textStyle: TextStyle(
                  fontSize: 20,
                  color: tileColor,
                  fontWeight: FontWeight.w600,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: tileColor.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              separatorBuilder: (index) => index == 2
                  ? const SizedBox(width: 20)
                  : const SizedBox(width: 5),
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
            Text(
              'Enter pin from another device to join room',
              style: TextStyle(
                color: tileColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: connectionColor('public room'),
                    ),
                    onPressed: () {
                      debugPrint('Join room');
                      // TODO: Implement pairing logic
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'Join room',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  WoltModalSheetPage _buildAboutSheet(BuildContext context, bool isDarkMode) {
    final tileColor = isDarkMode ? Colors.white : Colors.black;
    return WoltModalSheetPage(
      hasSabGradient: false,
      topBarTitle: Text('About ZappShare', style: TextStyle(color: tileColor)),
      backgroundColor: isDarkMode
          ? const Color(0xFF1F2937)
          : const Color(0xFFF9FAFB),
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text("ZappShare v1.0.0")),
      ),
    );
  }
}
