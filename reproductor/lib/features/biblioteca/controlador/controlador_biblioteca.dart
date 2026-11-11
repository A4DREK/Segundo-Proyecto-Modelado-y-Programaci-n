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


  Future<void> editarCancion({
    required int index,
    required int idRola,
    String? nuevoTitulo,
    String? nuevoArtista,
    String? nuevoAlbum, 
    String? nuevoTrack,
    int? nuevoYear,
    String? nuevoGenero,
    required bool actualizarArtista,
    required bool actualizarAlbum,
  }) async {
    try {
      final exitoRola = await rust_api.actualizarRola(
        idRola: idRola,
        nuevoTitle: nuevoTitulo,
        nuevoArtista: nuevoArtista,
        nuevoAlbum: nuevoAlbum, 
        actualizarAlbum: actualizarAlbum,
        actualizarArtista: actualizarArtista,
        nuevoTrack: nuevoTrack != null ? int.tryParse(nuevoTrack) : null,
        nuevoYear: nuevoYear,
        nuevoGenre: nuevoGenero,
      );

      if (!exitoRola) return; 
        
      final albumOriginal = rolas[index].albumName;

      //Si se selecciono alguna de las casillas prosigue 
      if (actualizarAlbum || actualizarArtista) {
        for (int i = 0; i < rolas.length; i++) {
          if (rolas[i].albumName == albumOriginal) {
            rolas[i] = _copiarConNuevosDatos(
              rolas[i], 
              albumName: actualizarAlbum ? nuevoAlbum : null,
              artista: actualizarArtista ? nuevoArtista : null,
            );
          }
        }
      }

      if (index != -1) {
        rolas[index] = _copiarConNuevosDatos(
          rolas[index],
          titulo: nuevoTitulo,
          artista: nuevoArtista,
          albumName: nuevoAlbum, 
          track: nuevoTrack,
          year: nuevoYear,
          genero: nuevoGenero,
        );
      }
        
        notifyListeners();
      
    } catch(e) {
      debugPrint("Error editando la canción: [$e]");
    }
  }

  //Método auxiliar para la parte de copiar los datos para del artista que se deben de copiar 
  Rola _copiarConNuevosDatos(Rola c, {String? titulo, String? artista,String? albumName, String? track, int? year, String? genero}) {
    return Rola(
      idRola: c.idRola,
      path: c.path,
      performerName: artista ?? c.performerName,
      artistAlbum: c.artistAlbum,
      albumName: albumName ?? c.albumName,
      title: titulo ?? c.title,
      track: track ?? c.track,
      year: year ?? c.year,
      genre: genero ?? c.genre,
      frontCover: c.frontCover,
      artistPortrait: c.artistPortrait,
    );
  }

}