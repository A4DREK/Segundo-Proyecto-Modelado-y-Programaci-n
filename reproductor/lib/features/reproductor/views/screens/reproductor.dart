import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

class ReproductorScreen extends StatelessWidget {
  const ReproductorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosWindow(
      sidebar: Sidebar(
        minWidth: 200,
        builder: (context, scrollController) {
          return SidebarItems(
            currentIndex: 0,
            onChanged: (index) { /*En esta parte irá la parte para cambiar de vista */},
            items: [
              SidebarItem(
                leading: MacosIcon(Icons.library_music),
                label: Text('Biblioteca'),
              ),
              SidebarItem(
                leading: MacosIcon(Icons.album),
                label: Text('Álbumes'),
              ),
            ],
          );
        },
      ),
      child: MacosScaffold(
        toolBar: const ToolBar(
          title: Text('Reproductor Mp3 Chidoris'),
          titleWidth: 200.0,
        ),
        children: [
          ContentArea(
            builder: (context, scrollController) {
              return const Center(
                child: Text(
                  'Esto funciona',
                  style: TextStyle(fontSize: 18),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}