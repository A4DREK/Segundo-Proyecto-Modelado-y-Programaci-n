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

    final BibliotecaControlador _controlador = BibliotecaControlador();
    //Parte de todo este código es recuperado de: https://github.com/tayormi/apple_music/blob/main/lib/pages/main_page.dart
    return Padding(
      padding: const EdgeInsets.only(top: 40.0, right: 40, left: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //Parte Superior donde está la parte de buscar (falta implementar el minero)
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

          //Parte donde viene el título y los botones 
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
                children:[
                  ListenableBuilder(
                    listenable: _controlador,
                    builder: (context, child) {
                      return IconButton(
                        icon: const Icon(
                          CupertinoIcons.add_circled_solid,
                          color: Colors.white,
                        ),
                        onPressed: _controlador.miner
                            ? null
                            : () => _controlador.buscarDirectorio(),
                      );
                    }
                  ),
                  const SizedBox(width: 15,),
                  ToggleVista(controlador: _controlador),
                ], 
              )
            ],
          ),
          const SizedBox(
            height: 40,
          ),

          //Parte donde está la vista de grid/lista, 
          Expanded(
            child: ListenableBuilder(
              listenable: _controlador,
              builder: (context, child) {
                if(_controlador.miner) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16,),
                        Text(
                          'Minando directorio',
                          style: TextStyle(color: Colors.white60, fontSize: 14),
                        )
                      ],
                    ),
                  );
                }

                if(_controlador.charged) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white)
                  );
                }

                if(_controlador.rolas.isEmpty){
                  return Center(
                    child:Column(
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
                          'Selecciona un directorio de música',
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
                          onPressed: () => _controlador.buscarDirectorio(),
                          icon: const Icon(CupertinoIcons.folder_badge_plus),
                          label: const Text('Seleccionar Carpeta'),
                        ),
                      ],
                    ),
                  );
                }
                
                return _controlador.viewGrid
                  ? GridAlbumes(canciones: _controlador.rolas)
                  : ListaCanciones(canciones: _controlador.rolas);
              }
            )
          )
        ],
      ),
    );
  }
}