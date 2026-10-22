/* En este archivo dao.rs tendrá todos los métodos (o fn) de las cuales el minero podrá
 * tener todos los métodos necesarios para agregar, eliminar o modificar la base de datos 
 * en otras palabras solamente tendrá los métodos para las consultas SQL. :p
 */

use dirs;
use rusqlite::{params, Connection, Result, OptionalExtension};
use std::{fs, path::PathBuf};

pub fn obtener_ruta_db () -> Result<PathBuf, String> {
    
    /* Aquí dependerá del OS, la dirección variará
     * de modo que en Linux, es en la dirección:
     * ~/.local/share/rolas/
     * y en mi caso en la mac será:
     * ~/Library/Application Support/rolas/
     */

    let mut ruta = dirs::data_dir()
        .ok_or_else(|| "No se pudo obtener el directorio con la base de datos".to_string())?;

    ruta.push("rolas");

    //En caso de no existir el directorio, se creará 
    fs::create_dir_all(&ruta).map_err(|e| e.to_string())?;

    ruta.push("rolas.db");

    Ok(ruta)
}

pub fn conectar_db() -> Result<Connection, Box<dyn std::error::Error>> {

    let ruta = obtener_ruta_db()?;
    let connection = Connection::open(ruta)?;

    connection.execute_batch("PRAGMA foreign_keys = ON;")?;

    Ok(connection)

}

/*
 * Se iniciarán con los métodos para poder manipular la base de datos.
 */

pub fn crear_tablas_db (connection: &Connection) -> Result<()> {
    let sql_plantilla = include_str!("../../base_de_datos/rolas.sql");

    connection.execute_batch(sql_plantilla)?;
    Ok(())
}

//Métodos para crear obtener o crear performers, persons, groups, in_group, albums, rolas
pub fn obtener_crear_performer(
    connection: &Connection, 
    name: Option<&str>, 
    id_type: i64
) -> Result<i64> {

    let final_nombre = verificar_texto(name, "Unknown Performer");

    //Revisar si ya existe el performer
    let mut stmt = connection.prepare(
        "SELECT id_performer FROM performers WHERE name = ?1 AND id_type = ?2"
    )?;

    //Se crea un nuevo ID
    let id_existente: Option<i64> = stmt
        .query_row(params![final_nombre, id_type], |r| r.get(0))
        .optional()?;

    if let Some(id) = id_existente{
        return Ok(id);
    }

    //Se agrega la nueva entrada a la tabla

    connection.execute(
        "INSERT INTO performers (id_type, name) VALUES (?1, ?2)", 
        params![id_type, final_nombre],
    )?;

    //Retorno del Id asignado por el SQLite
    Ok(connection.last_insert_rowid())
}

pub fn obtener_crear_person(
    connection: &mut Connection,
    nombre: Option<&str>,
    stage_name: Option<&str>,
    real_name: Option<&str>,
    birth_date: Option<&str>,
    death_date: Option<&str>,
) -> Result<i64> {

    let final_nombre = verificar_texto(nombre, "Unknown Person");

    //creamos a tx para inicializar la transacción para que ambas tablas estén sincronizadas
    let tx = connection.transaction()?;

    //Ver si está el registro en la tabla performers y que sean además "Persons"
    let id_person = obtener_crear_performer(&tx, Some(final_nombre), 0)?;

    //Intenta agregar en la tabla persons, si el parámetro id_persons ya existe,si no, no hace nada
    tx.execute(
        "INSERT OR IGNORE INTO persons (id_person, stage_name, real_name, birth_date, death_date)
        VALUES (?1, ?2, ?3, ?4, ?5)",
        params![id_person, stage_name, real_name, birth_date, death_date],
    )?;

    //hace el commit de la transacción 
    tx.commit()?;    

    Ok(id_person)
}

pub fn obtener_crear_group(
    connection: &mut Connection,
    nombre: Option<&str>,
    start_date: Option<&str>,
    end_date: Option<&str>,
) -> Result<i64> {

    let final_nombre = verificar_texto(nombre, "Unknown group");

    //Prácticamente se sigue el mismo razonamiento que con la fn de obtener_crear_person

    let tx = connection.transaction()?;

    let id_group = obtener_crear_performer(&tx, Some(final_nombre), 1)?;

    tx.execute(
        "INSERT OR IGNORE INTO groups (id_group, name, start_date, end_date)
         VALUES (?1, ?2, ?3, ?4)",
         params![id_group, final_nombre, start_date, end_date],
    )?;

    tx.commit()?;
    Ok(id_group)

}

pub fn obtener_crear_in_group(
    connection: &Connection,
    id_person: i64,
    id_group: i64,
) -> Result<()> {

    //Se ejecuta la conexión se inserta o se ignora en 
    connection.execute(
        "INSERT OR IGNORE into in_group (id_person, id_group) VALUES (?1, ?2)", 
        params![id_person, id_group],
    )?;

    Ok(())
}

pub fn obtener_crear_album(
    connection: &mut Connection,
    path: &str,
    name: Option<&str>,
    year: Option<i64>,
) -> Result<i64> {

    let final_name = verificar_texto(name, "Unknown Album");

    //Verificamos que el álbum ya exista por su ruta o su nombre
    let mut stmt = connection.prepare(
        "SELECT id_album FROM albums WHERE path = ?1"
    )?;

    let id_existente: Option<i64> = stmt
        .query_row(params![path], |r| r.get(0))
        .optional()?;

    if let Some(id) = id_existente {
        return Ok(id);
    }

    //Si no existe entonces insertamos de forma directa el album a la tabla de albums
    connection.execute(
        "INSERT INTO albums (path, name, year) VALUES (?1, ?2, ?3)",
        params![path, final_name, year]
    )?;

    Ok(connection.last_insert_rowid())
}

