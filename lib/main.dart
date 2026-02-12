import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'core/colors/app_colors.dart';
import 'core/provider/theme_provider.dart';
import 'core/provider/webrtc_provider.dart';
import 'core/router/app_router.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => WebRTCProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'ZappShare',
            routerConfig: router,
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: AppColors.whiteColor,
              textTheme: GoogleFonts.interTextTheme(),
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.black,
                brightness: Brightness.light,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: AppColors.blackColor,
              textTheme:
                  GoogleFonts.interTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.white,
                brightness: Brightness.dark,
              ),
            ),
          );
        },
      ),
    );
  }
}
