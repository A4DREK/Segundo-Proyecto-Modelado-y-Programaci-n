import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import '../../../edicion/controlador/controlador_edicion.dart';
import '../../../biblioteca/controlador/controlador_biblioteca.dart';

Future<void> mostrarDialogoEdicionCancion(
  BuildContext context, 
  Rola cancion, 
) async {
  final bibliotecaCtrl = context.read<BibliotecaControlador>();
  final edicionCtrl = context.read<EdicionControlador>();

  final tituloCtrl = TextEditingController(text: cancion.title);
  final artistaCtrl = TextEditingController(text: cancion.performerName);
  final albumCtrl = TextEditingController(text: cancion.albumName);
  final trackCtrl = TextEditingController(text: cancion.track ?? '');
  final yearCtrl = TextEditingController(text: cancion.year?.toString() ?? '');
  final generoCtrl = TextEditingController(text: cancion.genre ?? '');

  final formKey = GlobalKey<FormState>();

  bool actualizarArtistaGeneral = false;
  bool actualizarAlbumGeneral = false;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder:(contextSB, setState) {
          return AlertDialog(
            title: const Text('Editar Canción'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: tituloCtrl,
                      decoration: const InputDecoration(labelText: 'Título'),
                      validator: (value) => value == null || value.trim().isEmpty 
                          ? 'El título no puede estar vacío' 
                          : null,
                    ),
                    TextFormField(
                      controller: artistaCtrl,
                      decoration: const InputDecoration(labelText: 'Artista'),
                      validator: (value) => value == null || value.trim().isEmpty 
                          ? 'El artista no puede estar vacío' 
                          : null,
                    ),
                    // Checkbox para el artista
                    CheckboxListTile(
                      title: const Text('Aplicar artista a todas las pistas del álbum', style: TextStyle(fontSize: 13)),
                      value: actualizarArtistaGeneral,
                      controlAffinity: ListTileControlAffinity.leading, 
                      contentPadding: EdgeInsets.zero, 
                      onChanged: (bool? valor) {
                        setState(() {
                          actualizarArtistaGeneral = valor ?? false;
                        });
                      },
                    ),
                    TextFormField(
                      controller: albumCtrl,
                      decoration: const InputDecoration(labelText: 'Álbum'),
                      validator: (value) => value == null || value.trim().isEmpty 
                          ? 'El álbum no puede estar vacío' 
                          : null,
                    ),
                    // Checkbox para el álbum
                    CheckboxListTile(
                      title: const Text('Renombrar el álbum para todas las pistas', style: TextStyle(fontSize: 13)),
                      value: actualizarAlbumGeneral,
                      controlAffinity: ListTileControlAffinity.leading, 
                      contentPadding: EdgeInsets.zero, 
                      onChanged: (bool? valor) {
                        setState(() {
                          actualizarAlbumGeneral = valor ?? false;
                        });
                      },
                    ),
                    TextFormField(
                      controller: trackCtrl,
                      decoration: const InputDecoration(labelText: 'Track (Número)'),
                      keyboardType: TextInputType.number,
                    ),
                    TextFormField(
                      controller: yearCtrl,
                      decoration: const InputDecoration(labelText: 'Año'),
                      keyboardType: TextInputType.number,
                    ),
                    TextFormField(
                      controller: generoCtrl,
                      decoration: const InputDecoration(labelText: 'Género'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final yearValidado = int.tryParse(yearCtrl.text.trim());

                    final int index = bibliotecaCtrl.rolas.indexWhere((r) => r.idRola == cancion.idRola);

                    // Enviar variables al controlador
                    await edicionCtrl.editarCancion(
                      bibliotecaCtrl: bibliotecaCtrl,
                      index: index,
                      idRola: cancion.idRola,
                      nuevoTitulo: tituloCtrl.text.trim(),
                      nuevoArtista: artistaCtrl.text.trim(),
                      nuevoAlbum: albumCtrl.text.trim(), 
                      actualizarArtista: actualizarArtistaGeneral,
                      actualizarAlbum: actualizarAlbumGeneral,
                      nuevoTrack: trackCtrl.text.trim(), 
                      nuevoYear: yearValidado,
                      nuevoGenero: generoCtrl.text.trim().isEmpty ? null : generoCtrl.text.trim(), 
                    );

                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      );
    },
  );
}