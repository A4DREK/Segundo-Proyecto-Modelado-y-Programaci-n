import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BarraReproductor extends StatelessWidget {
  const BarraReproductor({super.key});

  @override
  Widget build(BuildContext context) {
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
          // Información Falsa (Aquí ira la parte para que muestre la portada del ID3V2")
          SizedBox(
            width: 250,
            child: Row(
              children: [
                // Carátula Falsa
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(CupertinoIcons.music_note, color: Colors.white54, size: 24),
                ),
                const SizedBox(width: 12),
                // Textos
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Canción de Prueba",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Artista Desconocido",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white60, fontSize: 12),
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
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.backward_fill, size: 20, color: Colors.white),
                      SizedBox(width: 20),
                      Icon(CupertinoIcons.play_fill, size: 28, color: Colors.white),
                      SizedBox(width: 20),
                      Icon(CupertinoIcons.forward_fill, size: 20, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Text("0:00", style: TextStyle(color: Colors.white60, fontSize: 11)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          alignment: Alignment.centerLeft,
                          // Pedacito de progreso "fake"
                          child: Container(
                            width: 50, 
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text("-:--", style: TextStyle(color: Colors.white60, fontSize: 11)),
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
                  // El Material transparente salva la app de crashear en macOS
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
                        value: 0.3, // 30% estático
                        onChanged: (val) {}, // No hace nada
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
}