pub fn obtener_crear_rola(
    connection: &mut Connection,
    id_performer: i64,
    id_album: i64,
    path: &str,
    title: Option<&str>,
    track: Option<i64>,
    year: Option<i64>,
    genre: Option<&str>,
) -> Result<i64> {
    
    //Si el track no tiene título se le asignará como predeterminado Unknown Title
    let titulo_final = match title {
        Some(t) if !t.trim().is_empty() => t.trim(),
        _ =>  "Unknown Track",
    };

    //Verificar que el track no se encuentre dentro de la tabla 
    let mut stmt = connection.prepare("SELECT id_rola FROM rolas WHERE path = ?1")?;
    let id_existente: Option<i64> = stmt
        .query_row(params![path], |r| r.get(0))
        .optional()?;

    if let Some(id) = id_existente {
        return Ok(id);
    }

    //Si no existe, se agrega el track con el título ya modificado
    connection.execute(
        "INSERT INTO rolas (id_performer, id_album, path, title, track, year, genre)
        VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
        params![id_performer, id_album, path, titulo_final, track, year, genre],
    )?;
    
    Ok(connection.last_insert_rowid())
}

//Métodos para poder modificar las entradas de las tablas
pub fn modificar_performer(
    connection: &Connection,
    id_performer: i64,
    nuevo_nombre: Option<&str>,
) -> Result<bool> {

    let nombre_final = verificar_texto(nuevo_nombre, "Unknown Performer");

    let filas_modificadas = connection.execute(
        "UPDATE performers SET name = ?1 WHERE id_performer = ?2",
        params![nombre_final, id_performer],
    )?;

    Ok(filas_modificadas > 0)
}

pub fn modificar_person(
    connection: &mut Connection,
    id_person : i64,
    nombre: Option<&str>,
    nuevo_stage_name: Option<&str>,
    nuevo_real_name: Option<&str>,
    nuevo_birth_date: Option<&str>,
    nuevo_death_date: Option<&str>,

) -> Result<bool> {

    let tx = connection.transaction()?;

    //Validación de los nombres
    let stage_final = verificar_texto(nuevo_stage_name, "Unknown Person");
    let nombre_final = verificar_texto(nombre, stage_final);

    //Actualizamos las filas en performers
    let fila_modificada = tx.execute(
        "UPDATE performers SET name = ?1 WHERE id_performer = ?2",
        params![nombre_final, id_person],
    )?;

    //Si devuelve falso quiere decir que el ID no existía 
    if fila_modificada == 0 {
        return Ok(false);
    }

    //Actualizamos persons
    tx.execute(
        "UPDATE persons 
         SET stage_name = ?1, real_name = ?2, birth_date = ?3, death_date = ?4 
         WHERE id_person = ?5",
         params![stage_final, nuevo_real_name, nuevo_birth_date, nuevo_death_date, id_person],
    )?;

    tx.commit()?;
    Ok(true)
}

pub fn modificar_group(
    connection: &mut Connection,
    id_group: i64,
    nuevo_name: Option<&str>,
    nueva_start_date: Option<&str>,
    nueva_end_date: Option<&str>,
) -> Result<bool> {

    let tx = connection.transaction()?;

    //Validación del nombre: 
    let nombre_final = verificar_texto(nuevo_name, "Unknown group_name");

    //Actualización de la tabla "performers"
    let filas_modificadas = tx.execute(
        "UPDATE performers SET name = ?1 WHERE id_performer = ?2",
        params![nombre_final, id_group]
    )?;

    if filas_modificadas == 0 {
        return Ok(false);
    }

    //Actualizamos groups 
    tx.execute(
        "UPDATE groups SET name = ?1, start_date = ?2, end_date = ?3 WHERE id_group = ?4",
        params![nombre_final, nueva_start_date, nueva_end_date, id_group]
    )?;

    tx.commit()?;
    Ok(true)
}

pub fn modificar_in_group(
    connection: &mut Connection,
    id_person_actual: i64,
    id_group_actual: i64,
    id_person_nuevo: i64,
    id_group_nuevo: i64,
) -> Result<bool> {
    
    //Revisa que las "referencias no sean iguales"
    if id_group_actual == id_group_nuevo && id_person_actual == id_person_nuevo {
        return Ok(true);
    }

    //Se manda el comando SQL a las tablas para que realicen su respectivo cambio
    let filas_modificadas = connection.execute(
        "UPDATE OR IGNORE in_group
        SET id_person = ?1, id_group = ?2
        WHERE id_person = ?3 AND id_group = ?4",
        params![
            id_person_nuevo, id_group_nuevo, id_person_actual, id_group_actual
        ]
    )?;

    //Retorno si se encontró la relación previa y se realizó con éxito el cambio de valores 
    Ok(filas_modificadas > 0)
}

