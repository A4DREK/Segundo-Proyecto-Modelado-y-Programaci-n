import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'features/reproductor/views/screens/reproductor.dart';

void main() {
  runApp(const Mp3Player());
}

class Mp3Player extends StatelessWidget {
  const Mp3Player({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosApp(
      title: 'Reproductor',
      debugShowCheckedModeBanner: false,
      theme: MacosThemeData.light(),
      darkTheme: MacosThemeData.dark(),
      themeMode: ThemeMode.system, // Se adapta al modo oscuro/claro de la Mac
      home: const ReproductorScreen(), 
    );
  }
}