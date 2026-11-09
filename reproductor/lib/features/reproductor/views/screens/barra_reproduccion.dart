import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controlador/controlador_reproductor.dart';


class BarraReproductor extends StatelessWidget {
  const BarraReproductor({super.key});

  @override
  Widget build(BuildContext context) {
    
    final controlador = context.watch<ReproductorControlador>();
    final cancion = controlador.cancionActual;

    double maxVal = controlador.duracionTotal.inMilliseconds.toDouble();
    double currentVal = controlador.minActual.inMilliseconds.toDouble();
    if (maxVal <= 0.0) maxVal = 1.0; 
    if (currentVal > maxVal) currentVal = maxVal;
    
    return Container(
      height: 85,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF181818), // Fondo oscuro sólido
        border: Border(
          top: BorderSide(color: Colors.white10, width: 1), // Línea sutil superior
        ),
      ),
      child: Row(
        children: [
          //(Aquí ira la parte para que muestre la portada del ID3V2")
        SizedBox(
          width: 250,
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(6),
                  //Aquí ya se hace el render del archivo y que, en efecto, tenga una portada
                  image: cancion?.frontCover != null 
                    ? DecorationImage(
                        image: MemoryImage(cancion!.frontCover!),
                        fit: BoxFit.cover,
                      ) 
                    : null,
                ),
                child: cancion?.frontCover == null 
                  ? const Icon(CupertinoIcons.music_note, color: Colors.white54, size: 24)
                  : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //Aquí es donde se hace el render del nombre de la canción y de los performers
                    Text(
                      cancion?.title ?? "Sin selección",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cancion?.performerName ?? "--",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

          // Controles 
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Fila de botones estáticos
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      //Botón de reversa
                      GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => controlador.anterior(),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Icon(CupertinoIcons.backward_fill, size: 20, color: Colors.white),
                            ),
                          ),                      
                          const SizedBox(width: 20),

                      //Botón de PLay/Pausa
                      GestureDetector(
                        behavior: HitTestBehavior.opaque, 
                        onTap: () {
                          controlador.alternarReproduccion();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: Icon(
                            controlador.reproduciendo 
                              ? CupertinoIcons.pause_fill 
                              : CupertinoIcons.play_fill, 
                            size: 28, 
                            color: Colors.white
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => controlador.siguiente(),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: Icon(CupertinoIcons.forward_fill, size: 20, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Text(formateoTiempo(controlador.minActual), style: const TextStyle(color: Colors.white60, fontSize: 11)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Material(
                          type: MaterialType.transparency,
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                              activeTrackColor: Colors.white,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: Colors.white,
                            ),
                            child: Slider(
                              min: 0.0,
                              max: maxVal,
                              value: currentVal,
                              onChanged: (val) {
                                controlador.buscarPosicion(Duration(milliseconds: val.toInt()));
                              }
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(formateoTiempo(controlador.duracionTotal), style: const TextStyle(color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Volumen 
          SizedBox(
            width: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(CupertinoIcons.speaker_fill, color: Colors.white60, size: 16),
                Expanded(
                  child: Material(
                    type: MaterialType.transparency,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: controlador.volumen,
                        onChanged: (val) => controlador.setVolumen(val), 
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //Método auxiliar para poder mostrar el tiempo en la línea de tiempo 
  String formateoTiempo(Duration duracion) {
    final minutos = duracion.inMinutes.remainder(60).toString();
    final segundos = duracion.inSeconds.remainder(60).toString().padLeft(2, '0');

    return "$minutos:$segundos";
  } 
}