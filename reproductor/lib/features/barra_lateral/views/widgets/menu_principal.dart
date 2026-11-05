//Parte del código donde esta la lista de widgets que aparecerán en la barra lateral

import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

class MenuPrincipal extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const MenuPrincipal({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SidebarItems(
      currentIndex: currentIndex,
      selectedColor: const Color(0xFF29264f),
      onChanged: onChanged,
      items: [
        const SidebarItem(
          leading: MacosIcon(CupertinoIcons.house),
          label: Text('Home'),
        ),
        const SidebarItem(
          leading: MacosIcon(CupertinoIcons.square_grid_2x2),
          label: Text('Views'),
        ),
        const SidebarItem(
          leading: MacosIcon(CupertinoIcons.add_circled_solid),
          label: Text('Minero'),
        ),
      ],
    );
  }
}