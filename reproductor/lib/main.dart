import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'sandbox.dart';
import 'package:reproductor/src/rust/frb_generated.dart';

/// This method initializes macos_window_utils and styles the window.
Future<void> _configureMacosWindowUtils() async {
  const config = MacosWindowUtilsConfig(
    toolbarStyle: NSWindowToolbarStyle.expanded,
  );
  await config.apply();
}
void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  if(!kIsWeb && Platform.isMacOS){
    await _configureMacosWindowUtils();
  }
  
  await RustLib.init();

  runApp(const Mp3Player());
}

class Mp3Player extends StatelessWidget {
  const Mp3Player({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosApp(
      title: 'Reproductor',
      debugShowCheckedModeBanner: true,
      theme: MacosThemeData.light().copyWith(visualDensity: VisualDensity.adaptivePlatformDensity),
      darkTheme: MacosThemeData.dark().copyWith(canvasColor: Colors.transparent),
      themeMode: ThemeMode.system,
      home: const SandboxScreen(), 
    );
  }
}