/* En este archivo dao.rs tendrá todos los métodos (o fn) de las cuales el minero podrá
 * tener todos los métodos necesarios para agregar, eliminar o modificar la base de datos 
 * en otras palabras solamente tendrá los métodos para las consultas SQL. :p
 */

use dirs;
use rusqlite::{Connection, Result, params, OptionalExtension};
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
    name: &str, 
    id_type: i64
) -> Result<i64> {

    //Revisar si ya existe el performer
    let mut stmt = connection.prepare(
        "SELECT id_performer FROM performers WHERE name = ?1 AND id_type = ?2"
    )?;

    //Se crea un nuevo ID
    let id_existente: Option<i64> = stmt
        .query_row(params![name, id_type], |row| row.get(0))
        .optional()?;

    if let Some(id) = id_existente{
        return Ok(id);
    }

    //Se agrega la nueva entrada a la tabla

    connection.execute(
        "INSERT INTO performers (id_type, name) VALUES (?1, ?2)", 
        params![id_type, name],
    )?;

    //Retorno del Id asignado por el SQLite
    Ok(connection.last_insert_rowid())
}

//Método para obtener o crear una persona 
pub fn obtener_crear_person(
    connection: &mut Connection,
    nombre: &str,
    stage_name: Option<&str>,
    real_name: Option<&str>,
    birth_date: Option<&str>,
    death_date: Option<&str>,
) -> Result<i64> {

    //creamos a tx para inicializar la transacción para que ambas tablas estén sincronizadas
    let tx = connection.transaction()?;

    //Ver si está el registro en la tabla performers y que sean además "Persons"
    let id_person = obtener_crear_performer(&tx, nombre, 0)?;

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
    nombre: &str,
    start_date: Option<&str>,
    end_date: Option<&str>,
) -> Result<i64> {

    //Prácticamente se sigue el mismo razonamiento que con la fn de obtener_crear_person

    let tx = connection.transaction()?;

    let id_group = obtener_crear_performer(&tx, nombre, 1)?;

    tx.execute(
        "INSERT OR IGNORE INTO groups (id_group, name, start_date, end_date)
         VALUES (?1, ?2, ?3, ?4)",
         params![id_group, nombre, start_date, end_date],
    )?;

    tx.commit()?;
    Ok(id_group)

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
            .query_row("PRAGMA foreign_keys;", [], |row| row.get(0))
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
        let primer_id = obtener_crear_performer(&connection, "Latin Mafia", 1)
            .expect("Error al crear el performer por primera vez");

        assert!(primer_id > 0, "El id generado debe de ser mayor a 0");

        //Se intenta obtener el mismo performer con el mismo nombre y tipo
        let segundo_id = obtener_crear_performer(&connection, "Latin Mafia", 1)
            .expect("Error al consultar un performer existente");

        assert_eq!(
            primer_id, segundo_id, "Debe de retornar el mismo id_performer en lugar de crear un nuevo registro"
        );
        
        //Verificamos que en la tabla performers solo exista un registro
        let conteo: i64 = connection
            .query_row("SELECT COUNT(*) FROM performers", [], |row| row.get(0))
            .expect("Error en el conteo de filas");

        assert_eq!(conteo, 1, "Debe de haber un solo registro en el SQL");
        
        //Creamos otro performer y verificamos que tengan ID distinto
        let tercer_id = obtener_crear_performer(&connection, "Martin Garrix", 0)
            .expect("Error al crear un nuevo performer");

        assert_ne!(
            primer_id, tercer_id,
            "Un performer diferente debe de tener un ID único"
        );

        //Comprobamos que dos datos con el mismo value, tengan registros distintos
        let cuarto_id = obtener_crear_performer(&connection, "Los Tigres del Norte", 1)
            .expect("Error al crear el performer");

        assert_ne!(
            primer_id, cuarto_id,
            "Dos grupos distintos deben de tener ID's diferentes"
        );

    }

    //test para comprobar la función obtener_crear_persona
    #[test]
    fn prueba_obtener_crear_person() {
        let mut connection = preparar_db_prueba();

        //Se registra a la primera persona
        let primer_id = obtener_crear_person(
            &mut connection, 
            "Martin Garrix",
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
                |row| Ok((row.get(0)?, row.get(1)?, row.get(2)?)),
        ).expect("Debe de existir en la tabla persons");

        assert_eq!(stage_name.as_deref(), Some("Martin Garrix"));
        assert_eq!(real_name.as_deref(), Some("Martijn Gerard Garritsen"));
        assert_eq!(death_date, None, "El resultado debe de ser NULL");

        //Intentar llamar de nuevo con la misma persona
        let segundo_id = obtener_crear_person(
            &mut connection,
            "Martin Garrix",
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
            "Daft Punk",
            Some("1993"),
            Some("2021"),
        ).expect("Error creando el grupo de Daft Punk");

        assert!(id_daft_punk > 0, "El ID debe de ser mayor a 0");

        //Insertar un grupo activo sin fecha de fin 
        let id_blink = obtener_crear_group(
            &mut connection,
            "Blink-182",
            Some("1992"),
            None,
        ).expect("Error al crear el grupo");

        assert_ne!(id_daft_punk, id_blink, "Grupos distintos deben de tener un ID distinto");

        //Comprobamos que si creamos otra entrada con los mismos datos, nos devuelve el mismo ID
        let prueba_id = obtener_crear_group(
            &mut connection,
            "Daft Punk",
            Some("1993"),
            Some("2021"),
        ).expect("Error creando el grupo de Daft Punk");

        assert_eq!(id_daft_punk, prueba_id, "Deben de tener el mismo ID ya id_existente");

        //Verificar que los grupos tengan el id_type de group (1)

        let id_type: i64 = connection
            .query_row(
                "SELECT id_type FROM performers WHERE id_performer = ?1",
                [id_daft_punk],
                |row| row.get(0)
        ).unwrap();

        assert_eq!(id_type, 1, "El id en los performers debe de ser 1");
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