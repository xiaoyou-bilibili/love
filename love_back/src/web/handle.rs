use crate::lib::config::config::get_config;
use crate::web::model::{
    AddCountDownReq, AppSetting, AppState, CommentInfo, CountDown, DynamicComment, DynamicInfo,
    HandleResult, NoteInfo, Response, TaskInfo, UpdateTaskReq,
};
use axum::extract::Multipart;
use axum::extract::{Extension, Path, Query};
use axum::Json;
use chrono::{Datelike, Local, NaiveDate};
use image::{load_from_memory, ImageOutputFormat};
use log::{error, info};
use mongodb::bson::{doc, Document};
use mongodb::options::FindOptions;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs::File;
use std::io::{Cursor, Write};

// 倒计时
const COLLECTION_COUNT_DOWN: &str = "count_down";
const COLLECTION_TASK: &str = "task";
const COLLECTION_DYNAMIC: &str = "dynamic";
const COLLECTION_NOTE: &str = "note";
const COLLECTION_COMMENT: &str = "comment";

// 响应测试
pub async fn pong() -> HandleResult<String> {
    Response::ok("pong".to_string())
}

// 文件上传请求
pub async fn upload_file(mut multipart: Multipart) -> HandleResult<String> {
    // 获取一下文件内容
    while let Some(field) = multipart.next_field().await.unwrap() {
        let name = field.name().unwrap().to_string();
        // 我们就只获取file字段
        if name != "file" {
            continue;
        }
        // 获取文件名
        let filename = field.file_name().unwrap().to_string();
        // 获取文件后缀
        let ext = filename.split('.').last().unwrap().to_string();
        info!("file name is {}, ext is {}", filename, ext);
        // 生成一个一个UUID
        let uuid = uuid::Uuid::new_v4().to_string();
        let new_file = format!("static/{}.{}", uuid, ext);
        let new_file_compose = format!("static/compose/{}.{}", uuid, ext);
        info!("new file is {}", new_file);
        // 获取文件内容
        let data = field.bytes().await.unwrap();
        // 图片压缩
        let mut buf = Cursor::new(Vec::new());
        let img = load_from_memory(data.clone().as_ref());
        if let Err(e) = img {
            return Response::err(format!("加载图片失败 {}", e).as_str());
        }
        if let Err(e) = img.unwrap().write_to(&mut buf, ImageOutputFormat::Jpeg(10)) {
            return Response::err(format!("压缩图片失败 {}", e).as_str());
        }

        // 写入文件
        return if let Ok(mut file) = File::create(new_file.to_string()) {
            // 写入文件
            file.write_all(&data).unwrap();
            // 再写入压缩文件
            if let Ok(mut file) = File::create(new_file_compose) {
                file.write_all(&buf.into_inner()).unwrap();
            }
            Response::ok(new_file)
        } else {
            Response::err("上传失败")
        };
    }
    Response::err("上传失败")
}