pub fn modificar_album(
    connection: &mut Connection,
    id_album: i64,
    nuevo_path: Option<&str>,
    nuevo_name: Option<&str>,
    nuevo_year: Option<i64>,
) -> Result<bool> {

    //Verificaciones de los parámetros de entrada
    let nombre_final = verificar_texto(nuevo_name, "Unknown Album");

    //Verificación si el album existe, si sí, se copia el path actual, si no, retorna False
    let path_actual: Option<String> = connection
        .query_row(
            "SELECT path FROM albums WHERE id_album = ?1",
            [id_album],
            |r| r.get(0),
        ).optional()?;

    let path_existente = match path_actual {
        Some(p) => p,
        None => return Ok(false),
    };

    //Verificamos el path si el path es vacío entonces deja el path existente
    let path_final = match nuevo_path {
        Some(p) if !p.trim().is_empty() => p.trim(),
        _ => &path_existente,
    };

    //Se hace la consulta SQL 
    connection.execute(
        "UPDATE albums SET path = ?1, name = ?2, year = ?3 WHERE id_album = ?4",
        params![path_final, nombre_final, nuevo_year, id_album],
    )?;

    Ok(true)

}

pub fn modificar_rola(
    connection: &mut Connection,
    id_rola: i64,
    nuevo_id_performer: Option<i64>,
    nuevo_id_album: Option<i64>,
    nuevo_path: Option<&str>,
    nuevo_title: Option<&str>,
    nuevo_track: Option<i64>,
    nuevo_year: Option<i64>,
    nuevo_genre: Option<&str>
) -> Result<bool> {

    //Obtenemos primero los datos que YA están
    let datos_actuales: Option<(i64, i64, String)> = connection
        .query_row(
            "SELECT id_performer, id_album, path FROM rolas WHERE id_rola = ?1",
            [id_rola],
            |r| Ok((r.get(0)?, r.get(1)?, r.get(2)?)),
        ).optional()?;

    let (performer_actual, album_actual, path_actual) = match datos_actuales {
        Some(datos) => datos,
        None => return Ok(false),
    };

    //Aquí se conserva los valores si es que los datos de entrada son Null o " "
    let id_performer_final = nuevo_id_performer.unwrap_or(performer_actual);
    let id_album_final = nuevo_id_album.unwrap_or(album_actual);

    let path_final = match nuevo_path {
        Some(p) if !p.trim().is_empty() => p.trim(),
        _ => &path_actual
    };

    //Inicia la verificación del texto
    let title_final = verificar_texto(nuevo_title, "Unknown Title");
    let genre_final = nuevo_genre.and_then(|g| {
        let t = g.trim();
        if t.is_empty() {
            None
        } else {
            Some(t)
        }
    });

    connection.execute(
        "UPDATE rolas
        SET id_performer = ?1, id_album = ?2, path = ?3, title = ?4, track = ?5, year = ?6, genre = ?7 WHERE id_rola = ?8", 
        params![id_performer_final, id_album_final, path_final, title_final, nuevo_track, nuevo_year, genre_final, id_rola]
    )?;

    Ok(true)

}
//Función auxiliar para poder verificar que el título de ya sea, el artista, el track o el álbum no sea ""
fn verificar_texto<'a>(texto: Option<&'a str>, texto_predeterminado: &'a str) -> &'a str {

    match texto {
        Some(t) if !t.trim().is_empty() => t.trim(),
        _ => texto_predeterminado,
    }
    
}

#[cfg(test)]
mod test{

    use super::*;
    use rusqlite::Connection;

    //Prueba que muestra que la obtención de la ruta de la base de datos sea la correcta
    #[test]
    fn prueba_obtener_ruta_db() {
        let ruta = obtener_ruta_db().expect("No se pudo obtener la ruta de la db");
        println!("\n[TEST] La Ruta Generada es: {:?}", ruta);

        //Checa si la base de datos se llama rolas.db
        assert_eq!(
            ruta.file_name().unwrap(),
            "rolas.db",
            "El archivo debe de ser rolas.db"
        );

        if let Some(carpeta_padre) = ruta.parent() {
            assert!(
                carpeta_padre.exists(),
                "El directorio padre debe de haber sido creado en el sistema"
            );
        }
    }

    //Prueba para ver si funciona que se conecte a la base de datos y a las llaves (foreign keys)
    #[test]
    fn prueba_conectar_db_y_llaves(){
        let connection = conectar_db().expect("Fallo en la conexión con la base de datos");

        let fk_activadas: i32 = connection
            .query_row("PRAGMA foreign_keys;", [], |r| r.get(0))
            .expect("No se pudo leer el estado PRAGMA foreign_keys");

        println!("[TEST] Estado de las foreign_keys (1 = ON): {}", fk_activadas);
        assert_eq!(
            fk_activadas, 1,
            "Las llaves deben de estar habilitadas"
        );
    }

