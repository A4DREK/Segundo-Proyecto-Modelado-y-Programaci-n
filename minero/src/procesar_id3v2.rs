/* En este archivo su objetivo será:
 * 1.- Con la función de poder buscar la ruta, entrar justamente a donde están todos los archivos de música
 * 2.- A partir de las características del ID3, obtenemos la información para los parámetros SQL
 *     de modo que: 
 *     2.1: Deben de haber funciones tales que sean: 
 *          a.- Obtener registro de cada uno de los parámetros que son: 
 *              Artist: A                  
 *              Title: T                    
 *              Album: L                    
 *              Album band: B              
 *              Year: 1950                  
 *              Track: 3 of 7              
 *              Disc number: 1              
 *              Genre: Jazz                
 *              Comment: C                  
 *              Composer: S                
 *              Original artist: O          
 *              Front cover picture: L cover
 *              Artist picture: A          
 * 
 * 
 */

use id3::{Tag, TagLike};
use std::path::Path;
use crate::estructuras::metadatos::MetadatosCancion;

pub fn obtener_datos_id3(path: &Path) -> Result<MetadatosCancion, String> {

    //Leemos la etiqueta ID3 del archivo
    let tag = Tag::read_from_path(path)
        .map_err(|e| format!("Error al leer la etiqueta ID3 en: {:?}: {}", path, e))?;

    //Creamos la variable con el struct de metadatos
    let mut metadatos = MetadatosCancion {
        route: path.to_path_buf(),
        ..Default::default()
    };

    //Se inician a agregar cada uno de los parámetros del archivo ID3
    metadatos.title = tag.title().map(|s| s.to_string());
    metadatos.artist = tag.artist().map(|s| s.to_string());
    metadatos.album = tag.album().map(|s| s.to_string());

    metadatos.artist_album = tag
        .album_artist()
        .map(|s| s.to_string())
        .or_else(|| tag.get("TPE2"). and_then(|f| f.content().text())
            .map(|s| s.to_string()));

    metadatos.year = tag
        .year()
        .or_else(|| tag.date_recorded().map(|d| d.year))
        .or_else(|| {
            tag.get("TDRC")
                .and_then(|f| f.content().text())
                .and_then(|s| s.chars().take(4).collect::<String>().parse::<i32>().ok())
        });

    metadatos.genre = tag.genre_parsed().map(|s| s.to_string());

    metadatos.compositor = tag.get("TCOM").and_then(|frame| frame.content().text())
        .map(|s| s.to_string());

    metadatos.original_artist = tag.get("TOPE").and_then(|f| f.content().text())
        .map(|s| s.to_string());


    if let Some(track) = tag.track() {
        if let Some(total) = tag.total_tracks() {
            metadatos.track = Some(format!("{:02}/{}", track, total ));
        } else {
            metadatos.track = Some(track.to_string())
        }
    }

    if let Some(commentary) = tag.comments().next() {
        metadatos.comment = Some(commentary.text.clone());
    }

    metadatos.disc_num = tag.disc();

    //Esta parte se usará para la imagen del album y del artista
    //Uso de la parte de PictureType de la biblioteca misma de id3
    for picture in tag.pictures() {
        use id3::frame::PictureType;
        match picture.picture_type {
            PictureType::CoverFront => {
                metadatos.front_cover = Some(picture.data.clone());
            }
            PictureType::Artist => {
                metadatos.artist_portrait = Some(picture.data.clone());
            }
            _ => {}
        }
    }

    Ok(metadatos)

}

//Inicio de la prueba unitaria
#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use std::path::PathBuf;
   
    //Esta última biblioteca es para crear directorios temporales, como en buscar_ruta.rs
    use std::sync::atomic::{AtomicUsize, Ordering};
    static TEST_COUNTER: AtomicUsize = AtomicUsize::new(0);

    #[test]
    fn prueba_obtener_datos() {

        //Creamos el directorio temporal y la ruta del mp3
        let tmp_dir = crear_dir_temp("id3_proceso");
        let ruta_mp3 = tmp_dir.join("demo.mp3");

        //Incrustamos el MP3 de prueba que esta en el directorio "fixtures"
        static DEMO_MP3: &[u8] = include_bytes!("../../fixtures/demo.mp3");
        fs::write(& ruta_mp3, DEMO_MP3).expect("La extracción falló");

        //Se llama a la función de obtener_datos_id3 para obtener los 13 parámetros del struct
        let metadatos = obtener_datos_id3(&ruta_mp3)
            .expect("Error en la extracción de metadatos");

        //Se realizan las validaciones
        assert_eq!(metadatos.artist.as_deref(), Some("A"));
        assert_eq!(metadatos.title.as_deref(), Some("T"));
        assert_eq!(metadatos.album.as_deref(), Some("L"));
        assert_eq!(metadatos.artist_album.as_deref(), Some("B"));
        assert_eq!(metadatos.year, Some(1950));
        assert_eq!(metadatos.disc_num, Some(1));
        assert_eq!(metadatos.genre.as_deref(), Some("Jazz"));
        assert_eq!(metadatos.comment.as_deref(), Some("C"));
        assert_eq!(metadatos.compositor.as_deref(), Some("S"));
        assert_eq!(metadatos.original_artist.as_deref(), Some("O"));

        //Validación de la pista (debe de ser 3)
        assert!(
            metadatos.track.as_ref().map_or(false, |p| p.contains('3')),
            "El campo debe la pista debe de indicar que es el track 3"
        );

        //Validaciones de las imágenes 
        static COVER_BYTES: &[u8] = include_bytes!("../../fixtures/cover.png");
        static ARTIST_BYTES: &[u8] = include_bytes!("../../fixtures/artist.png");

        assert!(metadatos.front_cover.is_some(), "Debe de contener la portada frontal");
        assert!(metadatos.artist_portrait.is_some(), "Debe de contener la imagen del artista");

        //Verificación de la portada frontal
        if let Some(portrait) = &metadatos.front_cover {
            assert_eq!(portrait, COVER_BYTES, "La portada debe de coincidir con el cover.png")
        }

        //Verificación de la portada del artista 
        if let Some(portrait) = &metadatos.artist_portrait {
            assert_eq!(portrait, ARTIST_BYTES, "La portada del artista debe de coincidir con artist.png");
        }

        let _ = fs::remove_dir_all(tmp_dir);

    }

    fn crear_dir_temp(prefix: &str) -> PathBuf {
        let pid = std::process::id();
        let id_test = TEST_COUNTER.fetch_add(1, Ordering::SeqCst);
        let tmp_dir = std::env::temp_dir().join(format!("minero_{}_{}_{}", prefix, pid, id_test));
        let _ = fs::create_dir_all(&tmp_dir);
        tmp_dir
    }
}