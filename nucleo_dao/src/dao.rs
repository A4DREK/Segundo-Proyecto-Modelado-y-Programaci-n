/* En este archivo dao.rs tendrá todos los métodos (o fn) de las cuales el minero podrá
 * tener todos los métodos necesarios para agregar, eliminar o modificar la base de datos 
 * en otras palabras solamente tendrá los métodos para las consultas SQL. :p
 */

use dirs;
use rusqlite::{Connection, Result};
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


#[cfg(test)]
mod test{
    use super::*;

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
}