    //Prueba para ver que funcione ks fn obtener_crear_performer
    #[test]
    fn prueba_obtener_crear_performer() {
        let connection = preparar_db_prueba();

        //Se crea a un primer performer
        let primer_id = obtener_crear_performer(&connection, Some("Latin Mafia"), 1)
            .expect("Error al crear el performer por primera vez");

        assert!(primer_id > 0, "El id generado debe de ser mayor a 0");

        //Se intenta obtener el mismo performer con el mismo nombre y tipo
        let segundo_id = obtener_crear_performer(&connection, Some("Latin Mafia"), 1)
            .expect("Error al consultar un performer existente");

        assert_eq!(
            primer_id, segundo_id, "Debe de retornar el mismo id_performer en lugar de crear un nuevo registro"
        );
        
        //Verificamos que en la tabla performers solo exista un registro
        let conteo: i64 = connection
            .query_row("SELECT COUNT(*) FROM performers", [], |r| r.get(0))
            .expect("Error en el conteo de filas");

        assert_eq!(conteo, 1, "Debe de haber un solo registro en el SQL");
        
        //Creamos otro performer y verificamos que tengan ID distinto
        let tercer_id = obtener_crear_performer(&connection, Some("Martin Garrix"), 0)
            .expect("Error al crear un nuevo performer");

        assert_ne!(
            primer_id, tercer_id,
            "Un performer diferente debe de tener un ID único"
        );

        //Comprobamos que dos datos con el mismo value, tengan registros distintos
        let cuarto_id = obtener_crear_performer(&connection, Some("Los Tigres del Norte"), 1)
            .expect("Error al crear el performer");

        assert_ne!(
            primer_id, cuarto_id,
            "Dos grupos distintos deben de tener ID's diferentes"
        );

        //se agrega el caso donde el nombre sea la cadena vacía
        let vacio_id = obtener_crear_performer(&connection, Some("   "), 0)
            .expect("Error al crear el performer con nombre vacío");

        let nombre_vacio: String = connection
            .query_row(
                "SELECT name FROM performers WHERE id_performer = ?1",
                [vacio_id],
                |r| r.get(0),
            )
            .expect("Debe de existir el performer con nombre vacío");

        assert_eq!(nombre_vacio, "Unknown Performer", "El nombre vacío debe de ser Unknown Performer");
    }

    //test para comprobar la función obtener_crear_persona
    #[test]
    fn prueba_obtener_crear_person() {
        let mut connection = preparar_db_prueba();

        //Se registra a la primera persona
        let primer_id = obtener_crear_person(
            &mut connection, 
            Some("Martin Garrix"),
            Some("Martin Garrix"),
            Some("Martijn Gerard Garritsen"),
            Some("May 12, 1996"), 
            None,
        ).expect("Fallo en la creación de la persona");

        assert!(primer_id > 0, "El id asignado debe de ser mayor a 0");

        //Se verifica que se inserto bien el primer_id en la tabla performers con id_type = 0
        let (id_type, nombre_performer): (i64, String) = connection
            .query_row(
                "SELECT id_type, name FROM performers WHERE id_performer = ?1",
                [primer_id],
                |row| Ok((row.get(0)?, row.get(1)?))
        ).expect("Debe de existir en la tabla performers");

        assert_eq!(id_type, 0, "El id_type debe de ser 0 (Person)");
        assert_eq!(nombre_performer, "Martin Garrix");  

        //Verificar si los datos sí fueron insertados en la tabla persons 
        let (stage_name, real_name, death_date): (Option<String>, Option<String>, Option<String>) = connection
            .query_row(
                "SELECT stage_name, real_name, death_date FROM persons WHERE id_person = ?1",
                [primer_id],
                |r| Ok((r.get(0)?, r.get(1)?, r.get(2)?)),
        ).expect("Debe de existir en la tabla persons");

        assert_eq!(stage_name.as_deref(), Some("Martin Garrix"));
        assert_eq!(real_name.as_deref(), Some("Martijn Gerard Garritsen"));
        assert_eq!(death_date, None, "El resultado debe de ser NULL");

        //Intentar llamar de nuevo con la misma persona
        let segundo_id = obtener_crear_person(
            &mut connection,
            Some("Martin Garrix"),
            Some("Martin Garrix"),
            Some("Martijn Gerard Garritsen"),
            Some("May 12, 1996"), 
            None,
        ).expect("Fallo en la re-consulta de la persona");

        assert_eq!(
            primer_id, 
            segundo_id,
            "Debe de retornar el mismo ID y no un duplicado"
        );

        //Verificamos que la cantidad de entradas en la tabla persons sea efectivamente, 1

        let total_performers: i64 = connection
            .query_row("SELECT COUNT(*) FROM performers", [], |r| r.get(0),)
            .unwrap();
        let total_persons: i64 = connection
            .query_row("SELECT COUNT(*) FROM persons", [], |r| r.get(0))
            .unwrap();

        assert_eq!(total_performers, 1, "Solo debe de existir un solo performer");
        assert_eq!(total_persons, 1, "Solo debe de existir una sola persona");

    }

    #[test]
    fn prueba_obtener_crear_group() {
        let mut connection = preparar_db_prueba();

        let id_daft_punk = obtener_crear_group(
            &mut connection,
            Some("Daft Punk"),
            Some("1993"),
            Some("2021"),
        ).expect("Error creando el grupo de Daft Punk");

        assert!(id_daft_punk > 0, "El ID debe de ser mayor a 0");

        //Insertar un grupo activo sin fecha de fin 
        let id_blink = obtener_crear_group(
            &mut connection,
            Some("Blink-182"),
            Some("1992"),
            None,
        ).expect("Error al crear el grupo");

        assert_ne!(id_daft_punk, id_blink, "Grupos distintos deben de tener un ID distinto");

        //Comprobamos que si creamos otra entrada con los mismos datos, nos devuelve el mismo ID
        let prueba_id = obtener_crear_group(
            &mut connection,
            Some("Daft Punk"),
            Some("1993"),
            Some("2021"),
        ).expect("Error creando el grupo de Daft Punk");

        assert_eq!(id_daft_punk, prueba_id, "Deben de tener el mismo ID ya id_existente");

        //Verificar que los grupos tengan el id_type de group (1)

        let id_type: i64 = connection
            .query_row(
                "SELECT id_type FROM performers WHERE id_performer = ?1",
                [id_daft_punk],
                |r| r.get(0)
        ).unwrap();

        assert_eq!(id_type, 1, "El id en los performers debe de ser 1");
    }

