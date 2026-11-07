//Archivo donde importaremos las funciones para utilizarlas dentro de dart
use std::path::Path;
use minero::minero::Minero;
use minero::procesar_id3v2::obtener_datos_id3;
use nucleo_dao::dao::conectar_db;

//Se implementaran las funciones del minero para poder utilizarlas en FLUTTER
pub struct RolaDto {
    pub id_rola: i64,
    pub path: String,
    pub titulo: String,
    pub artista: String,
    pub album: String,
    pub track: Option<String>,
    pub year: Option<i32>,
    pub genre: Option<String>,
}

pub fn ejecutar_minero(ruta_musica: String) -> Result<usize, String> {
    let path = Path::new(&ruta_musica);
    
    // Llamas a tu implementación original existente
    let mut minero = Minero::nuevo()?;
    minero.minar_directorio(path)
}

pub fn obtener_portada(ruta_mp3: String) -> Result<Option<Vec<u8>>, String> {
    let path = Path::new(&ruta_mp3);
    
    // Usas tu función de ID3 original
    let metadatos = obtener_datos_id3(path)?;
    Ok(metadatos.front_cover)
}

pub fn obtener_rolas_bd() -> Result<Vec<RolaDto>, String> {

    let conn = nucleo_dao::dao::conectar_db()
        .map_err(|e| format!("Error conectando a SQLite: {}", e))?;

    let rolas_db = nucleo_dao::dao::obtener_todas_las_rolas(&conn)
            .map_err(|e| format!("Error al consultar SQLite: {}", e))?;

    let dtos = rolas_db
        .into_iter()
        .map(|rola| RolaDto {
            id_rola: rola.id_rola,
            path: rola.path,
            titulo: rola.title.unwrap_or_else(|| "Unknown Track".to_string()),
            artista: rola.performer_name.unwrap_or_else(|| "Unknown Performer".to_string()),
            album: rola.album_name.unwrap_or_else(|| "Unknown Album".to_string()),
            track: rola.track.map(|t| t.to_string()),
            year: rola.year.map(|y| y as i32),
            genre: rola.genre,
        })
        .collect();

    Ok(dtos)
}
