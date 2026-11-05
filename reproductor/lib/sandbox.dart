import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

//Este import tendrá cada funcionalidad que quiero probar, por lo que tendrá cambios constantes
import 'package:reproductor/features/layout_principal/views/screens/main_layout.dart';

class SandboxScreen extends StatelessWidget {
  const SandboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosWindow(
      backgroundColor: Colors.transparent,
      child: MacosScaffold(
        backgroundColor: Colors.transparent,
        children: [
          ContentArea(
            builder: (context, scrollController) {
              return const Center(
                // Aquí se cambiara cada valor en específico para probar de forma individual
                child: MainLayout(), 
              );
            },
          ),
        ],
      ),
    );
  }
}