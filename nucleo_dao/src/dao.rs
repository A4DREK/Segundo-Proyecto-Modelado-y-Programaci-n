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
    nombre: &str, 
    id_type: i64
) -> Result<i64> {

    //Revisar si ya existe el performer
    let mut stmt = connection.prepare(
        "SELECT id_performer FROM performers WHERE name = ?1 AND id_type = ?2"
    )?;

    let id_existente: Option<i64> = stmt
        .query_row(params![nombre, id_type], |row| row.get(0))
        .optional()?;

    if let Some(id) = id_existente{
        return Ok(id);
    }

    connection.execute(
        "INSERT INTO performers (id_type, name) VALUES (?1, ?2)", 
        params![id_type, nombre],
    )?;

    //Retorno del Id asignado por el SQLite
    Ok(connection.last_insert_rowid())
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

    //Fn auxiliar para la prueba unitaria
    fn preparar_db_prueba() -> Connection {
        let connection = Connection::open_in_memory().expect("No se puede crear la bse de datos en memoria");
        connection.execute_batch("PRAGMA foreign_keys = ON;").unwrap();

        let sql_plantilla = include_str!("../../base_de_datos/rolas.sql");

        connection.execute_batch(sql_plantilla).unwrap();

        connection
    }
}