    #[test]
    fn prueba_obtener_crear_in_group() {
        let mut connection = preparar_db_prueba();

        //Creamos a una persona (John Lennon)
        let id_person = obtener_crear_person(
            &mut connection,
            Some("John Lennon"),
            Some("John Lennon"),
            Some("John Winston Ono Lennon"),
            Some("Octubre 9 1940"),
            Some("Diciembre 8 1980"),

        ).expect("Error al crear a la persona");

        //Creamos el grupo (The Beatles)
        let id_group = obtener_crear_group(
            &mut connection,
            Some("The Beatles"),
            Some("1960"),
            Some("1969"),
        ).expect("Error eal crear el grupo");

        //Asociamos a la persona con el grupo
        obtener_crear_in_group(&connection, id_person, id_group)
            .expect("Error al relacionar la persona con el grupo");

        //Verificamos que la relación se haya creado de forma exitosa
        let existe: bool = connection
            .query_row(
                "SELECT EXISTS(SELECT 1 FROM in_group WHERE id_person = ?1 AND id_group = ?2)",
                params![id_person, id_group],
                |r| r.get(0),
        ).unwrap();

        assert!(existe, "La relación debe de existir en la tabla in_group");
    }

    #[test]
    fn prueba_obtener_crear_album() {
        let mut connection =  preparar_db_prueba();

        //Obtenemos la cantidad de álbumes totales al inicio (Esto por el album 0 que marca el SQL)
        let albums_iniciales: i64 = connection
            .query_row("SELECT COUNT(*) FROM albums", [], |r| r.get(0))
            .unwrap();

        //Creamos primero un álbum 
        let primer_album = obtener_crear_album(
            &mut connection,
            "/musica/daft_punk/discovery",
            Some("Discovery"),
            Some(2001),
        ).expect("Error al crear el álbum");

        assert!(primer_album > 0, "El id debe de ser un número positivo");

        //verificar que la entrada esté en la tabla albums
        let (name, year): (String, Option<i64>) = connection
            .query_row(
                "SELECT name, year FROM albums WHERE id_album = ?1",
                [primer_album],
                |r| Ok((r.get(0)?, r.get(1)?)),
            ).expect("El álbum debe de existir en la tabla albums");

        assert_eq!(name, "Discovery", "El álbum debe de llamarse Discovery");
        assert_eq!(year, Some(2001), "El año debe de ser 2001");

        //Verificar la creación de un álbum sin año de lanzamiento 
        let segundo_album = obtener_crear_album(
            &mut connection,
            "/musica/desconocido/album_desconocido",
            Some("Album Desconocido"),
            None
        ).expect("Error al crear el álbum");

        assert_ne!(primer_album, segundo_album, "Álbumes diferentes deben de tener diferente ID");

        //Verificar que el año sea NULL en el segundo álbum
        let null_year: Option<i64> = connection
            .query_row(
                "SELECT year FROM albums WHERE id_album = ?1",
                [segundo_album],
                |r| r.get(0),
            ).unwrap();
        
        assert_eq!(null_year, None, "El año debe de ser NULL");

        //Creamos otro "album" con los mismos datos del primero y debe de dar el mismo id
        let tercer_album = obtener_crear_album(
            &mut connection,
            "/musica/daft_punk/discovery",
            Some("Discovery"),
            Some(2001),
        ).expect("Error al crear el álbum");

        assert_eq!(primer_album, tercer_album, "Debe de devolver el mismo Id ya existente");

        //Revisar que en la tabla solamente existan dos entradas
        let total_albums: i64 = connection
            .query_row("SELECT COUNT(*) FROM albums", [], |r| r.get(0))
            .unwrap();

        assert_eq!(total_albums, albums_iniciales +2, "Debe de haber dos álbumes adicionales con respecto al álbum por defecto");
    }

    #[test]
    fn prueba_obtener_crear_rola() {
        let mut connection = preparar_db_prueba();

        //Creamos un artista y un album
        let id_performer = obtener_crear_person(
            &mut connection,
            Some("Daft Punk"),
            Some("Daft Punk"),
            None,
            Some("1993"),
            None,
        ).expect("Error al crear performer");

        let id_album = obtener_crear_album(
            &mut connection,
            "/musica/daft_punk/discovery",
            Some("Discovery"),
            Some(2001),
        ).expect("Error al crear álbum");

        //Agregamos un track al álbum
        //1er Caso, el track sí tiene todos los parámetros
        let id_rola_1 = obtener_crear_rola(
            &mut connection,
            id_performer,
            id_album,
            "/musica/daft_punk/01_one_more_time.mp3",
            Some("One More Time"),
            Some(1),
            Some(2001),
            Some("French House"),
        ).expect("Error al crear rola con título");

        let titulo_1: String = connection
            .query_row("SELECT title FROM rolas WHERE id_rola = ?1", [id_rola_1], |r| r.get(0))
            .unwrap();

        assert_eq!(titulo_1, "One More Time");

        //2ndo Caso, el track no tiene título 
        let id_rola_3 = obtener_crear_rola(
            &mut connection,
            id_performer,
            id_album,
            "/musica/daft_punk/03_pista_espacios.mp3",
            Some("   "), // Cadena en blanco
            Some(3),
            None,
            None,
        ).expect("Error al crear rola con título de espacios");

        let titulo_3: String = connection
            .query_row("SELECT title FROM rolas WHERE id_rola = ?1", [id_rola_3], |r| r.get(0))
            .unwrap();

        assert_eq!(titulo_3, "Unknown Track", "Si el título son espacios en blanco debe guardarse como 'Unknown Track'");


        let id_reintento = obtener_crear_rola(
            &mut connection,
            id_performer,
            id_album,
            "/musica/daft_punk/01_one_more_time.mp3",
            Some("One More Time"),
            Some(1),
            Some(2001),
            Some("French House"),
        ).expect("Error al consultar rola existente");

        assert_eq!(id_rola_1, id_reintento, "Debe retornar el ID existente de la rola sin duplicarla");
}

