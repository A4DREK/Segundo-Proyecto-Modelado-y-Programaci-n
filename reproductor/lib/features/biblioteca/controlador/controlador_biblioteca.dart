//Modificación bien del controlado para que ya acepte las etiquetas de la BD

import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:reproductor/src/rust/api/simple.dart' as rust_api;
import 'package:file_picker/file_picker.dart';

class Rola {
  final int idRola;
  final String title;
  final String performerName;
  final String albumName;
  final String path;
  Uint8List? frontCover;

  Rola({
    required this.idRola,
    required this.title,
    required this.performerName,
    required this.albumName,
    required this.path,
    this.frontCover,
  });

  factory Rola.desdeDto(rust_api.RolaDto dto) {
    return Rola(
      idRola: dto.idRola.toInt(),
      title: dto.titulo,
      performerName: 'Artista Desconocido', //Este y el siguiente se deben de actualizar
      albumName: 'Álbum Desconocido',
      path: dto.path,
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
  Future<void> buscarDirectorio() async {
    String? rutaSeleccionada = await FilePicker.getDirectoryPath(
      dialogTitle: "Selecciona tu directorio",
    );

    if(rutaSeleccionada != null && rutaSeleccionada.isNotEmpty) {
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
    if(index < 0 || index >= rolas.length) {
      return;
    }

    if(rolas[index].frontCover != null) {
      return;
    }

    if (_portadasSolicitadas.contains(index)) {
      return;
    }

    _portadasSolicitadas.add(index);

    try{
      final bytes = await rust_api.obtenerPortada(rutaMp3: rolas[index].path);
      if(bytes != null) {
        rolas[index].frontCover = bytes;
        notifyListeners();
      }
    }catch(e) {
      debugPrint("Error extrayendo la caratula: $e");
    }
  }

  void limpiarPortadasRastreadas() {
    _portadasSolicitadas.clear();
  }

}