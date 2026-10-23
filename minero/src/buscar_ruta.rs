// Código que utilizará para preguntar la ruta de donde tenga las canciones el usuario
//todo esto debe de devolver los archivos .mp3, todos los demás deben de ser ignorados

use std::fs::{self, File};
use std::io::Read;
use std::path::{Path, PathBuf};
use walkdir::WalkDir;

pub fn obtener_ruta_musica(ruta: &Path) -> Result<Vec<PathBuf>, String> {

    //Verificar si la ruta existe
    if !ruta.exists() || !ruta.is_dir() {
        return Err(format!("La ruta mandada corresponde a un archivo o directamente no existe, {:?}", ruta));
    }

    //Canciones corresponde al vector dónde se guardarán las canciones
    let mut canciones = Vec::new();

    //Mientras el walkdir encuentre los resultados deseados, se irán agregando en canciones
    for entrada in WalkDir::new(ruta) {
        if let Ok(entrada) = entrada {
            let ruta_archivo = entrada.path();
            if ruta_archivo.is_file()
                && ruta_archivo
                    .extension()
                    .is_some_and(|extension| extension.eq_ignore_ascii_case("mp3"))
                && verificar_id3(ruta_archivo)
            {
                //También nos aseguramos que la ruta sea absoluta, para evitar duplicados de las canciones
                let ruta_absoluta = fs::canonicalize(ruta_archivo)
                    .unwrap_or_else(|_| ruta_archivo.to_path_buf());

                canciones.push(ruta_absoluta);
            }
        }
    }
    Ok(canciones)

}

fn verificar_id3(ruta: &Path) -> bool {

    //Primero se verifica que exista el archivo
    let mut archivo = match File::open(ruta) {
        Ok(a) => a,
        Err(_) => return false,
    };

    //Creamos un buffer para poder almacenar los primeros 3 dígitos del binario de cada canción
    let mut buffer = [0u8; 3];

    //Si los primeros tres dígitos del identificador son ID3 entonces la fn devuelve true, en otro caso, false
    if archivo.read_exact(&mut buffer).is_ok() {
        &buffer == b"ID3"
    }else {
        false
    }
}


#[cfg(test)]
mod tests {

    use super::*;
    use std::fs::{self, File};
    use std::io::Write;
    use std::path::{Path, PathBuf};
    use std::sync::atomic::{AtomicUsize, Ordering};

    static TEST_CONTEO: AtomicUsize = AtomicUsize::new(0);

    #[test]
    fn test_ruta_inexistente() {
        let ruta_test = Path::new("ruta/ficticia/que/no/existe");
        let resultado = obtener_ruta_musica(&ruta_test);
        assert!(resultado.is_err());
    }

    #[test]
    fn test_no_es_archivo() {
        let tmp_dir = crear_dir_temp("test_archivo");
        let ruta = tmp_dir.join("test.txt");
        let mut archivo = File::create(&ruta).expect("Error al crear el archivo");
        archivo.write_all(b"Contenido").expect("Error al escribir el texto");

        let resultado = obtener_ruta_musica(&ruta);
        assert!(resultado.is_err());

        let _ = fs::remove_dir_all(tmp_dir);
    }

    #[test]
    fn test_ruta_correcta() {
        //Creamos el directorio temporal con a ruta del archivo 
        let tmp_dir = crear_dir_temp("test_ruta_correcta");
        let ruta_archivo = tmp_dir.join("demo.mp3");

        //Tomamos los bytes del mp3 de la carpeta fixtures
        static MP3_BYTES: &[u8] = include_bytes!("../../fixtures/demo.mp3");
        fs::write(&ruta_archivo, MP3_BYTES).expect("Error al escribir el archivo");

        let ruta_esperada = fs::canonicalize(&ruta_archivo).expect("El archivo de prueba debe de existir");

        let resultados = obtener_ruta_musica(&tmp_dir).expect("Fallo con el MP3");

        assert_eq!(resultados.len(), 1, "Solo debe de existir un archivo");
        assert_eq!(resultados[0], ruta_esperada);

        let _ = fs::remove_dir_all(tmp_dir);
     }
    
    //Crea un directorio temporal único por prueba y un hilo de ejecución distinto para evitar colisiones
    fn crear_dir_temp (prefijo: &str) -> PathBuf {
        let pid = std::process::id();
        let id_test = TEST_CONTEO.fetch_add(1, Ordering::SeqCst);
        let temp_dir = std::env::temp_dir().join(format!("prueba_{}_{}_{}", prefijo, pid, id_test));
        let _ = fs::create_dir_all(&temp_dir);
        temp_dir
    } 
}

