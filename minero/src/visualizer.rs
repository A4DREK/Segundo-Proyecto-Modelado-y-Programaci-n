/* En este archivo, se creará un log en terminal para mostrar todas las canciones 
 * que resulten del minero, esto nos ayudará a dos cosas
 * 1.- Poder correr el minero sin necesidad de la GUI
 * 2.- Tener un registro de todo cuando tengamos la GUI
 */

use crate::estructuras::metadatos::MetadatosCancion;

pub struct LogTabla;

impl LogTabla {
    
    //Imprime la cabecera del registro
    pub fn imprimir_encabezado() {
        let separador = "=".repeat(110);
        let linea = "-".repeat(110);

        println!("\n{}", separador);
        println!("{:^110}", "MINERO MP3 - REPORTE DE EXTRACCIÓN");
        println!("{}", separador);
        println!(
            "| {:<6} | {:<25} | {:<25} | {:<25} | {:<6} | {:<8} |",
            "Pista", "Título", "Artista", "Álbum", "Año", "Estado"
        );
        println!("{}", linea);
    }

    //Imprime una fila correspondiente a una canción procesada
    pub fn imprimir_cancion (metadatos: &MetadatosCancion, exito: bool) {

        let track = metadatos.track.as_deref().unwrap_or("-");
        let title = metadatos.title.as_deref().unwrap_or("Unknown Title");
        let artist = metadatos.artist.as_deref().unwrap_or("Unknown Artist");
        let album = metadatos.album.as_deref().unwrap_or("Unknown Album");

        let year = metadatos
            .year
            .map(|y| y.to_string())
            .unwrap_or_else(|| "-".to_string());

        let state = if exito { "OK" } else { "ERROR" };

        println!(
            "| {:<6} | {:<25} | {:<25} | {:<25} | {:<6} | {:<8} |",
            recortar_texto(track, 6),
            recortar_texto(title, 25),
            recortar_texto(artist, 25),
            recortar_texto(album, 25),
            recortar_texto(&year, 6),
            state
        );
    }

    pub fn imprimir_resumen(total_procesados: usize, exitosos: usize, errores: usize) {
        let separador = "=".repeat(110);
        let linea = "-".repeat(110);

        println!("{}", linea);
        println!(
            " RESUMEN: Total procesados: {} | Exitosos: {} | Con error: {}",
            total_procesados, exitosos, errores
        );
        println!("{}\n", separador);
    }

}

fn recortar_texto(texto: &str, limite: usize) -> String {
    if texto.chars().count() > limite {
        let mut s: String = texto.chars().take(limite - 2).collect();
        s.push_str("..");
        s
    } else {
        texto.to_string()
    }
}

//Inicio de las pruebas unitarias 
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn prueba_recortar_texto_largo() {
        let texto_largo = "Canción con un nombre extremadamente largo";
        let recortado = recortar_texto(texto_largo, 15);
        
        assert_eq!(recortado.chars().count(), 15);
        assert!(recortado.ends_with(".."));
    }

    #[test]
    fn prueba_recortar_texto_corto() {
        let texto_corto = "Hola";
        let resultado = recortar_texto(texto_corto, 10);
        
        assert_eq!(resultado, "Hola");
    }
}