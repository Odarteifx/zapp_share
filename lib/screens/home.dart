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
import '../core/provider/webrtc_provider.dart';
import '../core/username/username.dart';
import '../widgets/file_picker.dart';
import '../widgets/qrcode/mobileqrcode.dart';
import 'package:file_picker/file_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PlatformFile> pickedFiles = [];
  late String randomUsername;

  @override
  void initState() {
    super.initState();
    randomUsername = usernames[Random().nextInt(usernames.length)];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final webrtcProvider =
          Provider.of<WebRTCProvider>(context, listen: false);
      final platform = WebRTCProvider.getPlatformPrefix();
      webrtcProvider.init('$platform:$randomUsername');
      webrtcProvider.onFileReceived = (name, path) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Received: $name')),
          );
        }
      };
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _selectFiles() async {
    final files = await FileHelper.pickFiles();
    if (files != null && files.isNotEmpty) {
      setState(() => pickedFiles = files);
    }
  }

  Future<void> _selectFolder() async {
    final files = await FileHelper.pickFolder();
    if (files != null && files.isNotEmpty) {
      setState(() => pickedFiles = files);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    final isWeb = kIsWeb;
    final isMacOS = defaultTargetPlatform == TargetPlatform.macOS;
    final isMacMini = isMacOS && MediaQuery.of(context).size.width < 600;
    final isMobile =
        !isWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final screenWidth = MediaQuery.of(context).size.width;
    final useMobileLayout = isMobile || (isWeb && screenWidth < 600) ;

    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            Padding(
              padding: useMobileLayout || isMacMini 
                  ? EdgeInsets.only(
                      left: 12.sp,
                      right: 12.sp,
                      top: (isWeb && screenWidth < 600 || isMacMini) ? 20.sp : 60.sp,
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
                        width: useMobileLayout || isMacMini ? 40.sp : 45,
                      ),
                    ),
                    SizedBox(width: 5.sp),
                    Text(
                      'ZappShare',
                      style: TextStyle(
                        fontSize: useMobileLayout || isMacMini ? 14.sp : 18,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: EdgeInsets.only(right: 12.sp),
                      child: useMobileLayout || isMacMini
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
                                  onPressed: _selectFiles,
                                  icon: const Icon(Iconsax.document),
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                  tooltip: 'Pick files to send',
                                ),
                                IconButton(
                                  onPressed: () {
                                    WoltModalSheet.show(
                                      context: context,
                                      pageListBuilder: (ctx) {
                                        return [
                                          _buildQrCodePage(ctx, isDarkMode),
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
                                    WoltModalSheet.show(
                                      context: context,
                                      pageListBuilder: (ctx) {
                                        return [
                                          _buildPublicRoomQrCodePage(
                                            ctx,
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
                  padding: useMobileLayout || isMacMini
                      ? EdgeInsets.only(
                          left: 12.sp,
                          right: 12.sp,
                          bottom: (isWeb && screenWidth < 600) ? 12.sp : 35.sp,
                        )
                      : const EdgeInsets.only(left: 40, right: 40, bottom: 35),
                  child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: 1024,
                        maxHeight: 1000,
                      ),
                      width: double.infinity,
                      // height: 980,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          useMobileLayout || isMacMini ? 20.sp : 20,
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
                                constraints: BoxConstraints(
                                  minHeight: isMobile ? 50.sp : 60,
                                ),
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
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isMobile ? 8.sp : 8,
                                    horizontal: isMobile ? 4.sp : 4,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              'You are connected as: ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w400,
                                                fontSize: isMobile ? 10.sp : 12,
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              randomUsername,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: isMobile ? 10.sp : 12,
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: isMobile ? 5.sp : 5),
                                      Consumer<WebRTCProvider>(
                                        builder: (_, webrtc, __) =>
                                            _buildConnectionBadges(
                                          isMobile,
                                          roomId: webrtc.roomId,
                                          isServerConnected:
                                              webrtc.isConnectedToServer,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Consumer<WebRTCProvider>(
                                builder: (context, webrtcProvider, child) {
                                  final hasFilesToSend =
                                      webrtcProvider.isDataChannelOpen &&
                                          pickedFiles.isNotEmpty;
                                  final showSendBanner = hasFilesToSend;

                                  return Column(
                                    children: [
                                      if (showSendBanner) ...[
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isMobile ? 12.sp : 20,
                                            vertical: isMobile ? 8.sp : 12,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '${pickedFiles.length} file(s) ready',
                                                style: TextStyle(
                                                  fontSize: isMobile ? 12.sp : 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDarkMode
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                              ),
                                              SizedBox(width: isMobile ? 12.sp : 16),
                                              ElevatedButton.icon(
                                                onPressed: () {
                                                  webrtcProvider.sendFiles(pickedFiles);
                                                  setState(() => pickedFiles = []);
                                                },
                                                icon: const Icon(Iconsax.send_1, size: 18),
                                                label: const Text('Send'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      Expanded(
                                        child: webrtcProvider.peers.isEmpty
                                            ? Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Iconsax.people,
                                                    size: 48,
                                                    color: AppColors.softGray,
                                                  ),
                                                  SizedBox(height: isMobile ? 12.sp : 16),
                                                  Text(
                                                    'No users on the network yet',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: MediaQuery.of(context)
                                                                  .size
                                                                  .width >
                                                              600
                                                          ? 14
                                                          : 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: isDarkMode
                                                          ? Colors.white
                                                          : Colors.black,
                                                    ),
                                                  ),
                                                  SizedBox(height: isMobile ? 4.sp : 6),
                                                  Text(
                                                    'Pair with a device or join a public room\nto see others nearby',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: MediaQuery.of(context)
                                                                  .size
                                                                  .width >
                                                              600
                                                          ? 12
                                                          : 10,
                                                      color: AppColors.softGray,
                                                      fontWeight: FontWeight.w400,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : LayoutBuilder(
                                                builder: (context, constraints) {
                                                  return _buildSolarLayout(
                                                    constraints: constraints,
                                                    peers: webrtcProvider.peers,
                                                    webrtcProvider: webrtcProvider,
                                                    isDarkMode: isDarkMode,
                                                    useMobileLayout: useMobileLayout || isMacMini,
                                                  );
                                                },
                                              ),
                                  ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: useMobileLayout || isMacMini
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
                  child: const Icon(Iconsax.document),
                  label: 'Pick folder',
                  labelStyle: TextStyle(fontSize: 12.sp),
                  onTap: _selectFolder,
                ),
                SpeedDialChild(
                  child: const Icon(Iconsax.people),
                  label: 'Pair with device',
                  labelStyle: TextStyle(fontSize: 12.sp),
                  onTap: () {
                    final pin = (1000 + Random().nextInt(9000)).toString();
                    buildMobileQrCodeDialog(
                      context,
                      pin,
                      webrtcProvider: Provider.of<WebRTCProvider>(context, listen: false),
                    );
                  },
                ),
                SpeedDialChild(
                  child: const Icon(Iconsax.link_21),
                  label: 'Public room',
                  labelStyle: TextStyle(fontSize: 12.sp),
                  onTap: () {
                    final pin = (100000 + Random().nextInt(900000)).toString();
                    buildMobilePublicRoomQrCodeDialog(
                      context,
                      pin,
                      webrtcProvider: Provider.of<WebRTCProvider>(context, listen: false),
                    );
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

  // ---------------------------------------------------------------------------
  // Solar orbit layout – "me" in the centre, peers orbiting around
  // ---------------------------------------------------------------------------

  Widget _buildSolarLayout({
    required BoxConstraints constraints,
    required List<String> peers,
    required WebRTCProvider webrtcProvider,
    required bool isDarkMode,
    required bool useMobileLayout,
  }) {
    final centerX = constraints.maxWidth / 2;
    final centerY = constraints.maxHeight / 2;
    // Orbit radius adapts to available space, leaving room for labels.
    final orbitRadius =
        (min(constraints.maxWidth, constraints.maxHeight) / 2) - (useMobileLayout ? 50 : 60);

    // Centre node – "You"
    final selfPlatform = WebRTCProvider.getPlatformPrefix();
    final selfIcon = _iconForPlatform(selfPlatform);
    final centerSize = useMobileLayout ? 52.0 : 60.0;

    final children = <Widget>[
      // Orbit ring
      Positioned(
        left: centerX - orbitRadius,
        top: centerY - orbitRadius,
        child: Container(
          width: orbitRadius * 2,
          height: orbitRadius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: (isDarkMode ? Colors.white : Colors.black)
                  .withValues(alpha: 0.06),
              width: 1,
            ),
          ),
        ),
      ),
      // Centre "You" node
      Positioned(
        left: centerX - centerSize / 2,
        top: centerY - centerSize / 2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: centerSize,
              height: centerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withValues(alpha: 0.8),
                    Colors.blue.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                selfIcon,
                size: useMobileLayout ? 22 : 26,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'You',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: useMobileLayout ? 9 : 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ];

    // Peer nodes arranged evenly around the orbit
    final count = peers.length;
    // Start from the top (-pi/2) so the first peer is at 12 o'clock.
    const startAngle = -pi / 2;

    for (var i = 0; i < count; i++) {
      final angle = startAngle + (2 * pi * i / count);
      final px = centerX + orbitRadius * cos(angle);
      final py = centerY + orbitRadius * sin(angle);

      final peerId = peers[i];
      final isPaired = webrtcProvider.connectedPeerId == peerId;

      children.add(
        Positioned(
          left: px - 40,
          top: py - 30,
          child: _buildPeerOrb(
            context: context,
            peerId: peerId,
            isPaired: isPaired,
            isDarkMode: isDarkMode,
            useMobileLayout: useMobileLayout,
            webrtcProvider: webrtcProvider,
          ),
        ),
      );
    }

    return Stack(children: children);
  }

  Widget _buildPeerOrb({
    required BuildContext context,
    required String peerId,
    required bool isPaired,
    required bool isDarkMode,
    required bool useMobileLayout,
    required WebRTCProvider webrtcProvider,
  }) {
    final peerName = WebRTCProvider.parsePeerName(peerId);
    final peerPlatform = WebRTCProvider.parsePeerPlatform(peerId);
    final platformLabel = WebRTCProvider.platformDisplayName(peerPlatform);
    final peerIcon = _iconForPlatform(peerPlatform);
    final orbSize = useMobileLayout ? 42.0 : 48.0;

    return GestureDetector(
      onTap: () {
        if (isPaired) return;
        _showPairMenu(context, webrtcProvider, peerId, peerName, platformLabel, isDarkMode);
      },
      onLongPress: isPaired
          ? () => _showUnpairMenu(context, webrtcProvider, peerName, isDarkMode)
          : null,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: orbSize,
              height: orbSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                border: Border.all(
                  color: isPaired ? Colors.green : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isPaired
                    ? [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                peerIcon,
                size: useMobileLayout ? 19 : 22,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              peerName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontSize: useMobileLayout ? 9 : 10,
                fontWeight: isPaired ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            Text(
              platformLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                fontSize: useMobileLayout ? 7 : 8,
                fontWeight: FontWeight.w400,
              ),
            ),
            if (isPaired)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Paired',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: useMobileLayout ? 7 : 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pair / Unpair confirmation popups
  // ---------------------------------------------------------------------------

  void _showPairMenu(
    BuildContext context,
    WebRTCProvider webrtcProvider,
    String peerId,
    String peerName,
    String platformLabel,
    bool isDarkMode,
  ) {
    final peerPlatform = WebRTCProvider.parsePeerPlatform(peerId);
    final peerIcon = _iconForPlatform(peerPlatform);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode
            ? const Color(0xFF1F2937)
            : const Color(0xFFF9FAFB),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              ),
              child: Icon(
                peerIcon,
                size: 26,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              peerName,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              platformLabel,
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Do you want to pair with this device?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ],
        ),
        actionsPadding:
            const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: BorderSide(
                      color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    webrtcProvider.connect(peerId);
                    Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Pair',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUnpairMenu(
    BuildContext context,
    WebRTCProvider webrtcProvider,
    String peerName,
    bool isDarkMode,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode
            ? const Color(0xFF1F2937)
            : const Color(0xFFF9FAFB),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Unpair from $peerName?',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will disconnect the active pairing.',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () {
              webrtcProvider.disconnect();
              Navigator.of(ctx).pop();
            },
            child: const Text(
              'Unpair',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForPlatform(String platform) {
    switch (platform) {
      case 'android':
      case 'ios':
        return Iconsax.mobile;
      case 'macos':
        return Iconsax.monitor;
      case 'windows':
        return Iconsax.monitor;
      case 'linux':
        return Iconsax.monitor;
      case 'web':
        return Iconsax.global;
      default:
        return Iconsax.mobile_copy;
    }
  }

  Widget _buildConnectionBadges(
    bool isMobile, {
    String? roomId,
    bool isServerConnected = false,
  }) {
    final badges = <Widget>[
      connectionType(
        isMobile,
        isServerConnected ? 'on this network' : 'disconnected',
      ),
    ];
    final isInPublicRoom = roomId != null && roomId.length == 6;
    final isInPairedDevice = roomId != null && roomId.length == 4;
    if (isInPublicRoom) {
      badges.add(connectionType(isMobile, 'public room'));
    }
    if (isInPairedDevice) {
      badges.add(connectionType(isMobile, 'paired device'));
    }

    if (badges.length <= 2) {
      // If 1 or 2 badges, show them in a single row
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: isMobile ? 5.sp : 8,
        children: badges,
      );
    } else {
      // If 3 badges, show 2 in first row, 1 in second row
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: isMobile ? 5.sp : 8,
            children: badges.sublist(0, 2),
          ),
          SizedBox(height: isMobile ? 5.sp : 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [badges[2]],
          ),
        ],
      );
    }
  }

  Color connectionColor(String connectionType) {
    if (connectionType == 'on this network') {
      return Colors.blue;
    } else if (connectionType == 'public room') {
      return Colors.green;
    } else if (connectionType == 'paired device') {
      return Colors.orange;
    } else if (connectionType == 'disconnected') {
      return Colors.red;
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
    } else if (connectionType == 'disconnected') {
      return 'Reconnecting…';
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
    final webrtcProvider = Provider.of<WebRTCProvider>(context, listen: false);
    final enteredPinHolder = <String?>[null];
    final tileColor = isDarkMode ? Colors.white : Colors.black;
    final pin = (1000 + Random().nextInt(9000)).toString();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return WoltModalSheetPage(
      hasSabGradient: false,
      isTopBarLayerAlwaysVisible: true,
      hasTopBarLayer: true,
      topBar: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16.sp : 24,
          vertical: isMobile ? 16.sp : 20,
        ),
        decoration: BoxDecoration(
          color: connectionColor('paired device').withValues(alpha: 0.2),
          border: Border(
            bottom: BorderSide(
              color: isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            ),
          ),
        ),
        child: Text(
          'Pair with a device',
          style: TextStyle(
            color: connectionColor('paired device').withValues(alpha: 0.9),
            fontSize: isMobile ? 16.sp : 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      backgroundColor: isDarkMode
          ? const Color(0xFF1F2937)
          : const Color(0xFFF9FAFB),
      child: Consumer<WebRTCProvider>(
        builder: (context, webrtc, _) {
          final activeRoomId = webrtc.roomId;
          if (activeRoomId != null && activeRoomId.isNotEmpty) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16.sp : 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
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
                  Container(
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
                      size: isMobile ? 180.sp : 200,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: isMobile ? 12.sp : 16),
                  Text(
                    activeRoomId,
                    style: TextStyle(
                      color: tileColor,
                      fontSize: isMobile ? 28 : 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: isMobile ? 6 : 8,
                    ),
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
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 12 : 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16.sp : 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
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
                    size: isMobile ? 180.sp : 200,
                    backgroundColor: Colors.white,
                  ),
                ),
                SizedBox(height: isMobile ? 12.sp : 16),
                Text(
                  pin,
                  style: TextStyle(
                    color: tileColor,
                    fontSize: isMobile ? 28 : 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: isMobile ? 6 : 8,
                  ),
                ),
                SizedBox(height: isMobile ? 8 : 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 8.0 : 0),
                  child: Text(
                    'Share this pin or QR code to let others\npair with your device',
                    style: TextStyle(
                      color: tileColor,
                      fontSize: isMobile ? 13 : 14,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: isMobile ? 8 : 10),
                Divider(color: tileColor, thickness: 1),
                SizedBox(height: isMobile ? 8 : 10),
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
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 0),
                  child: Pinput(
                length: 4,
                defaultPinTheme: PinTheme(
                  width: isMobile ? 50 : 60,
                  height: isMobile ? 50 : 60,
                  textStyle: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    color: tileColor,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: tileColor.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                separatorBuilder: (index) => SizedBox(width: isMobile ? 10 : 15),
                onCompleted: (value) => enteredPinHolder[0] = value,
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Please enter a valid pin' : null,
              ),
            ),
            SizedBox(height: isMobile ? 16 : 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 8.0 : 0),
              child: Text(
                'Enter pin from another device to pair',
                style: TextStyle(
                  color: tileColor,
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: isMobile ? 8 : 10),
            Padding(
              padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
              child: isMobile
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: connectionColor('paired device'),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          onPressed: () {
                            final roomPin = enteredPinHolder[0] ?? pin;
                            webrtcProvider.joinRoom(roomPin);
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Pair with device',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Close',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
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
                            final roomPin = enteredPinHolder[0] ?? pin;
                            webrtcProvider.joinRoom(roomPin);
                            Navigator.of(context).pop();
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
          ],
        ),
      );
        },
      ),
    );
  }

  WoltModalSheetPage _buildPublicRoomQrCodePage(
    BuildContext context,
    bool isDarkMode,
  ) {
    final webrtcProvider = Provider.of<WebRTCProvider>(context, listen: false);
    final enteredPinHolder = <String?>[null];
    final tileColor = isDarkMode ? Colors.white : Colors.black;
    final pin = (100000 + Random().nextInt(900000)).toString();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return WoltModalSheetPage(
      isTopBarLayerAlwaysVisible: true,
      hasTopBarLayer: true,
      hasSabGradient: false,
      topBar: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16.sp : 24,
          vertical: isMobile ? 16.sp : 20,
        ),
        decoration: BoxDecoration(
          color: connectionColor('public room').withValues(alpha: 0.2),
          border: Border(
            bottom: BorderSide(
              color: isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            ),
          ),
        ),
        child: Text(
          'Public room',
          style: TextStyle(
            color: connectionColor('public room').withValues(alpha: 0.9),
            fontSize: isMobile ? 16.sp : 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      backgroundColor: isDarkMode
          ? const Color(0xFF1F2937)
          : const Color(0xFFF9FAFB),
      child: Consumer<WebRTCProvider>(
        builder: (context, webrtc, _) {
          final activeRoomId = webrtc.roomId;
          if (activeRoomId != null && activeRoomId.isNotEmpty) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16.sp : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
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
                  Container(
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
                      size: isMobile ? 180.sp : 200,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: isMobile ? 12.sp : 16),
                  Text(
                    activeRoomId.length == 6
                        ? '${activeRoomId.substring(0, 3)} ${activeRoomId.substring(3, 6)}'
                        : activeRoomId,
                    style: TextStyle(
                      color: tileColor,
                      fontSize: isMobile ? 28 : 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: isMobile ? 6 : 8,
                    ),
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
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 12 : 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16.sp : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
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
                    size: isMobile ? 180.sp : 200,
                    backgroundColor: Colors.white,
                  ),
                ),
                SizedBox(height: isMobile ? 12.sp : 16),
                Text(
                  '${pin.substring(0, 3)} ${pin.substring(3, 6)}',
                  style: TextStyle(
                    color: tileColor,
                    fontSize: isMobile ? 28 : 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: isMobile ? 6 : 8,
                  ),
                ),
                SizedBox(height: isMobile ? 8 : 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 8.0 : 0),
                  child: Text(
                    'Share this pin or QR code to let others\njoin the public room',
                    style: TextStyle(
                      color: tileColor,
                      fontSize: isMobile ? 13 : 14,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: isMobile ? 8 : 10),
                Divider(color: tileColor, thickness: 1),
                SizedBox(height: isMobile ? 8 : 10),
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
                    length: 6,
                defaultPinTheme: PinTheme(
                  width: isMobile ? 45 : 60,
                  height: isMobile ? 45 : 60,
                  textStyle: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    color: tileColor,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: tileColor.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                separatorBuilder: (index) => SizedBox(
                  width: index == 2
                      ? (isMobile ? 12 : 20)
                      : (isMobile ? 4 : 5),
                ),
                onCompleted: (value) => enteredPinHolder[0] = value,
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Please enter a valid pin' : null,
              ),
            ),
            SizedBox(height: isMobile ? 16 : 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 8.0 : 0),
              child: Text(
                'Enter pin from another device to join room',
                style: TextStyle(
                  color: tileColor,
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: isMobile ? 8 : 10),
            Padding(
              padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
              child: isMobile
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: connectionColor('public room'),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              final roomPin = enteredPinHolder[0] ?? pin;
                              webrtcProvider.joinRoom(roomPin);
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              'Join room',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Close',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
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
                            final roomPin = enteredPinHolder[0] ?? pin;
                            webrtcProvider.joinRoom(roomPin);
                            Navigator.of(context).pop();
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
      );
        },
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
