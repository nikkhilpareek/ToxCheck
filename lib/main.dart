import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:tox_check/pages/home_page.dart';
import 'package:tox_check/theme/app_colors.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ignore: deprecated_member_use
      useInheritedMediaQuery: true, 
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      debugShowCheckedModeBanner: false,
      title: 'ToxCheck',
      theme: AppColors.darkTheme,
      home: const HomePage(),
    );
  }
}