    #[test]
    fn prueba_modificar_nombre_performer() {
        let connection = preparar_db_prueba();

        //Creamos dos instancias de performers
        let primer_id = obtener_crear_performer(&connection, Some("Latin Mafia"), 1)
            .expect("Error al crear el performer por primera vez");

        //Cambiamos el nombre al primer performer
        let nuevo_primer_id = modificar_performer(&connection, primer_id, Some("Paco Papitas"))
            .expect("Error al modificar el nombre");
        
        assert!(nuevo_primer_id, "El nombre debió de haber cambiado");

        //Verificamos el cambio de nombre
        let nombre_db: String = connection
        .query_row(
            "SELECT name FROM performers WHERE id_performer = ?1",
            [primer_id],
            |r| r.get(0),
        ).unwrap();

        assert_eq!(nombre_db, "Paco Papitas");

        modificar_performer(&connection, primer_id, None).unwrap();

        //Modificamos a que el nombre sea NULL
        let nombre_none: String = connection
            .query_row(
                "SELECT name FROM performers WHERE id_performer = ?1 ", 
                [primer_id], 
                |r| r.get(0)
            ).unwrap();
        
        assert_eq!(nombre_none, "Unknown Performer");

        //Modificar el texto para la cadena vacía 
        modificar_performer(&connection, primer_id, Some("     ")).unwrap();

        let nombre_espacios: String = connection
            .query_row(
                "SELECT name FROM performers WHERE id_performer = ?1",
                [primer_id],
                |r| r.get(0),
            ).unwrap();

        assert_eq!(nombre_espacios, "Unknown Performer");

    }
   
    #[test]
    fn prueba_modificar_person() {
        let mut connection = preparar_db_prueba();

        //Creamos a una persona inicial
        let primer_id = obtener_crear_person(
            &mut connection, 
            Some("Martin Garrix"),
            Some("Martin Garrix"),
            Some("Martijn Garritsen"), 
            Some("1996-05-14"),
            None
        ).expect("Error al crear la persona ");

        //Inician las modificaciones

        let actualizacion = modificar_person(
            &mut connection, 
            primer_id, 
            Some("Martin Garrix"),
            Some("Martin Garrix"),
            Some("Martijn Gerard Garritsen"),
            Some("1996-05-14x"),
            None,
        ).expect("Error en la modificación de la persona");

        assert!(actualizacion, "Debe de marcar como exitosa la modificación");

        //Validamos que la modificación ya realizada sea correcta
        let (real_name, stage_name): (Option<String>, String) = connection
            .query_row(
                "SELECT real_name, stage_name FROM persons WHERE id_person =?1",
                [primer_id],
                |r| Ok((r.get(0)?, r.get(1)?)),
            ).unwrap();

        assert_eq!(real_name.as_deref(), Some("Martijn Gerard Garritsen"));
        assert_eq!(stage_name, "Martin Garrix");

        //Ahora vamos a volar con la función de validación
        modificar_person(
            &mut connection,
            primer_id,
            None,               // Heredará stage_final ("Unknown Person")
            Some("   "),        // Al ser solo espacios, se convierte en "Unknown Person"
            None,               // Borra el nombre real (NULL)
            None,               // Borra la fecha de nacimiento (NULL)
            Some("2020-01-01"), // Asigna fecha de fallecimiento
        ).expect("Error al modificar con la verificación");

        let nombre_actualizado: String = connection
            .query_row(
                "SELECT name FROM performers WHERE id_performer = ?1", 
                [primer_id],
                |r| r.get(0),
            ).unwrap();

        assert_eq!(nombre_actualizado, "Unknown Person");


        //Validar los campos NULL (fallback o fb) y agregados en la tabla "persons"
        let (stage_fb, real_fb, birth_fb, death_fb): (String, Option<String>, Option<String>, Option<String>) = connection
        .query_row(
            "SELECT stage_name, real_name, birth_date, death_date FROM persons WHERE id_person = ?1",
            [primer_id],
            |r| Ok((r.get(0)?, r.get(1)?, r.get(2)?, r.get(3)?)),
        )
        .unwrap();

        assert_eq!(stage_fb, "Unknown Person");
        assert_eq!(real_fb, None);
        assert_eq!(birth_fb, None);
        assert_eq!(death_fb.as_deref(), Some("2020-01-01"));

        //El caso donde no exista el ID
        let resultado_inexistente = modificar_person(
            &mut connection,
            999_999, // ID fuera de rango
            Some("Nombre"),
            Some("Stage"),
            None,
            None,
            None,
            ).expect("La consulta debe ejecutarse sin errores aunque no encuentre el ID");

        assert!(
            !resultado_inexistente,
            "Debe retornar false cuando el id_person no existe en la base de datos"
        );


    }

