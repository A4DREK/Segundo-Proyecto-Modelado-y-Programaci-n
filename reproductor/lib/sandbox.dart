import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

//Este import tendrá cada funcionalidad que quiero probar, por lo que tendrá cambios constantes
import 'package:reproductor/features/barra_lateral/views/side_bar.dart';

class SandboxScreen extends StatelessWidget {
  const SandboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosWindow(
      child: MacosScaffold(
        children: [
          ContentArea(
            builder: (context, scrollController) {
              return const Center(
                // Aquí se cambiara cada valor en específico para probar de forma individual
                child: SideBar(), 
              );
            },
          ),
        ],
      ),
    );
  }
}