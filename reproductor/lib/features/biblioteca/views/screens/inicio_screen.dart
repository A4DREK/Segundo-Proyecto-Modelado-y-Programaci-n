//Parte donde irá la parte del "home-screen"

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:reproductor/features/biblioteca/controlador/controlador_biblioteca.dart';
import 'package:reproductor/features/biblioteca/views/widgets/grid_albumes.dart';
import 'package:reproductor/features/biblioteca/views/widgets/lista_albumes.dart';
import 'package:reproductor/features/biblioteca/views/widgets/toggle_vista.dart';

class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override 
  Widget build(BuildContext context){
    return ChangeNotifierProvider(
      create: (_) => BibliotecaControlador()..cargarDatosBD(),
      child: const _InicioScreenState(),
  );
  }
}

class _InicioScreenState extends StatelessWidget{
  
  const _InicioScreenState();

@override
  Widget build(BuildContext context) {
    
    final controlador = context.watch<BibliotecaControlador>();

    return Padding(
      padding: const EdgeInsets.only(top: 40.0, right: 40, left: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de búsqueda superior
          const SizedBox(
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.search,
                  color: Colors.white,
                ),
                SizedBox(width: 10),
                Text(
                  'Buscar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Título de la sección y botones de acción
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Escuchando Ahora',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Agregar carpeta de música',
                    icon: const Icon(
                      CupertinoIcons.add_circled_solid,
                      color: Colors.white,
                    ),
                    onPressed: controlador.miner
                        ? null
                        : () => controlador.buscarDirectorio(),
                  ),
                  const SizedBox(width: 15),
                  ToggleVista(controlador: controlador),
                ], 
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Contenido principal (Minando, Cargando, Vacío o Lista/Grid)
          Expanded(
            child: _construirContenido(controlador),
          ),
        ],
      ),
    );
  }

  Widget _construirContenido(BibliotecaControlador controlador) {
    if (controlador.miner) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Minando directorio...',
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (controlador.charged) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (controlador.rolas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.music_albums,
              size: 64,
              color: Colors.white38,
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay canciones en el directorio',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecciona un directorio de música para comenzar',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white10,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: () => controlador.buscarDirectorio(),
              icon: const Icon(CupertinoIcons.folder_badge_plus),
              label: const Text('Seleccionar Carpeta'),
            ),
          ],
        ),
      );
    }

    return controlador.viewGrid
        ? GridAlbumes(canciones: controlador.rolas)
        : ListaCanciones(canciones: controlador.rolas);
  }
}