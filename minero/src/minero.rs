/* Ahora, la parte del minero, una vez que tenemos la parte de poder buscar la ruta y de poder obtener 
 * los datos de los archivos con etiqueta ID3V2.4 ahora lo que tiene que hacer este archivo es poder mandar 
 * cada uno de los datos a la base de datos SQL, para esto ya tenemos la implementación del DAO, 
 * por lo que no debería de ser un problema dicha implementación
 * 
 * por lo que: 
 * 
 * El minero debe de:
 *  1.- Se busca y obtiene la ruta de la base de datos, la primera vez, al no existir se debe de crear 
 *  2.- Se conecta el minero con la base de datos y se crean las tablas
 *  3.- Se busca todo el directorio de música con la parte de buscar_ruta
 *  4.- una vez con esa parte, a cada archivo .mp3 que sea ID3, se obtendrán todos los parámetros necesarios
 *  5.- Se mandan a llamar las funciones del DAO las cuales son obtener_crear_(x parámetro)
 */

use std::path::Path;
use nucleo_dao::dao::obtener_crear_album;
use nucleo_dao::dao::obtener_crear_performer;
use nucleo_dao::dao::obtener_crear_rola;
use rusqlite::Connection;
use crate::visualizer::LogTabla;

 use crate::buscar_ruta;
 use crate::procesar_id3v2;
 use nucleo_dao::dao;

 pub struct Minero {
    connection: Connection,
 }

 impl Minero {
     
    //Inicializa la conexión con la base de datos y se asegura que se crean o existan las tablas
    pub fn nuevo() -> Result<Self, String> {

        let connection = dao::conectar_db()
            .map_err(|e| format!("Error en la conexión con la BD: {}", e))?;

        if !Self::existen_tablas(&connection) {
            dao::crear_tablas_db(&connection)
                .map_err(|e| format!("Error al crear las tablas en la BD: {}", e))?;
        }

        Ok(Self { connection })

    }

    //Instancia un minero en una conexión ya existente 
    pub fn desde_conexion(connection: Connection) -> Result<Self, String> {

        if !Self::existen_tablas(&connection) {
                    
            dao::crear_tablas_db(&connection)
                .map_err(|e| format!("Error al crear las tablas en la BD: {}", e))?;
        }

        Ok(Self { connection })

    }
    
    //Inicia a recorrer de forma recursiva cada uno de los archivos mp3 ID3V2
    pub fn minar_directorio(&mut self, music_route: &Path) -> Result<usize, String> {

        //Obtiene todas las rutas de archivos .mp3 con las etiquetas ID3V2
        let archives = buscar_ruta::obtener_ruta_musica(&music_route)?;
        let mut total_incrusted = 0;
        let mut total_errors = 0;

        LogTabla::imprimir_encabezado();
        
        for route_archive in &archives {

            //Inicia la extracción de los metadatos ID3V2 del arhivo 
            let metadata = match procesar_id3v2::obtener_datos_id3(&route_archive) {
                Ok(m) => m,
                Err(e) => {
                    total_errors += 1;
                    eprintln!("Error al procesar los metadatos en {:?}: {}", music_route, e);
                    continue;
                }
            };

            //Se obtienen los datos para el dao
            let song_path = match metadata.route.to_str() {
                Some(p) => p,
                None => {
                    total_errors += 1;
                    continue;
                },
            };

            //Ruta del album donde están las canciones
            let album_path = metadata
                .route
                .parent()
                .and_then(|p| p.to_str())
                .unwrap_or("");

            let track_number: Option<i64> = metadata.track.as_ref().and_then(|t| {
                t.split('/')
                    .next()
                    .and_then(|s| s.trim().parse::<i64>().ok())
            });


            let year_i64 = metadata.year.map(|y| y as i64);
            //Inicia las llamadas a los métodos del DAO, para ya conectar directamente con la base de datos

            //Parte de los performer, en esta parte cada nueva entrada, debe de entrar en 'Unknown' el usuari
            //debe de ser el que pueda establecer si se trata de una persona o un grupo

            const PERFORMER_TYPE_UNKNOWN: i64 = 2;

            let id_performer = match obtener_crear_performer(
                &self.connection, 
                metadata.artist.as_deref(),
                PERFORMER_TYPE_UNKNOWN,
            ) {
                Ok(id) => id,
                Err(e) => {
                    total_errors +=1;
                    LogTabla::imprimir_cancion(&metadata, false);
                    eprintln!("Error al guardar el performer en {:?}: {}", music_route, e);
                    continue;
                }
            };

            let id_album = match obtener_crear_album(
                &self.connection,
                album_path,
                metadata.album.as_deref(),
                year_i64
            ) {
                Ok(id) => id,
                Err(e) => {
                    total_errors += 1;
                    LogTabla::imprimir_cancion(&metadata, false);
                    eprintln!("Error al guardar el álbum en: {:?}, {}", music_route, e);
                    continue;
                }    
            };

            //Parte para obtener el track
            match obtener_crear_rola(
                &self.connection,
                id_performer,
                id_album,
                song_path,
                metadata.title.as_deref(),
                track_number,
                year_i64,
                metadata.genre.as_deref()
            ) {
                Ok(_) => {
                    total_incrusted += 1;
                    LogTabla::imprimir_cancion(&metadata, true);
                },
                Err(e) => {
                    total_errors += 1;
                    LogTabla::imprimir_cancion(&metadata, false);
                    eprintln!("Error al guardar la rola en {:?}: {} ", music_route, e)},
            }
        }

        LogTabla::imprimir_resumen(archives.len(), total_incrusted, total_errors);
        Ok(total_incrusted)
    }

    fn existen_tablas(connection: &Connection) -> bool {
        let conteo: i64 = connection
            .query_row(
                "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='types'",
                [],
                |r| r.get(0)
            ).unwrap_or(0);

        conteo > 0
    }
 }

 //Inicio de las pruebas unitarias
 #[cfg(test)]
 mod tests {

    use super::*;
    use rusqlite::Connection;
    use std::fs;
    use std::path::PathBuf;
    use std::sync::atomic::{AtomicUsize, Ordering};

    static TEST_COUNTER: AtomicUsize = AtomicUsize::new(0);

    #[test]
    fn prueba_minero() {

        let connection = Connection::open_in_memory().expect("No se pudo abrir la BD en memoria");
        let mut minero = Minero::desde_conexion(connection).expect("Error al inicializar el minero");

        let tmp_dir = crear_dir_temp("minado_test");
        let route_mp3: PathBuf = tmp_dir.join("demo.mp3");

        static DEMO_MP3: &[u8] = include_bytes!("../../fixtures/demo.mp3");
        fs::write(&route_mp3, DEMO_MP3).expect("Error al escribir el MP3 en el archivo temporal");

        //Inicia con las funciones del minero
        let inserted = minero.minar_directorio(&tmp_dir).expect("Fallo en el minero");
        assert_eq!(inserted, 1, "Debe de haber 1 elemento en la base de datos");

        let track_numbers: i64 = minero
            .connection
            .query_row("SELECT COUNT(*) FROM rolas", [], |r| r.get(0))
            .unwrap();

        assert_eq!(track_numbers, 1, "La tabla de rolas debe de tener un solo registro");

        let _ = fs::remove_dir_all(tmp_dir);

    }

    fn crear_dir_temp(prefix: &str) -> PathBuf {
        let pid = std::process::id();
        let id_test = TEST_COUNTER.fetch_add(1, Ordering::SeqCst);
        let tmp_dir = std::env::temp_dir().join(format!("minero_{}_{}_{}", prefix,pid, id_test));
        let _ = fs::create_dir(&tmp_dir);
        tmp_dir
    }
 }