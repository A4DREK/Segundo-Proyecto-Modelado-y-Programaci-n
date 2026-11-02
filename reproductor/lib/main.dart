import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'sandbox.dart';

/// This method initializes macos_window_utils and styles the window.
Future<void> _configureMacosWindowUtils() async {
  const config = MacosWindowUtilsConfig(
    toolbarStyle: NSWindowToolbarStyle.expanded,
  );
  await config.apply();
}
void main() async {

  await _configureMacosWindowUtils();

  runApp(const Mp3Player());
}

class Mp3Player extends StatelessWidget {
  const Mp3Player({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosApp(
      title: 'Reproductor',
      debugShowCheckedModeBanner: true,
      theme: MacosThemeData.light(),
      darkTheme: MacosThemeData.dark().copyWith(visualDensity: VisualDensity.adaptivePlatformDensity),
      themeMode: ThemeMode.system, // Se adapta al modo oscuro/claro de la Mac
      home: const SandboxScreen(), 
    );
  }
}