// 获取倒计时
pub async fn get_count_down(
    Extension(app_state): Extension<AppState>,
) -> HandleResult<Vec<CountDown>> {
    let mut result = Vec::new();
    // 获取所有倒计时
    let res = app_state
        .db
        .find_data::<AddCountDownReq>(COLLECTION_COUNT_DOWN, None, None)
        .await;
    if let Err(e) = res {
        return Response::err(e.to_string().as_str());
    }
    for item in res.unwrap() {
        info!("item info {:?}", item);
        let mut time = item.time.to_string();
        // 判断倒计时类型
        if item.count_down_type == 2 {
            let mut date_info: Vec<u32> = Vec::new();
            // 字符串分割然后放到数组里面
            for item in time.split("-") {
                if let Ok(i) = item.parse::<i32>() {
                    date_info.push(i as u32);
                }
            }
            // 长度必须为2才通过
            if date_info.len() != 2 {
                continue;
            }
            let now = Local::now();
            info!(
                "year {} month {} day {}",
                now.year(),
                now.month(),
                now.day()
            );
            let mut year = now.year();
            // 如果已经过去了就使用下一年的
            if now.month() > date_info[0] {
                year += 1;
            } else if now.month() == date_info[0] && now.day() > date_info[1] {
                year += 1;
            }
            time = format!("{}-{}", year, item.time);
            info!("day is {}", time);
        }
        // 先解析出时间
        let naive_date = NaiveDate::parse_from_str(time.as_str(), "%Y-%m-%d");
        if let Err(e) = naive_date {
            error!("解析时间失败: {}", e);
            continue;
        }
        // 计算时间差
        let mut start = Local::now().date_naive().and_hms_opt(0, 0, 0).unwrap();
        let mut end = naive_date.unwrap().and_hms_opt(0, 0, 0).unwrap();
        if item.count_down_type == 2 {
            // 倒计时时间需要倒过来
            (start, end) = (end, start);
        }
        // 相差多少时间
        let diff = start.signed_duration_since(end).num_days();

        result.push(CountDown {
            id: item._id.unwrap().to_hex(),
            title: item.title,
            time: item.time,
            count: format!("{}天", diff),
            sex: item.sex,
        })
    }
    Response::ok(result)
}

// 添加倒计时
pub async fn add_count_down(
    Extension(app_state): Extension<AppState>,
    Json(payload): Json<AddCountDownReq>,
) -> HandleResult<String> {
    // 添加到数据库
    let res = app_state
        .db
        .insert_one(COLLECTION_COUNT_DOWN, payload)
        .await;
    return match res {
        Ok(uuid) => Response::ok(uuid),
        Err(e) => Response::err(e.to_string().as_str()),
    };
}

// 添加任务
pub async fn add_task(
    Extension(app_state): Extension<AppState>,
    Json(payload): Json<TaskInfo>,
) -> HandleResult<String> {
    // 添加到数据库
    let res = app_state.db.insert_one(COLLECTION_TASK, payload).await;
    return match res {
        Ok(uuid) => Response::ok(uuid),
        Err(e) => Response::err(e.to_string().as_str()),
    };
}

// 获取任务列表
pub async fn get_task_list(
    Extension(app_state): Extension<AppState>,
    Query(args): Query<HashMap<String, String>>,
) -> HandleResult<Vec<TaskInfo>> {
    let mut result = Vec::new();
    let mut filter: Option<Document> = None;
    // 获取一下tag，如果存在就直接设置
    if let Some(tag) = args.get("tag") {
        filter = Some(doc! {"tag": tag});
    }
    // 获取所有倒计时
    let res = app_state
        .db
        .find_data::<TaskInfo>(
            COLLECTION_TASK,
            filter,
            Some(
                FindOptions::builder()
                    .sort(doc! { "done": 1, "timestamp": -1 })
                    .build(),
            ),
        )
        .await;
    if let Err(e) = res {
        return Response::err(e.to_string().as_str());
    }
    for task in res.unwrap() {
        let mut req = TaskInfo { ..task };
        req.id = Some(task._id.unwrap().to_hex());
        req._id = None;
        result.push(req);
    }
    Response::ok(result)
}

// 更新任务
pub async fn update_task(
    Extension(app_state): Extension<AppState>,
    Json(payload): Json<UpdateTaskReq>,
) -> HandleResult<String> {
    // 直接更新数据库
    let res = app_state
        .db
        .update_data::<TaskInfo>(
            COLLECTION_TASK,
            doc! { "_id": app_state.db.str_to_object_id(payload.id.as_str()).unwrap() },
            doc! { "$set": { "done": payload.done } },
        )
        .await;
    return match res {
        Ok(_) => Response::ok2(),
        Err(e) => Response::err(e.to_string().as_str()),
    };
}

