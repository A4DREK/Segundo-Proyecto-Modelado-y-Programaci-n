import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../biblioteca/controlador/controlador_biblioteca.dart';

class ReproductorControlador extends ChangeNotifier {

  final AudioPlayer _audioPlayer = AudioPlayer();

  Rola? cancionActual;
  bool reproduciendo = false;
  double volumen = 0.5;

  //Se inicializa el escucha para la interfaz 
  ReproductorControlador (){
    _audioPlayer.setVolume(volumen);

    _audioPlayer.playerStateStream.listen((state) {
      reproduciendo = state.playing;
      notifyListeners();
    });
  }

  Future<void> reproducirCancion(Rola cancion) async {
    
    try{
      cancionActual = cancion;
      notifyListeners();
      
      await _audioPlayer.setFilePath(cancion.path);
      await _audioPlayer.play();
    }catch(e) {
      debugPrint("Hubo un error en la reproducción del audio: [$e]");
    }

  }

  Future<void> alternarReproduccion() async {
    if(cancionActual == null) return;

    if(_audioPlayer.playing) {
      await _audioPlayer.pause();
      reproduciendo = false;
      notifyListeners();
    }else {
      await _audioPlayer.play();
      reproduciendo = true;
      notifyListeners();
    }

  }

  Future<void> setVolumen(double nuevoVolumen) async{
    volumen = nuevoVolumen.clamp(0.0,1.0);
    await _audioPlayer.setVolume(volumen);
    notifyListeners();
  }

  //Este es para liberar la memoria al cerrar la aplicación 
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}