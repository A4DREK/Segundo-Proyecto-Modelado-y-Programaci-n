//Aquí ira la parte del botón del toggle de la vista entre cambiar la biblioteca
//del grid y la biblioteca de lista 

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../controlador/controlador_biblioteca.dart';

class ToggleVista extends StatelessWidget {
  final BibliotecaControlador controlador;
  
  ToggleVista({super.key, required this.controlador});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controlador,
      builder: (context, _) {
        return IconButton(
          icon: Icon(
            controlador.viewGrid
            ? CupertinoIcons.list_bullet
            : CupertinoIcons.square_grid_2x2,
            color: Colors.white,
          ),
          onPressed: () {
            controlador.alternarVista();
          },
        );
      }
    );
  }
}