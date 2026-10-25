/* En este archivo ira una estructura la cual contendrá todos los
 * metadatos que puede contener un archivo con la etiqueta 
 * ID3V2.4 esto para que sea más fácil mi vida porque no voy a devolver
 * al minero una tupla de casi 13 elementos lol
 * Y con lo que dijo Canek el viernes, las variables ya serán en Inglés csm 
 */

use std::path::PathBuf;

#[derive(Debug, Default, Clone)]
pub struct MetadatosCancion {
    pub route: PathBuf,
    pub title: Option<String>,
    pub artist: Option<String>,
    pub album: Option<String>,
    pub artist_album: Option<String>,
    pub year: Option<i32>,
    pub track: Option<String>,
    pub disc_num: Option<u32>,
    pub genre: Option<String>,
    pub comment: Option<String>,
    pub compositor: Option<String>,
    pub original_artist: Option<String>,
    pub front_cover: Option<Vec<u8>>,
    pub artist_portrait: Option<Vec<u8>>,

}