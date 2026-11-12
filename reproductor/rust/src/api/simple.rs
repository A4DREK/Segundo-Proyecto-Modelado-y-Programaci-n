//Archivo donde importaremos las funciones para utilizarlas dentro de dart
use std::path::Path;
use minero::minero::Minero;
use minero::procesar_id3v2::obtener_datos_id3;

//Se implementaran las funciones del minero para poder utilizarlas en FLUTTER
pub struct RolaDto {
    pub id_rola: i64,
    pub id_performer: i64,
    pub artist_type: i32,
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
    let mut minero = Minero::nuevo()?;
    minero.minar_directorio(path)
}

pub fn obtener_portada(ruta_mp3: String) -> Result<Option<Vec<u8>>, String> {
    let path = Path::new(&ruta_mp3);
    let metadatos
    = obtener_datos_id3(path)?;
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
            id_performer: rola.id_performer.unwrap_or(0), 
            artist_type: rola.id_type.unwrap_or(2) as i32
        })
        .collect();

    Ok(dtos)
}

pub fn actualizar_rola(
    id_rola: i64,
    nuevo_title: Option<String>,
    nuevo_artista: Option<String>,
    nuevo_album: Option<String>,
    actualizar_artista: bool,
    actualizar_album: bool,
    nuevo_track: Option<i64>,
    nuevo_year: Option<i64>,
    nuevo_genre: Option<String>,
) -> Result<bool, String> {
    
    let conn = nucleo_dao::dao::conectar_db()
        .map_err(|e| format!("Error DB: {}", e))?;

    
    let datos_actuales = conn.query_row(
        "SELECT r.id_album, a.path, a.year 
        FROM rolas r 
        LEFT JOIN albums a ON r.id_album = a.id_album 
        WHERE r.id_rola = ?1",
        [id_rola],
        |r| {
            let id_a = r.get::<_, i64>(0)?;
            let path_a = r.get::<_, Option<String>>(1).unwrap_or(None).unwrap_or_default();
            let year_a = r.get::<_, Option<i64>>(2).unwrap_or(None);
            Ok((id_a, path_a, year_a))
        },
    );

    let (id_album_actual, path_album_actual, year_album_actual) = match datos_actuales {
        Ok(datos) => datos,
        Err(_) => return Err("No se encontró la canción original".to_string()),
    };

    let mut id_nuevo_performer: Option<i64> = None;
    let mut id_nuevo_album: Option<i64> = None;

    if let Some(artista) = &nuevo_artista {
        let id_perf = nucleo_dao::dao::obtener_crear_performer(&conn, Some(artista), 2)
            .map_err(|e| format!("Error obteniendo artista: {}", e))?;
        
        if actualizar_artista {
            conn.execute(
                "UPDATE rolas SET id_performer = ?1 WHERE id_album = ?2",
                rusqlite::params![id_perf, id_album_actual],
            ).map_err(|e| format!("Error en modificar al artista: {}", e))?;
        }
        
        id_nuevo_performer = Some(id_perf);
    }

    if let Some(album_name) = &nuevo_album {
        if actualizar_album {
            let id_existente: Option<i64> = conn.query_row(
                "SELECT id_album FROM albums WHERE name = ?1 AND path = ?2",
                rusqlite::params![album_name, &path_album_actual],
                |r| r.get(0)
            ).ok(); 

            if let Some(id_destino) = id_existente {
                if id_destino != id_album_actual {
                    // Si ya existe, MUDAMOS todas las canciones de este álbum al existente
                    conn.execute(
                        "UPDATE rolas SET id_album = ?1 WHERE id_album = ?2",
                        rusqlite::params![id_destino, id_album_actual]
                    ).map_err(|e| format!("Error fusionando álbumes: {}", e))?;
                    
                    id_nuevo_album = Some(id_destino);
                }
            } else {
                // Si no existe, entonces se renombra al actual
                let modificado = nucleo_dao::dao::modificar_album(
                    &conn, 
                    id_album_actual, 
                    None, 
                    Some(album_name), 
                    year_album_actual
                ).map_err(|e| format!("Error renombrando álbum masivo: {}", e))?;
                
                if !modificado {
                    return Err("Fallo interno al renombrar el álbum masivo".to_string());
                }
            }
        } else {
            let id_alb = nucleo_dao::dao::obtener_crear_album(
                &conn, 
                &path_album_actual, 
                Some(album_name), 
                year_album_actual
            ).map_err(|e| format!("Error obteniendo/creando álbum individual: {}", e))?;
            
            if id_alb != id_album_actual {
                id_nuevo_album = Some(id_alb);
            }
        }
    }

    
    nucleo_dao::dao::modificar_rola(
        &conn,
        id_rola,
        id_nuevo_performer, 
        id_nuevo_album,
        None, 
        nuevo_title.as_deref(),
        nuevo_track,
        nuevo_year,
        nuevo_genre.as_deref(),
    ).map_err(|e| format!("Error actualizando track individual: {}", e))?;

    //Matar huérfanos (De vdd ese término es demasiado surreal wtf)
    let _ = conn.execute(
        "DELETE FROM albums WHERE NOT EXISTS (SELECT 1 FROM rolas WHERE rolas.id_album = albums.id_album)",
        [],
    );

    let _ = conn.execute(
        "DELETE FROM performers WHERE NOT EXISTS (SELECT 1 FROM rolas WHERE rolas.id_performer = performers.id_performer)",
        [],
    );
    Ok(true)
}

