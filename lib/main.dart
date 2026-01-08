import 'package:ai_chat_bot/chat/presentation/chat_page.dart';
import 'package:ai_chat_bot/chat/presentation/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
    print('✅ Successfully loaded .env file');
  } catch (e) {
    print('❌ Error loading .env: $e');
    print('⚠️  Make sure .env file exists and contains GEMINI_API_KEY');
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
        title: 'AI Assistant',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          fontFamily: 'Roboto',
        ),
        home: ChatPage(),
      ),
    );
  }
}
