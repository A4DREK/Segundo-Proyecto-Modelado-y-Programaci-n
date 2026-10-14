/* Se agregarán cada una de las estructuras de las tablas del SQL, para poder hacer el resto de cosas */
use std::convert::TryFrom;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Types  {
    Person = 0,
    Group = 1,
    Unknown = 2,
}

//Checa que el int dado corresponda con el Type
impl TryFrom<i64> for Types {
    type Error = String;

    fn try_from(value: i64) -> Result<Self, Self::Error> {
        match value {
            0 => Ok(Types::Person),
            1 => Ok(Types::Group),
            2 => Ok(Types::Unknown),
            _ => Err(format!("Type invalido: {}", value)),
        }
    }
}


//Estructura de la tabla performers del sql
#[derive (Debug, Clone)]
pub struct Performer {
    pub id_performer: i64,
    pub id_type: Option<Types>,
    pub nombre: String,
}

//Estructura de la tabla persons
#[derive(Debug, Clone)]
pub struct Person {
    pub id_person: i64,
    pub stage_name: String,
    pub real_name: String,
    pub birth_date: Option<String>,
    pub death_date: Option<String>,
}

//Estructura de la tabla Groups 
#[derive(Debug, Clone)]
pub struct Group {
    pub id_group: i64,
    pub name: String,
    pub start_date: Option<String>,
    pub end_date: Option<String>,
}

//Estructura de la tabla in_groups}
#[derive(Debug, Clone)]
pub struct InGroup {
    pub id_person: i64,
    pub id_group: i64,
}

//Estructura de la tabla Albums 
#[derive(Debug, Clone)]
pub struct Album {
    pub id_album: i64,
    pub path: String,
    pub name: String,
    pub year: Option<i64>,
}

//Estructura de la tabla principal rolas
#[derive(Debug, Clone)]
pub struct Rola {
    pub id_rola: i64,
    pub id_performer: Option<i64>,
    pub id_album: Option<i64>,
    pub path: String,
    pub title: String,
    pub track: Option<i64>,
    pub year: Option<i64>,
    pub genre: Option<String>,
}

