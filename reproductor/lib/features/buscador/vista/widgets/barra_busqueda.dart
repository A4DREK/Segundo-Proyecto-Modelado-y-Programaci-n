import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../biblioteca/controlador/controlador_biblioteca.dart';
import '../../controlador/controlador_busqueda.dart';
import 'dialog_filtro_busqueda.dart';

class BarraBusqueda extends StatefulWidget {
  const BarraBusqueda({super.key});

  @override
  State<BarraBusqueda> createState() => _BarraBusquedaState();
}

class _BarraBusquedaState extends State<BarraBusqueda> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _construirHint(BusquedaControlador busquedaCtrl) {
    if (!busquedaCtrl.tieneFiltrosPersonalizados) {
      return 'Buscar en toda la biblioteca...';
    }
    final nombres =
        busquedaCtrl.camposActivos.map((c) => c.etiqueta).join(', ');
    return 'Buscar por: $nombres...';
  }

  @override
  Widget build(BuildContext context) {
    final bibliotecaCtrl = context.read<BibliotecaControlador>();
    final busquedaCtrl = context.watch<BusquedaControlador>();

    return Material(
      type: MaterialType.transparency,
      child: TextField(
        controller: _ctrl,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        cursorColor: Colors.white,
        onChanged: (valor) {
          busquedaCtrl.actualizarBusqueda(valor, bibliotecaCtrl.rolas);
        },
        decoration: InputDecoration(
          hintText: _construirHint(busquedaCtrl),
          hintStyle: const TextStyle(color: Colors.white60, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.08),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busquedaCtrl.consulta.isNotEmpty)
                IconButton(
                  tooltip: 'Limpiar búsqueda',
                  icon: const Icon(Icons.clear, color: Colors.white70),
                  onPressed: () {
                    _ctrl.clear();
                    busquedaCtrl.limpiar(bibliotecaCtrl.rolas);
                  },
                ),
              IconButton(
                tooltip: 'Filtrar parámetros de búsqueda',
                icon: Icon(
                  Icons.tune,
                  color: busquedaCtrl.tieneFiltrosPersonalizados
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white70,
                ),
                onPressed: () => mostrarDialogoFiltrosBusqueda(context),
              ),
            ],
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
      ),
    );
      
  }
}