    #[test]
    fn prueba_modificar_group() {
        let mut connection = preparar_db_prueba();

        let primer_grupo = obtener_crear_group(
            &mut connection,
            Some("Grupo Paquito"),
            Some("2000-01-01"),
            None,
        ).expect("Error en la creación del grupo");

        //Esto es una modificación total de todos los parámetros de primer_grupo
        let actualizacion = modificar_group(
            &mut connection,
            primer_grupo,
            Some("Daft Punk"),
            Some("1993-01-01"),
            Some("2021-02-22")
        ).expect("Error en la modificación del grupo");

        assert!(actualizacion, "Debió de haber sido exitosa la modificación");

        //Verificación en performers
        let nombre_performer_db: String = connection
            .query_row(
                "SELECT name FROM performers WHERE id_performer = ?1", 
                [primer_grupo],
                |r| r.get(0),
            ).unwrap();

        assert_eq!(nombre_performer_db, "Daft Punk");

        //Verificar en groups
        let (nombre_db, start_date, end_date): (String, Option<String>, Option<String>) = connection
            .query_row(
                "SELECT name, start_date, end_date FROM groups WHERE id_group = ?1", 
                [primer_grupo],
                |r| Ok((r.get(0)?, r.get(1)?, r.get(2)?)),
            ).unwrap();

        assert_eq!(nombre_db, "Daft Punk");
        assert_eq!(start_date.as_deref(), Some("1993-01-01"));
        assert_eq!(end_date.as_deref(), Some("2021-02-22"));

        //Caso donde hay puras cadenas vacías y NULL 
        modificar_group(
            &mut connection, 
            primer_grupo,
            Some(" "), 
            None,
            None
        ).expect("Error en la modificación de datos");

        let nombre_verificado_performer: String = connection
            .query_row(
                "SELECT name FROM performers WHERE id_performer = ?1",
                [primer_grupo],
                |r| r.get(0),
            ).unwrap();
        
        assert_eq!(nombre_verificado_performer, "Unknown group_name");

        //Validar en groups
        let (nombre_verificado, start_null, end_null): (String, Option<String>, Option<String>) = connection
            .query_row(
                "SELECT name, start_date, end_date FROM groups WHERE id_group = ?1",
                [primer_grupo],
                |r| Ok((r.get(0)?, r.get(1)?,  r.get(2)?))
            ).unwrap();

        assert_eq!(nombre_verificado, "Unknown group_name");
        assert_eq!(start_null, None);
        assert_eq!(end_null, None);

        //Verificar que no se pueda realizar dentro de un rango no existente
        let resultado_inexistente = modificar_group(
            &mut connection,
            999_999, // ID fuera de rango
            Some("Grupo Inexistente"),
            None,
            None,
        ).expect("La consulta debe ejecutarse sin errores aunque no encuentre filas");

        assert!(
            !resultado_inexistente,
            "Debe de retornar false cuando el id_group es inexistente en la db"
        );


    }
    
    #[test]
    fn prueba_modificar_in_group() {
        let mut connection = preparar_db_prueba();

        //Creamos a las personas y grupo
        let primer_persona = obtener_crear_person(
            &mut connection, 
            Some("Persona1"),
            Some("Artista1"),
            Some("Persona1"),
            Some("2000-01-01"),
            None,
        ).expect("Error al crear la persona");

        let segunda_persona = obtener_crear_person(
            &mut connection,
            Some("Persona2"),
            Some("Artista2"),
            Some("Persona2"),
            Some("1999-12-12"),
            None,
        ).expect("Error al crear la persona");

        let primer_grupo = obtener_crear_group(
            &mut connection, 
            Some("Grupo1"), 
            Some("2006-12-02"), 
            None
        ).expect("Error al crear el grupo");

        let segundo_grupo = obtener_crear_group(
            &mut connection,
            Some("Grupo2"),
            Some("2010-24-05"),
            Some("2014-10-02"),
        ).expect("Error al crear el grupo");

        //Inicia las relaciones en la tabla in_group

        obtener_crear_in_group(&connection, primer_persona, primer_grupo)
        .expect("Error en la relación de la tabla");

        let modificacion_relacion = modificar_in_group(
            &mut connection, 
            primer_persona, 
            primer_grupo, 
            segunda_persona, 
            segundo_grupo,
        ).expect("Error en la nueva relación");

        assert!(modificacion_relacion, "La modificación debió realizarse con éxito");

        //Checa si la primer persona ya no está en el primer grupo
        let persona1_grupo1: bool = connection
            .query_row(
                "SELECT EXISTS(SELECT 1 FROM in_group WHERE id_person = ?1 AND id_group = ?2)",
                [primer_persona, segundo_grupo ],
                |r| r.get(0),
            ).unwrap();

        assert!(!persona1_grupo1);

        //Checa si. la segunda persona ya está en el primer grupo 

        let persona2_grupo1: bool = connection
            .query_row(
                "SELECT EXISTS(SELECT 1 FROM in_group WHERE id_person = ?1 AND id_group = ?2)",
                [segunda_persona, segundo_grupo],
                |r| r.get(0),
            ).unwrap();

        assert!(persona2_grupo1);

        //Intentar modificar una relación inexistente
        let resultado_inexistente = modificar_in_group(
            &mut connection, 
            234, 
            primer_grupo,
            primer_persona,
            primer_grupo
        ).unwrap();

        assert!(
            !resultado_inexistente,
            "Debe de retornar FALSE ya que la relación no existe"
        );  

    }
    