// 获取所有的标签
pub async fn get_all_tag(
    app_state: AppState,
    collection: &str
) -> HandleResult<Vec<String>> {
    let mut result = Vec::new();
    // 获取所有倒计时
    #[derive(Serialize, Deserialize, Debug)]
    pub struct AggregateRes {
        pub _id: String,
        pub values: Vec<String>,
    }
    let res = app_state
        .db
        .aggregate::<AggregateRes>(
            collection,
            vec![
                doc! { "$group": { "_id": "$tag", "values": { "$addToSet": "$tag" } } },
                doc! {"$sort": {"_id": 1}},
            ],
        )
        .await;
    if let Err(e) = res {
        return Response::err(e.to_string().as_str());
    }
    for aggregate in res.unwrap() {
        result.push(aggregate._id)
    }
    Response::ok(result)
}

// 获取所有任务标签
pub async fn get_task_tags(Extension(app_state): Extension<AppState>) -> HandleResult<Vec<String>> {
    get_all_tag(app_state,COLLECTION_TASK).await
}

// 添加动态
pub async fn add_dynamic(
    Extension(app_state): Extension<AppState>,
    Json(payload): Json<DynamicInfo>,
) -> HandleResult<String> {
    // 添加到数据库
    let res = app_state.db.insert_one(COLLECTION_DYNAMIC, payload).await;
    return match res {
        Ok(uuid) => Response::ok(uuid),
        Err(e) => Response::err(e.to_string().as_str()),
    };
}

// 获取动态列表
pub async fn get_dynamic_list(
    Extension(app_state): Extension<AppState>,
) -> HandleResult<Vec<DynamicComment>> {
    let mut result = Vec::new();
    // 获取所有倒计时
    let res = app_state
        .db
        .find_data::<DynamicInfo>(
            COLLECTION_DYNAMIC,
            None,
            Some(
                FindOptions::builder()
                    .sort(doc! { "timestamp": -1 })
                    .build(),
            ),
        )
        .await;
    if let Err(e) = res {
        return Response::err(e.to_string().as_str());
    }
    // 获取所有的动态id
    let mut dynamic_ids = Vec::new();
    let mut dynamic_list = Vec::new();
    for dynamic in res.unwrap() {
        dynamic_ids.push(dynamic._id.clone().unwrap().to_hex());
        let mut info = DynamicInfo { ..dynamic };
        info.id = Some(dynamic._id.unwrap().to_hex());
        info._id = None;
        dynamic_list.push(info);
    }

    // 查询所有评论
    let comment_res = app_state
        .db
        .find_data::<CommentInfo>(
            COLLECTION_COMMENT,
            Some(doc! {"relation_id": {"$in": dynamic_ids} }),
            None,
        )
        .await;
    // 映射为map
    let mut comment_map: HashMap<String, Vec<CommentInfo>> = HashMap::new();
    if let Ok(comment_list) = comment_res {
        for comment in comment_list {
            let mut info = CommentInfo { ..comment };
            info.id = Some(comment._id.unwrap().to_hex());
            info._id = None;
            let relation_id = info.relation_id.clone();
            if comment_map.contains_key(&*relation_id) {
                comment_map.get_mut(&*relation_id).unwrap().push(info);
            } else {
                comment_map.insert(relation_id, vec![info]);
            }
        }
    }

    // 遍历所有动态
    for dynamic in dynamic_list {
        let mut comments = Vec::new();
        // 插入评论
        let id = dynamic.id.clone().unwrap();
        if comment_map.contains_key(&*id) {
            comments = comment_map.get(&*id).unwrap().to_vec();
        }
        result.push(DynamicComment { dynamic, comments });
    }
    Response::ok(result)
}

// 添加笔记
pub async fn add_note(
    Extension(app_state): Extension<AppState>,
    Json(payload): Json<NoteInfo>,
) -> HandleResult<String> {
    // 添加到数据库
    let res = app_state.db.insert_one(COLLECTION_NOTE, payload).await;
    return match res {
        Ok(uuid) => Response::ok(uuid),
        Err(e) => Response::err(e.to_string().as_str()),
    };
}

