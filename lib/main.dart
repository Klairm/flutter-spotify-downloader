import 'package:sample_app/home.dart';
import 'package:flutter/material.dart';
import 'package:sample_app/utils/theme.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.darkTheme(context: context),
      home: SpotifyDownloader(),
    );
  }
}
