import 'package:flutter/material.dart';
import 'package:reproductor/src/rust/api/simple.dart' as rust_api;

Future<void> mostrarDialogoMiembros(
  BuildContext context,
  int idGroup,
  String nombreGrupo,
) async {
  List<rust_api.MiembroDto> miembros =
      await rust_api.obtenerMiembrosGrupo(idGroup: idGroup);

  if (!context.mounted) return;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (contextSB, setStateSB) {
          Future<void> recargarMiembros() async {
            final actualizados =
                await rust_api.obtenerMiembrosGrupo(idGroup: idGroup);
            setStateSB(() => miembros = actualizados);
          }

          return AlertDialog(
            title: Text('Miembros de $nombreGrupo'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: Column(
                children: [
                  Expanded(
                    child: miembros.isEmpty
                        ? const Center(
                            child: Text('Este grupo aún no tiene miembros.'),
                          )
                        : ListView.builder(
                            itemCount: miembros.length,
                            itemBuilder: (_, index) {
                              final m = miembros[index];
                              return ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(m.stageName),
                                subtitle: m.realName != null
                                    ? Text(m.realName!)
                                    : null,
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () async {
                                    await rust_api.eliminarMiembroGrupo(
                                      idPerson: m.idPerson,
                                      idGroup: idGroup,
                                    );
                                    await recargarMiembros();
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text('Añadir Miembro'),
                    onPressed: () async {
                      final todas = await rust_api.obtenerTodasLasPersonas();
                      final idsActuales =
                          miembros.map((m) => m.idPerson).toSet();
                      final disponibles = todas
                          .where((p) => !idsActuales.contains(p.idPerson))
                          .toList();

                      if (!contextSB.mounted) return;

                      final elegida = await showDialog<rust_api.MiembroDto>(
                        context: contextSB,
                        builder: (modalCtx) => AlertDialog(
                          title: const Text('Seleccionar Persona'),
                          content: SizedBox(
                            width: double.maxFinite,
                            height: 250,
                            child: disponibles.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No hay personas registradas disponibles.',
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: disponibles.length,
                                    itemBuilder: (_, i) {
                                      final p = disponibles[i];
                                      return ListTile(
                                        leading:
                                            const Icon(Icons.person_outline),
                                        title: Text(p.stageName),
                                        subtitle: p.realName != null
                                            ? Text(p.realName!)
                                            : null,
                                        onTap: () =>
                                            Navigator.of(modalCtx).pop(p),
                                      );
                                    },
                                  ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(modalCtx).pop(),
                              child: const Text('Cancelar'),
                            ),
                          ],
                        ),
                      );

                      if (elegida != null) {
                        await rust_api.agregarMiembroGrupo(
                          idPerson: elegida.idPerson,
                          idGroup: idGroup,
                        );
                        await recargarMiembros();
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      );
    },
  );
}