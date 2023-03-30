use anyhow::Result;
use mongodb::bson::oid::ObjectId;
use mongodb::bson::Document;
use mongodb::results::{DeleteResult, UpdateResult};
use mongodb::{bson, Client, Database, options::ClientOptions, Cursor};
use serde::de::DeserializeOwned;
use serde::Serialize;
// 修复异步cursor method not found的问题
use futures::StreamExt;
use mongodb::options::FindOptions;

#[derive(Clone)]
pub struct DbServer {
    db: Database,
}

impl DbServer {
    // 初始化mongo数据库
    pub async fn build(url: &str, db: &str) -> DbServer {
        let client_options = ClientOptions::parse(url).await.unwrap();

        let client = Client::with_options(client_options).unwrap();
        DbServer {
            db: client.database(db),
        }
    }

    // 字符串转换为ObjectId
    pub fn str_to_object_id(&self, id: &str) -> Result<ObjectId> {
        Ok(ObjectId::parse_str(id)?)
    }

    // cursor转换为数组
    async fn cursor_to_vec<T>(&self, mut cursor: Cursor<Document>) -> Vec<T>
        where T: DeserializeOwned,
    {
        // 初始化数组
        let mut result = Vec::new();
        // 遍历所有cursor
        while let Some(doc) = cursor.next().await {
            if let Ok(data) = doc {
                if let Ok(t) = bson::from_bson(bson::Bson::Document(data)) {
                    result.push(t);
                }
            }
        }
        return result;
    }

    // 插入数据
    pub async fn insert_one<T>(&self, collection: &str, data: T) -> Result<String>
    where
        T: Serialize,
    {
        let result = self.db.collection(collection).insert_one(data, None).await?;
        Ok(result.inserted_id.as_object_id().unwrap().to_hex())
    }

    // 查询数据
    pub async fn find_data<T>(&self, collection: &str, filter: Option<Document>, options: Option<FindOptions>) -> Result<Vec<T>>
    where
        T: DeserializeOwned,
    {
        // 查询数据
        let cursor = self.db.collection(collection).find(filter, options).await?;
        Ok(self.cursor_to_vec(cursor).await)
    }

    // 更新数据
    pub async fn update_data<T>(
        &self,
        collection: &str,
        filter: Document,
        data: Document,
    ) -> Result<UpdateResult>
    where
        T: DeserializeOwned,
    {
        let result = self
            .db
            .collection::<T>(collection)
            .update_one(filter, data, None).await?;
        Ok(result)
    }

    // 删除数据
    pub async fn delete_one<T>(&self, collection: &str, filter: Document) -> Result<DeleteResult>
    where
        T: DeserializeOwned,
    {
        let result = self
            .db
            .collection::<T>(collection)
            .delete_one(filter, None).await?;
        Ok(result)
    }

    // 聚合操作
    pub async fn aggregate<T>(&self, collection: &str, pipeline: impl IntoIterator<Item = Document>) -> Result<Vec<T>>
        where T:DeserializeOwned {
        // 查询数据
        let cursor = self.db.collection::<T>(collection).aggregate(pipeline, None).await?;
        Ok(self.cursor_to_vec(cursor).await)
    }
}

#[cfg(test)]
mod tests {
    use crate::lib::db::DbServer;
    use mongodb::bson::oid::ObjectId;
    use mongodb::{bson, bson::doc, Client};
    use serde::{Deserialize, Serialize};

    #[derive(Debug, Serialize, Deserialize)]
    struct Book {
        title: String,
        author: String,
    }

    async fn new_db() -> DbServer{
       return DbServer::build("mongodb://127.0.0.1:27017", "love").await;
    }

    #[actix_rt::test]
    async fn insert_data() {
        let db = new_db().await;
        let res = db.insert_one(
                "books",
                Book {
                    title: "测试".to_string(),
                    author: "小游".to_string(),
                },
            ).await.unwrap();
        println!("{}", res);
    }

    #[actix_rt::test]
    async fn get_data() {
        let db = new_db().await;

        let res = db
            .find_data::<Book>(
                "books",
                Some(doc! { "_id": db.str_to_object_id("63ff517bbf2191f0b682655b").unwrap() }),
                None,
            ).await.unwrap();
        println!("{:?}", res);
    }

    #[actix_rt::test]
    async fn update_data() {
        let db = new_db().await;
        let res = db.update_data::<Book>(
            "books",
            doc! { "_id": db.str_to_object_id("63ff51115576ae4feda184f4").unwrap() },
            doc! { "$set": { "title": "测试21123" } },
        ).await;
        println!("{:?}", res);
    }

    #[actix_rt::test]
    async fn delete_data() {
        let db = new_db().await;
        let res = db.delete_one::<Book>("books", doc! {"title": "测试21123"}).await;
        println!("{:?}", res);
    }

    #[actix_rt::test]
    async fn delete_aggretaion() {
        #[derive(Serialize, Deserialize, Debug)]
        pub struct Res {
            pub _id: String,
            pub values: Vec<String>,
        }
        let db = new_db().await;
        let res = db.aggregate::<Res>("task", vec![
            doc! { "$group": { "_id": "$tag", "values": { "$addToSet": "$tag" } } }
        ]).await;
        println!("{:?}", res);
    }
}
