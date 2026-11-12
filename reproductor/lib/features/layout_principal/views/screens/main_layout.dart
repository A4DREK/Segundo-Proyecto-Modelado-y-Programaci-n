import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';

import '../../../biblioteca/views/screens/inicio_screen.dart';
import '../../../reproductor/views/screens/barra_reproduccion.dart'; 
import '../../../reproductor/controlador/controlador_reproductor.dart';
import '../../../edicion/controlador/controlador_edicion.dart';
import '../../../biblioteca/controlador/controlador_biblioteca.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReproductorControlador()),
        ChangeNotifierProvider(create: (_) => BibliotecaControlador()..cargarDatosBD()),
        ChangeNotifierProvider(create: (_) => EdicionControlador()),
      ],

      child: MacosWindow(
        backgroundColor: Colors.transparent,
        child: MacosScaffold(
          children: [
            ContentArea(
              builder: (context, scrollController) {
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
      ),
    );
    
      
  }
}