import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../core/colors/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
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
                  color: const Color(0xFFF9FAFB).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Image.asset('assets/icons/ZpS.png', width: 45),
                    ),
                    const SizedBox(width: 5),
                     Text(
                      'ZappShare',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width > 600 ? 18 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Row(
                        spacing: MediaQuery.of(context).size.width > 600 ? 8 : 4,
                        children: [
                          IconButton(onPressed: () {}, icon: Icon(Iconsax.people), color: Colors.black,),
                          IconButton(onPressed: () {}, icon: Icon(Iconsax.link_21,  color: Colors.black,)),
                          IconButton(onPressed: () {}, icon: Icon(Iconsax.moon, weight: 500, color: Colors.black,)),
                          IconButton(onPressed: () {}, icon: Icon(Iconsax.info_circle_copy, color: Colors.black,)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 1024,
                      maxHeight: 1000,
                    ),
                    width: double.infinity,
                    // height: 980,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xFFF9FAFB).withValues(alpha: 0.8),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 80,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Open ZappShare on other devices to transfer files',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: MediaQuery.of(context).size.width > 600 ? 14 : 12, fontWeight: FontWeight.w600),
                          ),
                    
                          Text(
                            'Only devices in the same network are shown.',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width > 600 ? 12 : 10,
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

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: Colors.transparent,
              child:  Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Built with ',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width > 600 ? 10 : 10,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  FlutterLogo(size: 22),
                  Text(
                    ' by Odartei',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width > 600 ? 10 : 10,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF9CA3AF),
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
}
