import 'package:flutter/material.dart';
import 'package:reproductor/src/rust/api/simple.dart' as rust_api;
import '../../biblioteca/controlador/controlador_biblioteca.dart';

class EdicionControlador extends ChangeNotifier {
  bool guardando = false;

Future<void> editarCancion({
    required BibliotecaControlador bibliotecaCtrl,
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
    guardando = true;
    notifyListeners();

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
        
      final albumOriginal = bibliotecaCtrl.rolas[index].albumName;

      // Si se seleccionó alguna de las casillas se prosigue 
      if (actualizarAlbum || actualizarArtista) {
        for (int i = 0; i < bibliotecaCtrl.rolas.length; i++) {
          if (bibliotecaCtrl.rolas[i].albumName == albumOriginal) {
            bibliotecaCtrl.rolas[i] = _copiarConNuevosDatos(
              bibliotecaCtrl.rolas[i], 
              albumName: actualizarAlbum ? nuevoAlbum : null,
              artista: actualizarArtista ? nuevoArtista : null,
            );
          }
        }
      }

      if (index != -1) {
        bibliotecaCtrl.rolas[index] = _copiarConNuevosDatos(
          bibliotecaCtrl.rolas[index],
          titulo: nuevoTitulo,
          artista: nuevoArtista,
          albumName: nuevoAlbum, 
          track: nuevoTrack,
          year: nuevoYear,
          genero: nuevoGenero,
        );
      }
        
      // Notifica a la interfaz que la lista de la biblioteca fue modificada
      bibliotecaCtrl.refrescarInterfaz();
      
    } catch(e) {
      debugPrint("Error editando la canción: [$e]");
    } finally {
      guardando = false;
      notifyListeners();
    }
  }

  //Método auxiliar para la parte de copiar los datos para del artista que se deben de copiar 
  Rola _copiarConNuevosDatos(
    Rola c, {
      String? titulo, 
      String? artista,
      String? albumName, 
      String? track, 
      bool isEditing = true, 
      int? year, 
      String? genero,
      int? idPerformer,
      int? tipoArtista,
    }) {
    return Rola(
      idRola: c.idRola,
      path: c.path,
      performerName: artista ?? c.performerName,
      artistAlbum: c.artistAlbum,
      albumName: albumName ?? c.albumName,
      title: titulo ?? c.title,
      track: track ?? c.track, 
      year: isEditing ? year : c.year,
      genre: isEditing ? genero : c.genre,
      frontCover: c.frontCover,
      artistPortrait: c.artistPortrait,
      idPerformer: idPerformer ?? c.idPerformer,
      tipoArtista: tipoArtista ?? c.tipoArtista,
    );
  }
}
