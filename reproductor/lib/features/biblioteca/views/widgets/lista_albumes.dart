//Está será la segunda vista, que nada más será mostrar los álbumes en forma de lista y ya 

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:reproductor/features/biblioteca/controlador/controlador_biblioteca.dart';
import '../../../reproductor/controlador/controlador_reproductor.dart';

class ListaCanciones extends StatelessWidget {
  final List<Rola> canciones;

  const ListaCanciones({super.key, required this.canciones});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: canciones.length,
        itemBuilder: (context, index) {
          final cancion = canciones[index];

          if(cancion.frontCover == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<BibliotecaControlador>().cargarPortada(index);
            });
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 15.0),
            child: Row(
              children: [
                //Esta parte modificarla luego para la parte de los archivos ID3
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: cancion.frontCover != null 
                    ? Image.memory(
                        cancion.frontCover!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover
                      )
                      : Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[850],
                        child: const Icon(
                          CupertinoIcons.music_albums,
                          color: Colors.white38,
                          size: 24,
                        ),
                      ),
                ),
                const SizedBox(width: 15,),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cancion.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4,),
                      Text(
                        cancion.performerName,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque, 
                  onTap: () {
                    context.read<ReproductorControlador>().reproducirPLaylist(canciones, index);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8.0), 
                    child: Icon(CupertinoIcons.play_circle_fill, color: Colors.white54, size: 28),
                  ),
                ),
              ],
            ), 
          );
        },
    );
  }
}