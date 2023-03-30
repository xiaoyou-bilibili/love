use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct App {
    pub secret: String,       // 密钥
    pub mongo: String,        // mongo数据库
    pub man_avatar: String,   // 男性头像
    pub woman_avatar: String, // 女性头像
}

pub mod config {
    use crate::lib::config::App;
    use serde_yaml;

    pub fn get_config() -> App {
        let file = std::fs::File::open("app.yaml");
        if file.is_ok() {
            let file = file.unwrap();
            return serde_yaml::from_reader::<std::fs::File, App>(file).unwrap();
        }
        return App{
            secret: "xiaoyou".to_string(),
            mongo:"mongodb://127.0.0.1:27017".to_string(),
            man_avatar: "".to_string(),
            woman_avatar: "".to_string(),
        }
    }
}


#[cfg(test)]
mod tests {
    use crate::lib::config::App;

    #[actix_rt::test]
    async fn get_config() {
        let schma = serde_yaml::from_str::<App>(include_str!("../../app.yaml")).unwrap();
        println!("{:?}", schma);
    }
}