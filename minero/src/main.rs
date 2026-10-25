//En este main se hara la llamada a los 3 archivos que llevarán a cabo el minero

use std::env;
use std::path::Path;
use minero::minero::Minero;

fn main () {
    //Primero se ingresa la ruta en termial 
    let args: Vec<String> = env::args().collect();

    //Si no se pasa algún argumento se mandará una ruta relativa al proyecto
    let route_str = if args.len() > 1 {
        &args[1]
    } else {
        "../../fixtures/" 
    };

    let route_music = Path::new(route_str);

    if !route_music.exists() {
        eprintln!("Error en la ruta {:?} no existe", route_music);
        return;
    }

    println!("Iniciando la conexión con la base de datos");

    let mut minero = match Minero::nuevo() {
        Ok(m) => m,
        Err(e) => {
            eprintln!("Error fatal al iniciar el minero: {}", e);
            return;
        }
    };

    println!("Se escanea el directorio: {:?}", route_music);

    match minero.minar_directorio(route_music) {
        Ok(procesado) => {
            println!("\nProceso terminado");
            println!("Total de canciones guardadas en la BD: {}", procesado);
        }
        Err(e) => {
            eprintln!("\nEl minero tuvo algún error: {}", e)
        }
    }

}