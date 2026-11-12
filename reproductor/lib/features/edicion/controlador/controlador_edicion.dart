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
      
      await bibliotecaCtrl.cargarDatosBD();
      
    } catch(e) {
      debugPrint("Error editando la canción: [$e]");
    } finally {
      guardando = false;
      notifyListeners();
    }
  }

}
