//En esta parte del código irá el como debe de verse los álbumes de forma que 
//pueda estar en un grid tipo Apple Music o así 

import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:reproductor/features/biblioteca/controlador/controlador_biblioteca.dart';

class GridAlbumes extends StatelessWidget {
  final List<CancionTemporal> canciones;

  const GridAlbumes({super.key, required this.canciones});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              childAspectRatio: 0.8,
              crossAxisSpacing: 50,
              mainAxisSpacing: 40),
          itemCount: canciones.length, 
          itemBuilder: (BuildContext context, int index) {
            final card = canciones[index];
            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: Colors.grey[900],
                  image: DecorationImage(
                      fit: BoxFit.cover,
                      image: NetworkImage(card.link)), //Cambiar esta parte para que no sea con internet pq wtf
                  borderRadius: BorderRadius.circular(20)),
              child: Column(
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
                              card.cancion,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              card.artista,
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
            );
          },
        ),
      ),
    );
  }
}

//Parte recuperada de: https://github.com/tayormi/apple_music/blob/main/lib/pages/main_page.dart
class FrostedGlassBox extends StatelessWidget {
  final double width, height;
  final Widget child;

  const FrostedGlassBox(
      {Key? key,
      required this.width,
      required this.height,
      required this.child})
      : super(key: key);

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
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 30,
                        offset: const Offset(2, 2))
                  ],
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.5),
                        Colors.white.withOpacity(0.1),
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