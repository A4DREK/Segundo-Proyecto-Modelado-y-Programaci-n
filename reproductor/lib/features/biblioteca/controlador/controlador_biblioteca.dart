import 'package:flutter/material.dart';

//Esta clase es temporal porque aún no conectamos nada a la base de datos solo es para mostrar imágenes predeterminadas
class CancionTemporal {
  final String cancion;
  final String artista;
  final String link;

  CancionTemporal({
    required this.cancion,
    required this.artista,
    required this.link,
  });
}

//Parte del controlador
class BibliotecaControlador extends ChangeNotifier {

  List<CancionTemporal> albums = [];
  bool cargando = false; //
  bool vistaGrid = true;

  //Para verificar si esta en x o y vista
  void alternarVista() {
    vistaGrid = !vistaGrid;
    notifyListeners();
  }


  void cargarDatos() {
    cargando = true;
    notifyListeners();

    //Posteriormente se harán las llamadas al minero para obtener las imágenes

    albums = [
      CancionTemporal(cancion: 'Dawn FM', artista: "The Weeknd", link: 'https://cdn-images.dzcdn.net/images/cover/478a544d29275755b3b8f7b4a1fd7a3c/0x1900-000000-80-0-0.jpg'),
      CancionTemporal(cancion: 'Mosca', artista: "NSQK", link: 'https://i.scdn.co/image/ab67616d0000b273d4798c7abe3ccd11d56936a1'),
      CancionTemporal(cancion: "Blonde", artista: "Frank Ocean", link: 'https://i.scdn.co/image/ab67616d0000b273c5649add07ed3720be9d5526'),
    ];

    cargando = false;

    notifyListeners();
  }

}