import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:reproductor/src/rust/api/simple.dart' as rust_api;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Rola {
  final int idRola;
  final String path;
  final String title;
  final String performerName;
  final String albumName;
  final String? artistAlbum;
  final int? year;
  final String? track;
  final int? discNum;
  final String? genre;
  final String? comment;
  final String? compositor;
  final String? originalArtist;
  Uint8List? frontCover;
  Uint8List? artistPortrait;

  Rola({
    required this.idRola,
    required this.path,
    required this.title,
    required this.performerName,
    required this.albumName,
    this.artistAlbum,
    this.year,
    this.track,
    this.discNum,
    this.genre,
    this.comment,
    this.compositor,
    this.originalArtist,
    this.frontCover,
    this.artistPortrait,
  });

  factory Rola.desdeDto(rust_api.RolaDto dto) {
    return Rola(
      idRola: dto.idRola.toInt(),
      title: dto.titulo,
      performerName: dto.artista.isNotEmpty? dto.artista : 'Artista Desconocido', //Este y el siguiente se deben de actualizar
      albumName: dto.album.isNotEmpty? dto.album : 'Álbum Desconocido',
      path: dto.path,
      track: dto.track,
      year: dto.year,
      genre: dto.genre,
    );
  }

}

class BibliotecaControlador extends ChangeNotifier {
  List<Rola> rolas = [];
  bool charged = false;
  bool viewGrid = true;
  bool miner = false;
  String? rutaMusica;

  final Set<int> _portadasSolicitadas = {};

  bool get bibliotecaVacia => !charged && rolas.isEmpty;

  void alternarVista() {
    viewGrid = !viewGrid;
    notifyListeners();
  }

  //Consulta la base de datos generada por el minero 
  Future<void> cargarDatosBD() async {
    charged = true;
    notifyListeners();
    
    try {
      final dtos = await rust_api.obtenerRolasBd();
      rolas = dtos.map((dto) => Rola.desdeDto(dto)).toList();
    } catch(e) {
      debugPrint("Error en la consulta de base de datos: $e");
    } finally {
      charged = false;
      notifyListeners();
    }
  }

  //Muestra el buscador para poder seleccionar el directorio con la música
  Future<void> buscarDirectorio({bool cambiarRuta = false}) async {
    //Si ya se conoce la ruta, ya solo se llama al minero y ya 
    if (rutaMusica != null && rutaMusica!.isNotEmpty && !cambiarRuta) {
      await ejecutarMinero(rutaMusica!);
      return;
    }
    String? rutaSeleccionada = await FilePicker.getDirectoryPath(
      dialogTitle: "Selecciona tu directorio",
    );

    if(rutaSeleccionada != null && rutaSeleccionada.isNotEmpty) {
      await ejecutarMinero(rutaSeleccionada);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ruta_musica', rutaSeleccionada);

      await ejecutarMinero(rutaSeleccionada);
    }
  }

  //Si no hay .db entonces se hace el escaneo de la ruta con la música
  Future<void> ejecutarMinero(String rutaMusica) async {
    limpiarPortadasRastreadas();
    miner = true;
    notifyListeners();

    try {
      await rust_api.ejecutarMinero(rutaMusica: rutaMusica);
      debugPrint("Se terminó de procesar");
      await cargarDatosBD();
    }catch(e) {
      debugPrint("Error en el minado: $e");
    }finally {
      miner = false;
      notifyListeners();
    }
  }


  //Para el procesamiento de las portadas de los álbumes 
  Future<void> cargarPortada(int index) async {
    if (index < 0 || index >= rolas.length) return;
    if (rolas[index].frontCover != null || _portadasSolicitadas.contains(index)) return;

    _portadasSolicitadas.add(index);

    try{
      final bytes = await rust_api.obtenerPortada(rutaMp3: rolas[index].path);
      if (bytes != null && bytes.isNotEmpty) {
        debugPrint("Carátula cargada ($index): ${bytes.length} bytes");
        rolas[index].frontCover = bytes;
        notifyListeners();
      } else {
          debugPrint("No se encontró carátula ID3 en: ${rolas[index].path}");
      }

    }catch(e) {
      debugPrint("Error extrayendo la caratula: $e");
    }
  }

  Future<void> limpiarBiblioteca() async {
    rolas.clear();
    rutaMusica = null;
    limpiarPortadasRastreadas();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ruta_musica');

    notifyListeners();
  }

  void limpiarPortadasRastreadas() {
    _portadasSolicitadas.clear();
  }

  void refrescarInterfaz() {
    notifyListeners();
  }
}