pub fn actualizar_persona(
    id_person: i64,
    nombre: Option<String>,
    nuevo_stage_name: Option<String>,
    nuevo_real_name: Option<String>,
    nuevo_birth_date: Option<String>,
    nuevo_death_date: Option<String>,
) -> Result<bool, String> {
    let mut conn = nucleo_dao::dao::conectar_db()
        .map_err(|e| format!("Error al conectar con la base de datos: {}", e))?;

    nucleo_dao::dao::modificar_person(
        &mut conn,
        id_person,
        nombre.as_deref(),
        nuevo_stage_name.as_deref(),
        nuevo_real_name.as_deref(),
        nuevo_birth_date.as_deref(),
        nuevo_death_date.as_deref(),
    ).map_err(|e| format!("Error modificando el SQL: {}", e))
}

pub fn actualizar_grupo(
    id_group: i64,
    nuevo_name: Option<String>,
    nueva_start_date: Option<String>,
    nueva_end_date: Option<String>,
) -> Result<bool, String> {
    let mut conn = nucleo_dao::dao::conectar_db()
        .map_err(|e| format!("Error conectando la base de datos: {}", e))?;

    nucleo_dao::dao::modificar_group(
        &mut conn,
        id_group,
        nuevo_name.as_deref(), 
        nueva_start_date.as_deref(), 
        nueva_end_date.as_deref(),
    ).map_err(|e| format!("Error modificando el SQL: {}", e))
}

pub fn convertir_artista_person(
    id_performer: i64,
    stage_name: Option<String>,
    real_name: Option<String>,
    birth_date: Option<String>,
    death_date: Option<String>
) -> Result<bool, String> {
    let mut conn = nucleo_dao::dao::conectar_db()
        .map_err(|e| format!("Error en la conexión con la base de datos {}", e))?;

    let exito= nucleo_dao::dao::convertir_unknown_person(
        &mut conn, 
        id_performer, 
        stage_name.as_deref(), 
        real_name.as_deref(), 
        birth_date.as_deref(), 
        death_date.as_deref(),
    ).map_err(|e| format!("Error en la conversion: {}",e))?;

    Ok(exito)
}

pub fn convertir_artista_group(
    id_performer: i64,
    name: Option<String>,
    start_date: Option<String>,
    end_date: Option<String>,
) -> Result<bool, String> {
    let mut conn = nucleo_dao::dao::conectar_db()
        .map_err(|e| format!("Error en la conexión con la base de datos {}", e))?;

    nucleo_dao::dao::convertir_unknown_group(
        &mut conn, 
        id_performer, 
        name.as_deref(), 
        start_date.as_deref(), 
        end_date.as_deref(), 
    ).map_err(|e| format!("Error en la conversion: {}",e))
}

//Para las relaciones entre person y group  
pub fn actualizar_in_group(
    id_person_actual: i64,
    id_group_actual: i64,
    id_person_nuevo: i64,
    id_group_nuevo: i64,
) -> Result<bool, String> {
    let conn = nucleo_dao::dao::conectar_db()
        .map_err(|e| format!("Error conectando la base de datos: {}", e))?;

    nucleo_dao::dao::modificar_in_group(
        &conn,
        id_person_actual,
        id_group_actual,
        id_person_nuevo,
        id_group_nuevo,
    ).map_err(|e| format!("Error modificando relación in_group: {}", e))
}