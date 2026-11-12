import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reproductor/features/edicion/vista/widgets/dialog_editar_album.dart';
import '../../../biblioteca/controlador/controlador_biblioteca.dart';
import 'dialog_editar_cancion.dart';

void mostrarMenuEdicion(BuildContext contextScreen, Rola cancion) {
  showModalBottomSheet(
    context: contextScreen,
    builder: (contextMenu) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.music_note),
              title: const Text('Editar datos del track'),
              onTap: () {
                Navigator.pop(contextMenu);
                mostrarDialogoEdicionCancion(contextScreen, cancion);
              }
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Editar información del artista'),
              onTap: () {
                Navigator.pop(contextMenu);
                //Parte del archivo de dialog_editar_artista(aún no se crea lol)
                final bibliotecaCtrl = contextScreen.read<BibliotecaControlador>();
                final cancionActualizada = bibliotecaCtrl.rolas.firstWhere(
                  (r) => r.idRola == cancion.idRola,
                  orElse: () => cancion,
                );
                mostrarDialogoEdicionArtista(
                  contextScreen,
                  cancionActualizada.idPerformer,
                  cancionActualizada.tipoArtista,
                  cancionActualizada.performerName,
                );
              }
            ),
          ],
        ),
      );
    }
  );
}