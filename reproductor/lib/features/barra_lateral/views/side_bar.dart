//Archivo para poder integrar todos los widgets que estarán en la side bar

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:cupertino_ui/cupertino_ui.dart';

//Import de los widgets
import 'widgets/menu_principal.dart';


class SideBar extends HookWidget {
  const SideBar({super.key});

  @override
  Widget build(BuildContext context) {

    final pageIndex = useState(0);

    
    return Column(
      children: [
        Expanded(
          child: MenuPrincipal(
            currentIndex: pageIndex.value,
            onChanged: (i) => pageIndex.value = i,
          ),
        ),

        //Parte de donde va el minero y ldkfjakdlfj
      ],
    );
  }
}

