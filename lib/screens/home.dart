import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../core/colors/app_colors.dart';
import '../core/provider/theme_provider.dart';
import '../services/nearby_services.dart';
import '../widgets/file_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> pickedFiles = [];
  final nearby = NearbyService();
  bool connected = false;

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
  final isMobile = !kIsWeb && (Platform.isIOS || Platform.isAndroid);
  final screenWidth = MediaQuery.of(context).size.width;
  


    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            Padding(
              padding: isMobile
                  ? EdgeInsets.only(
                    left: 12.sp,
                    right: 12.sp,
                    top: 60.sp,
                    bottom: 12.sp,
                  )
                  : EdgeInsets.only(
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
                  color: isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(isMobile ? 20.sp : 20),
                  border: Border.all(color: isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Image.asset('assets/icons/ZpS.png', width: isMobile ? 40.sp : 45),
                    ),
                    SizedBox(width: 5.sp),
                    Text(
                      'ZappShare',
                      style: TextStyle(
                        fontSize: isMobile ? 14.sp : isWeb && screenWidth > 600 ? 18 : 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: EdgeInsets.only(right: 12.sp),
                      child: isMobile || (screenWidth < 500)
                          ? IconButton(
                              onPressed: () {
                                themeProvider.toggleTheme();
                              },
                              icon: Icon(
                                isDarkMode ? Iconsax.sun_1 : Iconsax.moon,
                                size: 20.sp,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                              onHover: (value) {},
                            )
                          : Row(
                        spacing: MediaQuery.of(context).size.width > 600
                            ? 8
                            : 4,
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Iconsax.people),
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(Iconsax.link_21, color: isDarkMode ? Colors.white : Colors.black),
                          ),
                          IconButton(
                            onPressed: () {
                              themeProvider.toggleTheme();
                            },
                            icon: Icon(
                              isDarkMode ? Iconsax.sun_1 : Iconsax.moon,
                              weight: 500,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            onHover: (value) {},
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(
                              Iconsax.info_circle_copy,
                              color: isDarkMode ? Colors.white : Colors.black,
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
                  padding: isMobile ? EdgeInsets.only(left: 12.sp, right: 12.sp, bottom: 35.sp) : EdgeInsets.symmetric(horizontal: 40,),
                  child: InkWell(
                    onTap: _selectFiles,
                    borderRadius: BorderRadius.circular( isMobile ? 20.sp : 20),
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: 1024,
                        maxHeight: 1000,
                      ),
                      width: double.infinity,
                      // height: 980,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(isMobile ? 20.sp : 20),
                        color: isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB).withValues(alpha: 0.8),
                        border: Border.all(
                          color: isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                          width: 1,
                          strokeAlign: BorderSide.strokeAlignInside,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          // horizontal: 48,
                          vertical: 80,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Open ZappShare on other devices to transfer files',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.width > 600 ? 14 : 12,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),

                            Text(
                              'Only devices in the same network are shown.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.width > 600
                                    ? 12
                                    : 10,
                                color: AppColors.softGray,
                                fontWeight: FontWeight.w400,
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

            // Container(
            //   padding: EdgeInsets.symmetric(horizontal: isMobile ? 20.sp : screenWidth > 600 ? 20 : 10, vertical: isMobile ? 15.sp : 10),
            //   color: Colors.transparent,
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     children: [
            //       Text(
            //         'Built with ',
            //         style: TextStyle(
            //           fontSize: isMobile ? 10.sp : MediaQuery.of(context).size.width > 600
            //               ? 10
            //               : 10,
            //           fontWeight: FontWeight.w400,
            //           color: isDarkMode ? AppColors.softGray : const Color(0xFF9CA3AF),
            //         ),
            //       ),
            //       FlutterLogo(size: isMobile ? 16.sp : 22),
            //       Text(
            //         ' by Odartei',
            //         style: TextStyle(
            //           fontSize: isMobile ? 10.sp : MediaQuery.of(context).size.width > 600
            //               ? 10
            //               : 10,
            //           fontWeight: FontWeight.w400,
            //           color: isDarkMode ? AppColors.softGray : const Color(0xFF9CA3AF),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
      floatingActionButton: !isMobile || !(screenWidth < 500)
          ? null
          : SpeedDial(
              icon: Iconsax.add_copy,
              activeIcon: Icons.close,
              backgroundColor: isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB).withValues(alpha: 0.8),
              overlayColor: isDarkMode ? const Color(0xFF1F2937) :const Color(0xFFF9FAFB).withValues(alpha: 0.8),
              elevation: 0,
              activeForegroundColor: null,
              
              foregroundColor: isDarkMode ? Colors.white : Colors.black,
              shape: RoundedRectangleBorder(
                // side: BorderSide(color: isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB), width: 1),
                  borderRadius: BorderRadius.circular(20.sp)
                  ),
              children: [
                SpeedDialChild(
                  child: const Icon(Iconsax.people),
                  label: 'Pair with device',
                  labelStyle: TextStyle(fontSize: 12.sp,),
                  onTap: () {
                    // Handle people action
                  },
                ),
                SpeedDialChild(
                  child: const Icon(Iconsax.link_21),
                  label: 'Public room',
                  labelStyle: TextStyle(fontSize: 12.sp,),
                  onTap: () {
                    // Handle link action
                  },
                ),
              ],
            ),
    );
  }
}