    #[test]
    fn prueba_modificar_album() {
        
        let mut connection = preparar_db_prueba();

        let album_inicial = obtener_crear_album(
            &mut connection,
            "/musica/tmp/discovery",
            Some("Discovery"),
            Some(2001),
        ).expect("Error al crear el álbum");

        //Si el álbum fue movido a otra carpeta 
        let modificacion = modificar_album(
            &mut connection, 
            album_inicial, 
            Some("/musica/daft_punk/2001_discovery"),
            Some("Discovery (Remastered)"),
            Some(2001),
        ).expect("Error al modificar el álbum");

        assert!(modificacion, "Se debe de confirmar que se modificó el álbum");

        let (path_db, name_db, year_db): (String, String, Option<i64>) = connection
            .query_row(
                "SELECT path, name, year FROM albums WHERE id_album = ?1",
                [album_inicial],
                |r| Ok((r.get(0)?, r.get(1)?, r.get(2)?))
            ).unwrap();

        assert_eq!(path_db, "/musica/daft_punk/2001_discovery");
        assert_eq!(name_db, "Discovery (Remastered)");
        assert_eq!(year_db, Some(2001));

        //Verificación de que si la ruta es NULL, se deja la ruta que ya está 

        modificar_album(
            &mut connection,
            album_inicial,
            None, 
            Some("   "), 
            None,        
        )
        .expect("Error al modificar metadatos");

        let (path_conservado, name_verificado, year_null): (String, String, Option<i64>) = connection
            .query_row(
                "SELECT path, name, year FROM albums WHERE id_album = ?1",
                [album_inicial],
                |r| Ok((r.get(0)?, r.get(1)?, r.get(2)?)),
            ).unwrap();

        assert_eq!(path_conservado, "/musica/daft_punk/2001_discovery");
        assert_eq!(name_verificado, "Unknown Album");
        assert_eq!(year_null, None);

        //Caso donde el id sea inexistente
        let resultado_inexistente = modificar_album(
            &mut connection,
            999_999,
            Some("/ruta/falsa"),
            Some("Album Inexistente"),
            None,
        ).unwrap();

        assert!(!resultado_inexistente, "Debe retornar false si el id_album no existe");

    }
   
    #[test]
    fn prueba_modificar_rolas() {
        let mut connection = preparar_db_prueba();

        let performer_1 = obtener_crear_person(
            &mut connection, 
            Some("Nombre1"), 
            Some("stage_name1"),
            None,
            None,
            None
        ).unwrap();

        let performer_2 = obtener_crear_person(
            &mut connection, 
            Some("Nombre2"),
            Some("stage_name2"),
            None,
            None,
            None,
        ).unwrap();


        let album1 = obtener_crear_album(
            &mut connection,
            "/musica/album1", 
            Some("album"),
            Some(2001),
        ).unwrap();

        let album2 = obtener_crear_album(
            &mut connection,
            "/musica/album2",
            Some("album2"),
            Some(2020),
        ).unwrap();

        let id_rola = obtener_crear_rola(
            &mut connection,
            performer_1,
            album1,
            "/musica/album1/01_one_more_time.mp3",
            Some("One More Time"),
            Some(1),
            Some(2001),
            Some("French House"),
        ).unwrap();

        let modificado = modificar_rola(
            &mut connection,
            id_rola,
            Some(performer_2), // Cambia artista
            Some(album2),     // Cambia álbum
            Some("/musica/album2/01_music_sounds.mp3"),
            Some("Rola nueva"),
            Some(1),
            Some(1998),
            Some("French House"),
        ).expect("Error al reasignar FKs en la rola");

        assert!(modificado);

        let (p_db, a_db, title_db): (i64, i64, String) = connection
            .query_row(
                "SELECT id_performer, id_album, title FROM rolas WHERE id_rola = ?1",
                [id_rola],
                |r| Ok((r.get(0)?, r.get(1)?, r.get(2)?)),
            ).unwrap();
        
        assert_eq!(p_db, performer_2);
        assert_eq!(a_db, album2);
        assert_eq!(title_db, "Rola nueva");

        //Conserva las foreign keys, usando el parámetro None, debe de conservarse los datos
        modificar_rola(
            &mut connection,
            id_rola, 
            None,
            None,
            None,
            Some("   "), 
            None,
            None, None
        ).expect("Error al modificar ls valores de la rola");

        let (p_conservado, a_conservado, title_verificado): (i64, i64, String) = connection
            .query_row(
                "SELECT id_performer, id_album, title FROM rolas WHERE id_rola = ?1",
                [id_rola],
                |r| Ok((r.get(0)?, r.get(1)?, r.get(2)?)),
            ).unwrap();

        assert_eq!(p_conservado, performer_2);
        assert_eq!(a_conservado, album2);
        assert_eq!(title_verificado, "Unknown Title");

        //Caso de un id_inexistente
        let id_performer_inexistente = 999_999;
        let resultado_error_fk = modificar_rola(
            &mut connection,
            id_rola,
            Some(id_performer_inexistente),
            None,
            None,
            Some("Título Validación FK"),
            None,
            None,
            None,
        );

        assert!(
            resultado_error_fk.is_err(),
            "Debe fallar debido a la restricción de Foreign Key en SQLite"
        );

    }
    //Fn auxiliar para la prueba unitaria
    fn preparar_db_prueba() -> Connection {
        let connection = Connection::open_in_memory().expect("No se puede crear la bse de datos en memoria");
        connection.execute_batch("PRAGMA foreign_keys = ON;").unwrap();

        let sql_plantilla = include_str!("../../base_de_datos/rolas.sql");

        connection.execute_batch(sql_plantilla).unwrap();

        connection
    }

}