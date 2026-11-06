//Está será la segunda vista, que nada más será mostrar los álbumes en forma de lista y ya 

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:reproductor/features/biblioteca/controlador/controlador_biblioteca.dart';

class ListaCanciones extends StatelessWidget {
  final List<CancionTemporal> canciones;

  const ListaCanciones({super.key, required this.canciones});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: canciones.length,
        itemBuilder: (context, index) {
          final cancion = canciones[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 15.0),
            child: Row(
              children: [
                //Esta parte modificarla luego para la parte de los archivos ID3
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(cancion.link, width: 50, height: 50, fit: BoxFit.cover),
                ),
                const SizedBox(width: 15,),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cancion.cancion,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4,),
                      Text(
                        cancion.artista,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(CupertinoIcons.play_circle_fill, color: Colors.white54),
              ],
            ), 
          );
        },
      ),
    );
  }
}