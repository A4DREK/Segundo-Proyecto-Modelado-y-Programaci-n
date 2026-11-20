# 2NDO PROYECTO MODELADO Y PROGRAMACIÓN

## Reproductor de Música con Base de Datos SQLite

Este proyecto de Modelado y Programación es un sistema de reproducción y gestión de bibliotecas musicales compatible con **macOS** y **Linux**. El sistema escanea archivos de audio `.mp3` con etiquetas **ID3v2.4**, almacena y edita sus metadatos de forma no destructiva dentro de una base de datos relacional **SQLite** (`rolas.db`), y permite reproducir las pistas desde una interfaz gráfica de escritorio.

El núcleo de acceso a datos (`nucleo_dao`) y el extractor de metadatos (`minero`) se desarrollaron en **Rust**; mientras que la interfaz gráfica (`reproductor`) se construyó bajo el toolkit de  **Flutter (Dart)**, comunicando ambas capas de forma nativa y asíncrona mediante `flutter_rust_bridge`.

> **Nota sobre la base de datos:** No es necesario crear manualmente el archivo `.db`. En la primera ejecución, tanto el minero como el reproductor generan e inicializan automáticamente `rolas.db` en la ruta estándar del sistema operativo:
> * **Linux:** `~/.local/share/rolas/rolas.db`
> * **macOS:** `~/Library/Application Support/rolas/rolas.db`

---

## Ejecución rápida (Binarios precompilados)

Si descargaste los ejecutables directamente desde la sección **Releases** del repositorio, no necesitas instalar Rust ni Flutter:

### En Linux (`x86_64`)
Requiere tener instalada la librería de audio `libmpv` en el sistema:
* **Ubuntu / Debian:** `sudo apt install -y libmpv-dev`
* **Fedora:** `sudo dnf install -y mpv-libs` (requiere RPM Fusion Free)
> **NOTA
> * Si la ventana tarda en responder o se congela al redimensionar en pantallas de alta resolución (Wayland), ejecútalo forzando X11:
>   ```bash
>   GDK_BACKEND=x11 ./reproductor
>   ```

```bash
# 1. Ejecutar el minero (CLI)
chmod +x minero-linux-x64
./minero-linux-x64 <ruta_carpeta_musica>

# 2. Descomprimir y abrir el reproductor (GUI)
tar -xzvf reproductor-linux-x64.tar.gz
cd reproductor-linux-x64
./reproductor

### En macOS (`arm64` / Universal)

```bash
# 1. Ejecutar el minero (CLI)
chmod +x minero-macos
./minero-macos <ruta_carpeta_musica>
```

Para abrir `reproductor.app`, descomprime `reproductor-macos.zip` y haz **clic derecho -> Abrir** la primera vez para autorizar su ejecución fuera de la App Store.

---

## Construcción del proyecto 

### 1. Herramientas y dependencias del sistema

Se necesitan los compiladores de **Rust** y **Flutter** (con soporte de escritorio habilitado). Para revisar que estén instalados utiliza:

```bash
cargo --version
flutter --version
```

Si no se tienen instalados, consulta las páginas oficiales de Rust y Flutter para ver el proceso de instalación. :)) Adicionalmente, instala las dependencias nativas correspondientes a tu sistema operativo:

* **macOS:**
  * **Xcode** completo (con *Command Line Tools* habilitadas) y **CocoaPods** (`brew install cocoapods`) para enlazar las bibliotecas nativas de Rust y los *frameworks* de escritorio.

* **Linux (Ubuntu / Debian):**
  ```bash
  sudo apt update
  sudo apt install -y clang cmake ninja-build pkg-config xz-utils g++ \
    libgtk-3-dev libsqlite3-dev libasound2-dev libmpv-dev zenity
  ```

* **Linux (Fedora):**
  ```bash
  # Habilitar repositorio RPM Fusion Free para soporte de audio (mpv-devel)
  sudo dnf install -y [https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm](https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm) -E %fedora).noarch.rpm

  sudo dnf install -y gcc-c++ clang cmake ninja-build pkg-config xz \
    gtk3-devel sqlite-devel alsa-lib-devel mpv-devel zenity perl-Digest-SHA
  ```

### 2. Clonar y compilar el workspace de Rust

Clona el repositorio y compila los paquetes del *backend* (`nucleo_dao` y `minero`):

```bash
git clone [https://github.com/A4DREK/Segundo-Proyecto-Modelado-y-Programaci-n.git](https://github.com/A4DREK/Segundo-Proyecto-Modelado-y-Programaci-n.git)
cd Segundo-Proyecto-Modelado-y-Programaci-n

# Compilar workspace y ejecutar pruebas unitarias
cargo build --workspace
cargo test --workspace
```

---

## Ejecución del Minero (CLI)

El minero recorre de forma recursiva un directorio, filtra los archivos `.mp3` con cabecera válida ID3v2.4, registra sus metadatos en SQLite y muestra una tabla resumen en consola.

### Modo desarrollador

Desde la raíz del proyecto:

```bash
cargo run -p minero -- <ruta_carpeta_musica>
```

### Ejecutable independiente (Release)

```bash
cargo build --release -p minero
./target/release/minero <ruta_carpeta_musica>
```

---

## Ejecución del Reproductor (Interfaz Gráfica)

Para correr la aplicación de escritorio tienes dos opciones:

### Si se quiere ocupar el "Modo desarrollador"

Dentro de la carpeta `reproductor` corre los siguientes comandos:

```bash
cd reproductor
flutter pub get

# En macOS
flutter run -d macos

# En Linux
flutter run -d linux
```

### Si se quiere ocupar un ejecutable (Release)

Dentro de la carpeta `reproductor`, genera la compilación de producción según tu sistema operativo:

```bash
# Para macOS
flutter build macos --release

# Para Linux
flutter build linux --release
```

Una vez compilado, ejecuta el binario generado desde su ruta de salida:

```bash
# En macOS (abre el paquete de aplicación)
open ./build/macos/Build/Products/Release/reproductor.app

# En Linux (debe ejecutarse dentro de bundle/ para cargar lib/ y data/)
./build/linux/x64/release/bundle/reproductor
```

> **Solución de problemas en Fedora (`mimalloc.o`):** Si al ejecutar `flutter build linux --release` Ninja arroja el error `missing and no known rule to make it` sobre `mimalloc/out/release/mimalloc.o`, agrega `BUILD_BYPRODUCTS "${CMAKE_CURRENT_BINARY_DIR}/mimalloc/out/release/mimalloc.o"` dentro de `ExternalProject_Add(mimalloc ...)` en `~/.pub-cache/hosted/pub.dev/media_kit_libs_linux-*/linux/CMakeLists.txt`, ejecuta `flutter clean && flutter pub get` y vuelve a compilar.