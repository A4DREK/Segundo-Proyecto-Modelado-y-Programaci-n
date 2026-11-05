//Parte donde irá la parte del "home-screen"

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:reproductor/features/biblioteca/controlador/controlador_biblioteca.dart';
import 'package:reproductor/features/biblioteca/views/widgets/grid_albumes.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override 
  State<InicioScreen> createState() => _InicioScreenState();

}

class _InicioScreenState extends State<InicioScreen> {
  final BibliotecaControlador _controlador = BibliotecaControlador();
  
  @override
  void initState() {
    super.initState();
    _controlador.cargarDatos();
  }

  @override
  Widget build(BuildContext context) {

    //Parte de todo este código es recuperado de: https://github.com/tayormi/apple_music/blob/main/lib/pages/main_page.dart
    return Padding(
      padding: const EdgeInsets.only(top: 40.0, right: 40, left: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            child: Row(
              children: const [
                Icon(
                  CupertinoIcons.search,
                  color: Colors.white,
                ),
                SizedBox(
                  width: 10,
                ),
                Text(
                  'Buscar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 40,
          ),
          const Text(
            'Escuchando ahora',
            style: TextStyle(
              color: Colors.white,
              fontSize:16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(
            height: 40,
          ),
          //Falta agregar lo de la grid view

          Expanded(
            child: ListenableBuilder(
              listenable: _controlador,
              builder: (context, child) {
                if(_controlador.cargando) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if(_controlador.albums.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay canciones en la biblioteca',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return GridAlbumes(canciones: _controlador.albums);
              }
            )
          )
        ],
      ),
    );
  }
}