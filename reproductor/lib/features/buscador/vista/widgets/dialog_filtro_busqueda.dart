import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../biblioteca/controlador/controlador_biblioteca.dart';
import '../../controlador/controlador_busqueda.dart';

Future<void> mostrarDialogoFiltrosBusqueda(BuildContext context) async {
  final busquedaCtrl = context.read<BusquedaControlador>();
  final bibliotecaCtrl = context.read<BibliotecaControlador>();
  await showDialog(
    context: context,
    builder: (dialogContext) {
      return ListenableBuilder(
        listenable: busquedaCtrl,
        builder: (_, _) {
          return AlertDialog(
            title: const Text('Parámetros de búsqueda'),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: CampoBusqueda.values.map((campo) {
                  return CheckboxListTile(
                    value: busquedaCtrl.estaActivo(campo),
                    title: Text(campo.etiqueta),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    onChanged: (valor) {
                      if (valor != null) {
                        busquedaCtrl.alternarCampo(
                          campo,
                          valor,
                          bibliotecaCtrl.rolas,
                        );
                      }
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              if (busquedaCtrl.tieneFiltrosPersonalizados)
                TextButton(
                  onPressed: () {
                    busquedaCtrl.seleccionarTodos(bibliotecaCtrl.rolas);
                  },
                  child: const Text('Seleccionar todos'),
                ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Listo'),
              ),
            ],
          );
        }
      );
    },
  );
}