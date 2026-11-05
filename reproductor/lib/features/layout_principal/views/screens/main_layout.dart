//Ira todo lo principal aquí 

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

//El import de cada uno de los "mains" de cada feature 
import '../../../barra_lateral/views/side_bar.dart';
import '../../../biblioteca/views/screens/inicio_screen.dart';


class MainLayout extends StatelessWidget{
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {

    return MacosWindow(
      backgroundColor: Colors.transparent,

      sidebar: Sidebar(
        builder: (context, controller) {
          return const SideBar();
        },
        minWidth: 200,
      ),

      child: MacosScaffold(
        
        //Parte del centro de la pantalla principal
        children: [
          ContentArea(
            builder: (context, scrolllController) {
              return const InicioScreen();
            }
          )
        ]
      )
    );
  }
}