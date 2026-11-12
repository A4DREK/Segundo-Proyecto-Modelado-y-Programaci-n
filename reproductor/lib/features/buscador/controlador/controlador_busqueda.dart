import 'package:flutter/material.dart';
import '../../biblioteca/controlador/controlador_biblioteca.dart';

enum CampoBusqueda {
  titulo('Título'),
  artista('Artista'),
  album('Álbum'),
  genero('Género'),
  year('Año');

  final String etiqueta;
  const CampoBusqueda(this.etiqueta);
}

class BusquedaControlador extends ChangeNotifier {
  String _consulta = '';
  List<Rola> _resultados = [];
  final Set<CampoBusqueda> _camposActivos = CampoBusqueda.values.toSet();

  //Getters
  String get consulta => _consulta;
  bool get hayBusquedaActiva => _consulta.trim().isNotEmpty;
  List<Rola> get resultados => _resultados;
  Set<CampoBusqueda> get camposActivos => Set.unmodifiable(_camposActivos);
  bool get tieneFiltrosPersonalizados =>
      _camposActivos.length < CampoBusqueda.values.length;
  bool estaActivo(CampoBusqueda campo) => _camposActivos.contains(campo);

  //Inicio de los métodos
  void alternarCampo(
    CampoBusqueda campo,
    bool activo,
    List<Rola> catalogoCompleto,
  ) {
    if (activo) {
      _camposActivos.add(campo);
    } else if (_camposActivos.length > 1) {
      _camposActivos.remove(campo);
    }
    actualizarBusqueda(_consulta, catalogoCompleto);
  }

  void seleccionarTodos(List<Rola> catalogoCompleto) {
    _camposActivos.clear();
    _camposActivos.addAll(CampoBusqueda.values);
    actualizarBusqueda(_consulta, catalogoCompleto);
  }

  String _normalizar(String texto) {
    return texto
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
  }

  void actualizarBusqueda(String nuevaConsulta, List<Rola> catalogoCompleto) {
    _consulta = nuevaConsulta;
    final termino = _normalizar(nuevaConsulta.trim());

    if (termino.isEmpty) {
      _resultados = [];
      notifyListeners();
      return;
    }

    _resultados = catalogoCompleto.where((rola) {
      if (_camposActivos.contains(CampoBusqueda.titulo) &&
          _normalizar(rola.title).contains(termino)) {
        return true;
      }
      if (_camposActivos.contains(CampoBusqueda.artista) &&
          _normalizar(rola.performerName).contains(termino)) {
        return true;
      }
      if (_camposActivos.contains(CampoBusqueda.album) &&
          _normalizar(rola.albumName).contains(termino)) {
        return true;
      }
      if (_camposActivos.contains(CampoBusqueda.genero) &&
          _normalizar(rola.genre ?? '').contains(termino)) {
        return true;
      }
      if (_camposActivos.contains(CampoBusqueda.year) &&
          (rola.year?.toString() ?? '').contains(termino)) {
        return true;
      }
      return false;
    }).toList();

    notifyListeners();
  }

  void limpiar(List<Rola> catalogoCompleto) {
    actualizarBusqueda('', catalogoCompleto);
  }
}