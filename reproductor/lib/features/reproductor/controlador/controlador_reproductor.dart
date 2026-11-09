import 'package:flutter/material.dart';
import '../../biblioteca/controlador/controlador_biblioteca.dart';

class ReproductorControlador extends ChangeNotifier {
  Rola? cancionActual;
  bool reproduciendo = false;
  double volumen = 0.5;

  void reproducirCancion(Rola cancion) {
    cancionActual = cancion;
    reproduciendo = true;

    //Futura implementación de la biblioteca del audio(cambiar a Future<void> sdfsd async)
    notifyListeners();
  }

  void alternarReproduccion() {
    if(cancionActual != null) {
      reproduciendo = !reproduciendo;
      notifyListeners();
    }
  }

  void setVolumen(double nuevoVolumen) {
    volumen = nuevoVolumen;
    //También falta la implementación de la biblioteca de audio

    notifyListeners();
  }
}