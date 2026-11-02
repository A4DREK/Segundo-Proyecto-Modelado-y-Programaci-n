//Archivo para poder integrar todos los widgets que estarán en la side bar

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart';

class SideBar extends HookWidget {
  const SideBar({super.key});

  @override
  Widget build(BuildContext context) {
    final pageIndex = useState(0);

      return Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 240,
          height: double.infinity,
          child: LiquidGlassLens(
            style: const LiquidGlassStyle(
              shape: LiquidGlassShape.squircle(cornerRadius: 0.4),
              refractionIndex: 1.02,
              refractionWidth: 34,
            ),
            child: Container(
              padding: const EdgeInsets.only(top: 50.0),
              color: const Color(0xFF14225B).withValues(alpha: 0.3),
              child: SidebarItems(
                items: const [
                  SidebarItem(
                    leading: MacosIcon(CupertinoIcons.play_circle_fill),
                    label: Text('Escucha'),
                  ),
                  SidebarItem(
                    leading: MacosIcon(CupertinoIcons.square_grid_2x2),
                    label: Text('Browse'),
                  ),
                  SidebarItem(
                    leading: MacosIcon(CupertinoIcons.add_circled),
                    label: Text('Minero'),
                  )


                ],
                currentIndex: pageIndex.value,
                onChanged: (i) => pageIndex.value = i
              ),
            ),
          )
        )
      );
  }
}

