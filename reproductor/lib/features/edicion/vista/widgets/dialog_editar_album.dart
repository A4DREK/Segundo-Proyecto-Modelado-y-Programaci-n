import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reproductor/src/rust/api/simple.dart' as rust_api;
import '../../../biblioteca/controlador/controlador_biblioteca.dart';

Future<void> mostrarDialogoEdicionArtista(
  BuildContext contextPantalla, 
  int idPerformer,
  int tipoInicial,
  String? nombreInicial, // 0 = Persona, 1 = Grupo, 2 = Unknown
) async {
  final bibliotecaCtrl = contextPantalla.read<BibliotecaControlador>();

  int tipoSeleccionado = tipoInicial == 2 ? 0 : tipoInicial;

  final nombreCtrl = TextEditingController(text: nombreInicial ?? ''); 
  final realNameCtrl = TextEditingController();
  final fecha1Ctrl = TextEditingController(); 
  final fecha2Ctrl = TextEditingController(); 

  //Esta parte es para cargar los datos del artista (person o group)
  if (tipoInicial == 0 || tipoInicial == 1) {
    try {
      final detalle = await rust_api.obtenerDetalleArtista(
        idPerformer: idPerformer,
        artistType: tipoInicial,
      );
      if (detalle.nombre != null && detalle.nombre!.isNotEmpty) {
        nombreCtrl.text = detalle.nombre!;
      }
      realNameCtrl.text = detalle.realName ?? '';
      fecha1Ctrl.text = detalle.fechaInicio ?? '';
      fecha2Ctrl.text = detalle.fechaFin ?? '';
    } catch (e) {
      debugPrint('Error cargando detalles del artista: $e');
    }
  }

  if (!contextPantalla.mounted) return;

  final formKey = GlobalKey<FormState>();

  await showDialog(
    context: contextPantalla,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Editar Información del Artista'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (tipoInicial == 2) ...[
                      const Text('El tipo de artista es desconocido. Selecciona uno:'),
                      RadioGroup<int>(
                        groupValue: tipoSeleccionado,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => tipoSeleccionado = value);
                          }
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RadioListTile<int>(
                              value: 0,
                              title: Text('Persona'),
                            ),
                            RadioListTile<int>(
                              value: 1,
                              title: Text('Grupo'),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (tipoSeleccionado == 0) ...[
                      TextFormField(
                        controller: nombreCtrl,
                        decoration: const InputDecoration(labelText: 'Stage Name (Nombre Artístico)'),
                        validator: (value) => value == null || value.trim().isEmpty 
                            ? 'El nombre es obligatorio' : null,
                      ),
                      TextFormField(
                        controller: realNameCtrl,
                        decoration: const InputDecoration(labelText: 'Real Name (Nombre Real)'),
                      ),
                      TextFormField(
                        controller: fecha1Ctrl,
                        decoration: const InputDecoration(labelText: 'Birth Date (YYYY-MM-DD)'),
                      ),
                      TextFormField(
                        controller: fecha2Ctrl,
                        decoration: const InputDecoration(labelText: 'Death Date (YYYY-MM-DD)'),
                      ),
                    ],

                    if (tipoSeleccionado == 1) ...[
                      TextFormField(
                        controller: nombreCtrl,
                        decoration: const InputDecoration(labelText: 'Group Name (Nombre del Grupo)'),
                        validator: (value) => value == null || value.trim().isEmpty 
                            ? 'El nombre es obligatorio' : null,
                      ),
                      TextFormField(
                        controller: fecha1Ctrl,
                        decoration: const InputDecoration(labelText: 'Start Date (YYYY-MM-DD)'),
                      ),
                      TextFormField(
                        controller: fecha2Ctrl,
                        decoration: const InputDecoration(labelText: 'End Date (YYYY-MM-DD)'),
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.people),
                        label: const Text('Gestionar Miembros'),
                        onPressed: () {
                          // TODO: Implementar vista de miembros
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    String? valOrNull(String text) => text.trim().isEmpty ? null : text.trim();
                    final nuevoNombre = valOrNull(nombreCtrl.text);

                    try {
                      if (tipoInicial == 2 && tipoSeleccionado == 0) {
                        await rust_api.convertirArtistaPerson(
                          idPerformer: idPerformer,
                          stageName: nuevoNombre,
                          realName: valOrNull(realNameCtrl.text),
                          birthDate: valOrNull(fecha1Ctrl.text),
                          deathDate: valOrNull(fecha2Ctrl.text),
                        );
                      } else if (tipoInicial == 2 && tipoSeleccionado == 1) {
                        await rust_api.convertirArtistaGroup(
                          idPerformer: idPerformer,
                          name: nuevoNombre,
                          startDate: valOrNull(fecha1Ctrl.text),
                          endDate: valOrNull(fecha2Ctrl.text),
                        );
                      } else if (tipoSeleccionado == 0) {
                        await rust_api.actualizarPersona(
                          idPerson: idPerformer, 
                          nombre: nuevoNombre, 
                          nuevoStageName: nuevoNombre,
                          nuevoRealName: valOrNull(realNameCtrl.text),
                          nuevoBirthDate: valOrNull(fecha1Ctrl.text),
                          nuevoDeathDate: valOrNull(fecha2Ctrl.text),
                        );
                      } else if (tipoSeleccionado == 1) {
                        await rust_api.actualizarGrupo(
                          idGroup: idPerformer, 
                          nuevoName: nuevoNombre,
                          nuevaStartDate: valOrNull(fecha1Ctrl.text),
                          nuevaEndDate: valOrNull(fecha2Ctrl.text),
                        );
                      }

                      await bibliotecaCtrl.cargarDatosBD();

                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    } catch (e) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text('Error guardando: $e')),
                        );
                      }
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