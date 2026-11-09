import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../biblioteca/controlador/controlador_biblioteca.dart';

class ReproductorControlador extends ChangeNotifier {

  final AudioPlayer _audioPlayer = AudioPlayer();

  Rola? cancionActual;
  bool reproduciendo = false;
  double volumen = 0.5;
  List<Rola> playlistActual = [];

  Duration minActual = Duration.zero;
  Duration duracionTotal = Duration.zero;

  //Se inicializa el escucha para la interfaz 
  ReproductorControlador (){
    _audioPlayer.setVolume(volumen);

    _audioPlayer.playerStateStream.listen((state) {
      reproduciendo = state.playing;

      if(state.processingState == ProcessingState.completed) {
        reproduciendo = false;
        minActual = Duration.zero;
      }
      notifyListeners();
    });

    _audioPlayer.positionStream.listen((posicion) {
      minActual = posicion;
      notifyListeners();
    });

    _audioPlayer.durationStream.listen((duracion) {
      duracionTotal = duracion ?? Duration.zero;
      notifyListeners();
    });

    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && playlistActual.isNotEmpty && index < playlistActual.length) {
        cancionActual = playlistActual[index];
        notifyListeners();
      }
    });
  }

  // Future<void> reproducirCancion(Rola cancion) async {
    
  //   try{
  //     cancionActual = cancion;
  //     notifyListeners();
      
  //     await _audioPlayer.setFilePath(cancion.path);
  //     await _audioPlayer.play();
  //   }catch(e) {
  //     debugPrint("Hubo un error en la reproducción del audio: [$e]");
  //   }

  // }

  Future<void> reproducirPLaylist(List<Rola> canciones, int indiceActual) async {
    try{
      playlistActual = canciones;
      cancionActual = canciones[indiceActual];
      notifyListeners();

      final fuenteAudio = canciones.map(
        (cancion) => AudioSource.uri(Uri.file(cancion.path))
      ).toList();

      await _audioPlayer.setAudioSources(
        fuenteAudio,
        initialIndex: indiceActual,
      );

      await _audioPlayer.play();

    }catch(e){
      debugPrint("Error en la reproducción: [$e]");
    }
  }

  Future<void> alternarReproduccion() async {
    if(cancionActual == null) return;

    if(_audioPlayer.playing) {
      await _audioPlayer.pause();
    }else {
      await _audioPlayer.play();
    }

  }

  Future<void> siguiente() async {
    if (_audioPlayer.hasNext) {
      await _audioPlayer.seekToNext();
    }
  }

  Future<void> anterior() async {
    if (_audioPlayer.hasPrevious) {
      await _audioPlayer.seekToPrevious();
    } else {
      // Si es la primera canción, la reinicia al segundo 0
      await _audioPlayer.seek(Duration.zero);
    }
  }

  Future<void> setVolumen(double nuevoVolumen) async{
    volumen = nuevoVolumen.clamp(0.0,1.0);
    await _audioPlayer.setVolume(volumen);
    notifyListeners();
  }

  Future<void> buscarPosicion(Duration posicion) async {
    await _audioPlayer.seek(posicion);
  }

  //Este es para liberar la memoria al cerrar la aplicación 
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}