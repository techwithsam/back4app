import 'package:back4app/homescreen.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const keyApplicationId = '<APP_ID>';
  const keyClientKey = '<CLIENT_KEY>';
  const keyParseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(keyApplicationId, keyParseServerUrl,
      clientKey: keyClientKey, debug: true);

  runApp(
    const MaterialApp(
      title: 'Movies',
      themeMode: ThemeMode.dark,
      home: HomeScreen(),
    ),
  );
}
