import 'package:ai_chat_bot/chat/presentation/chat_page.dart';
import 'package:ai_chat_bot/chat/presentation/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'dart:io';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    print('Looking for .env at: ${File('.env').absolute.path}');
    await dotenv.load(fileName: '.env');
    print('Successfully loaded .env file');
  } catch (e) {
    print('Error loading .env: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ChatPage(),
      ),
    );
  }
}