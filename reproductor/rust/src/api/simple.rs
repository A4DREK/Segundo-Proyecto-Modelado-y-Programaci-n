//Archivo donde importaremos las funciones para utilizarlas dentro de dart
use std::path::Path;
use minero::minero::Minero;
use minero::procesar_id3v2::obtener_datos_id3;
use nucleo_dao::dao::conectar_db;

//Se implementaran las funciones del minero para poder utilizarlas en FLUTTER
pub struct RolaDto {
    pub id_rola: i64,
    pub titulo: String,
    pub path: String,
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

    let conn = conectar_db().map_err(|e| e.to_string())?;
    
    let mut stmt = conn.prepare("SELECT id_rola, title, path FROM rolas").map_err(|e| e.to_string())?;
    
    let rolas_iter = stmt.query_map([], |row| {
        Ok(RolaDto {
            id_rola: row.get(0)?,
            titulo: row.get(1)?,
            path: row.get(2)?,
        })
    }).map_err(|e| e.to_string())?;
    
    let mut resultado = Vec::new();
    for rola in rolas_iter {
        if let Ok(r) = rola {
            resultado.push(r);
        }
    }
    
    Ok(resultado)
}
