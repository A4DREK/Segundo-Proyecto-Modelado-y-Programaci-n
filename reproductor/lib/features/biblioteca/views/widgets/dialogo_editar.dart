import 'package:flutter/material.dart';
import '../../controlador/controlador_biblioteca.dart';

Future<void> mostrarDialogoEdicion(
  BuildContext context, 
  Rola cancion, 
  BibliotecaControlador controlador,
) async {
  final tituloCtrl = TextEditingController(text: cancion.title);
  final trackCtrl = TextEditingController(text: cancion.track ?? '');
  final yearCtrl = TextEditingController(text: cancion.year?.toString() ?? '');
  final generoCtrl = TextEditingController(text: cancion.genre ?? '');

  final formKey = GlobalKey<FormState>();

  await showDialog(
    context: context,
    builder: (context) {
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
                final trackValidado = int.tryParse(trackCtrl.text.trim());
                final yearValidado = int.tryParse(yearCtrl.text.trim());

                await controlador.editarCancion(
                  idRola: cancion.idRola,
                  titulo: tituloCtrl.text.trim(),
                  track: trackValidado,
                  year: yearValidado,
                  genero: generoCtrl.text.trim().isEmpty ? null : generoCtrl.text.trim(),
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
}