// 获取笔记列表
pub async fn get_note_list(
    Extension(app_state): Extension<AppState>,
    Query(args): Query<HashMap<String, String>>,
) -> HandleResult<Vec<NoteInfo>> {
    let mut filter: Option<Document> = None;
    // 获取一下tag，如果存在就直接设置
    if let Some(tag) = args.get("tag") {
        filter = Some(doc! {"tag": tag});
    }
    let mut result = Vec::new();
    // 获取所有倒计时
    let res = app_state
        .db
        .find_data::<NoteInfo>(
            COLLECTION_NOTE,
            filter,
            Some(
                FindOptions::builder()
                    .sort(doc! { "timestamp": -1 })
                    .build(),
            ),
        )
        .await;
    if let Err(e) = res {
        return Response::err(e.to_string().as_str());
    }
    for note in res.unwrap() {
        let mut req = NoteInfo { ..note };
        req.id = Some(note._id.unwrap().to_hex());
        req._id = None;
        // 字符串超过200个就要截取
        if utf8_slice::len(req.content.as_str()) > 200 {
            req.content = utf8_slice::till(req.content.as_str(), 200).replace("\n"," ");
        }
        result.push(req);
    }
    Response::ok(result)
}

// 获取所有笔记标签
pub async fn get_note_tags(Extension(app_state): Extension<AppState>) -> HandleResult<Vec<String>> {
    get_all_tag(app_state,COLLECTION_NOTE).await
}

// 获取笔记列表
pub async fn get_note(
    Extension(app_state): Extension<AppState>,
    id: Path<String>,
) -> HandleResult<NoteInfo> {
    // 获取所有倒计时
    let res = app_state
        .db
        .find_data::<NoteInfo>(
            COLLECTION_NOTE,
            Some(doc! {"_id": app_state.db.str_to_object_id(id.as_str()).unwrap()}),
            None,
        )
        .await;
    if let Err(e) = res {
        return Response::err(e.to_string().as_str());
    }
    for note in res.unwrap() {
        let mut info = NoteInfo { ..note };
        info.id = Some(note._id.unwrap().to_hex());
        info._id = None;
        return Response::ok(info);
    }
    return Response::err("未找到笔记");
}

pub async fn update_note(
    Extension(app_state): Extension<AppState>,
    Json(payload): Json<NoteInfo>,
) -> HandleResult<String> {
    if None == payload.id {
        return Response::err("id不能为空");
    }
    // 直接更新数据库
    let res = app_state
        .db
        .update_data::<TaskInfo>(
            COLLECTION_NOTE,
            doc! { "_id": app_state.db.str_to_object_id(payload.id.unwrap().as_str()).unwrap() },
            doc! { "$set": {
                "title": payload.title,
                "content": payload.content,
                "tag": payload.tag,
            } },
        )
        .await;
    return match res {
        Ok(_) => Response::ok2(),
        Err(e) => Response::err(e.to_string().as_str()),
    };
}

pub async fn get_app() -> HandleResult<AppSetting> {
    let app = get_config();
    Response::ok(AppSetting {
        man_avatar: app.man_avatar,
        woman_avatar: app.woman_avatar,
    })
}

// 添加评论
pub async fn add_comment(
    Extension(app_state): Extension<AppState>,
    Json(payload): Json<CommentInfo>,
) -> HandleResult<String> {
    // 添加到数据库
    let res = app_state.db.insert_one(COLLECTION_COMMENT, payload).await;
    return match res {
        Ok(uuid) => Response::ok(uuid),
        Err(e) => Response::err(e.to_string().as_str()),
    };
}

#[cfg(test)]
mod tests {
    use chrono::{Datelike, Local, NaiveDate, TimeZone};

    #[actix_rt::test]
    async fn insert_data() {
        let naive_date = NaiveDate::parse_from_str(
            format!("{}-05-27", Local::now().year()).as_str(),
            "%Y-%m-%d",
        )
        .unwrap()
        .and_hms_opt(0, 0, 0)
        .unwrap();
        println!("{:?}", naive_date);
        // let data2 = Local::now().naive_local();
        // let duration = data2.signed_duration_since(naive_date);
        // println!("{:?}", duration.num_days());
    }
}
