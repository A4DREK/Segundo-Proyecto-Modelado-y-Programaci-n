//En esta parte del código irá el como debe de verse los álbumes de forma que 
//pueda estar en un grid tipo Apple Music o así 

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:reproductor/features/biblioteca/controlador/controlador_biblioteca.dart';
import 'package:reproductor/features/reproductor/controlador/controlador_reproductor.dart';

class GridAlbumes extends StatelessWidget {
  final List<Rola> canciones;

  const GridAlbumes({super.key, required this.canciones});

  @override
  Widget build(BuildContext context) {

    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 400,
          childAspectRatio: 0.8,
          crossAxisSpacing: 50,
          mainAxisSpacing: 40),
      itemCount: canciones.length, 
      itemBuilder: (BuildContext context, int index) {
        final card = canciones[index];

        if(card.frontCover == null ){
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<BibliotecaControlador>().cargarPortada(index);
          });
        }

        return GestureDetector(
          onTap: () {
            context.read<ReproductorControlador>().reproducirCancion(card);
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: Colors.grey[900],
                //Parte para cargar la portada del album 
                image: card.frontCover != null
                    ? DecorationImage(
                        fit: BoxFit.cover,
                        image: MemoryImage(card.frontCover!),
                      )
                    : null,
                borderRadius: BorderRadius.circular(20)),
            child: Stack(
              children: [
                if (card.frontCover == null)
                  const Center(
                    child: Icon(
                      Icons.music_note_rounded,
                      size: 64,
                      color: Colors.white24,
                    ),
                  ),
                Column(
                  children: [
                    const Spacer(),
                    FrostedGlassBox(
                      height: 100,
                      width: MediaQuery.of(context).size.width,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20)),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                card.title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                card.performerName,
                                style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w300),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

//Parte recuperada de: https://github.com/tayormi/apple_music/blob/main/lib/pages/main_page.dart
class FrostedGlassBox extends StatelessWidget {
  final double width, height;
  final Widget child;

  const FrostedGlassBox(
      {super.key,
      required this.width,
      required this.height,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 7.0,
                sigmaY: 7.0,
              ),
              child: SizedBox(
                  width: width, height: height, child: const Text(" ")),
            ),
            Container(
              decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 30,
                        offset: const Offset(2, 2))
                  ],
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.5),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                      stops: const [
                        0.0,
                        1.0,
                      ])),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}


/* 

*/