import 'package:flutter/material.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// 导入页面和管理器
import 'package:wclient/ui/home_page.dart';
import 'package:wclient/managers/data_manager.dart';
import 'package:wclient/managers/connection_manager.dart'; // 引入新的网络管理器

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _initApp();
  runApp(const MyApp());
}

Future<void> _initApp() async {
  try {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    await DataManager().loadSessions();
    ConnectionManager().start('');
  } catch (e) {
    print("App 初始化发生异常: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WeChat Flutter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFEDEDED),
      ),
      home: const HomePage(),
    );
  }
}