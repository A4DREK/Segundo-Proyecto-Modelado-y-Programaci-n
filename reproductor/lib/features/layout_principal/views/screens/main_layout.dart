import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../biblioteca/views/screens/inicio_screen.dart';
import '../../../reproductor/views/screens/barra_reproduccion.dart'; 

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosWindow(
      backgroundColor: Colors.transparent,
      child: MacosScaffold(
        children: [
          ContentArea(
            builder: (context, scrollController) {
              // Envolvemos todo en una columna
              return const Column(
                children: [
                  Expanded(
                    child: InicioScreen(),
                  ),
                  
                  BarraReproductor(),
                ],
              );
            },
          )
        ],
      ),
    );
  }
}