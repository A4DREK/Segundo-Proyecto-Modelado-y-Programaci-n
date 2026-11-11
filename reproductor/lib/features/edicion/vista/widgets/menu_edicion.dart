import 'package:flutter/material.dart';
import '../../../biblioteca/controlador/controlador_biblioteca.dart';
//import 'dialog_editar_album.dart';
import 'dialog_editar_cancion.dart';

void mostrarMenuEdicion(BuildContext context, Rola cancion, BibliotecaControlador controlador) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.music_note),
              title: const Text('Editar datos del track'),
              onTap: () {
                Navigator.pop(context);
                mostrarDialogoEdicionCancion(context, cancion, controlador);
              }
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Editar información del artista'),
              onTap: () {
                Navigator.pop(context);
                //Parte del archivo de dialog_editar_artista(aún no se crea lol)
              }
            ),
          ],
        ),
      );
    }
  );
}