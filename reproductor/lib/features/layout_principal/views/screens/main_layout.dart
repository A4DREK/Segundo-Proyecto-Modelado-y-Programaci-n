//Ira todo lo principal aquí 

import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';


class MainLayout extends HookWidget{
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosScaffold(
      backgroundColor: const Color(0xFF0C060B).withValues(alpha: 03),
    );
  }
}