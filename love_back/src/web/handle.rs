use crate::lib::utils::is_overlap;
use crate::lib::{config::config::get_config, utils::naive_date_to_timestamp};
use crate::web::model::{
    AddCountDownReq, Album, AlbumInfo, AlbumPhotoInfo, AppSetting, AppState, Calendar,
    CalendarInfo, CommentInfo, CountDown, DynamicComment, DynamicInfo, HandleResult, ImageInfo,
    NoteInfo, Response, TaskInfo, UpdateTaskReq,
};
use axum::extract::Multipart;
use axum::extract::{Extension, Path, Query};
use axum::Json;
use chrono::{Datelike, Duration, Local, NaiveDate};
use image::{load_from_memory, GenericImageView, ImageOutputFormat};
use log::error;
use mongodb::bson::{doc, Document};
use mongodb::options::FindOptions;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs::File;
use std::io::{Cursor, Write};
use std::ops::Add;
use std::path::Path as FilePath;
use lazy_static::lazy_static;
use lru::LruCache;
use std::num::NonZeroUsize;
use std::sync::mpsc::channel;
use std::sync::Mutex;

// 倒计时
const COLLECTION_COUNT_DOWN: &str = "count_down";
const COLLECTION_TASK: &str = "task";
const COLLECTION_DYNAMIC: &str = "dynamic";
const COLLECTION_NOTE: &str = "note";
const COLLECTION_COMMENT: &str = "comment";
const COLLECTION_CALENDAR: &str = "calendar";
const COLLECTION_ALBUM: &str = "album";

// 变量
lazy_static! {
    static ref IMG_SIZE_CACHE: Mutex<LruCache<String, ImageInfo>> = Mutex::new(LruCache::new(NonZeroUsize::new(2048).unwrap()));
}

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
        // 生成一个一个UUID
        let uuid = uuid::Uuid::new_v4().to_string();
        let new_file = format!("static/{}.{}", uuid, ext);
        let new_file_compose = format!("static/compose/{}.{}", uuid, ext);
        // info!("new file is {}", new_file);
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
            let mut year = now.year();
            // 如果已经过去了就使用下一年的
            if now.month() > date_info[0] {
                year += 1;
            } else if now.month() == date_info[0] && now.day() > date_info[1] {
                year += 1;
            }
            time = format!("{}-{}", year, item.time);
            // info!("day is {}", time);
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
            count_down_type: item.count_down_type,
            diff,
        })
    }
    // 进行自定义排序，优先展示正计时，然后是倒计时（正计时从大到小，倒计时从小到达）
    result.sort_by(|a, b| {
        return if a.count_down_type != b.count_down_type {
            a.count_down_type.cmp(&b.count_down_type)
        } else {
            if a.count_down_type == 1 {
                return b.diff.cmp(&a.diff);
            }
            a.diff.cmp(&b.diff)
        };
    });

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
pub async fn get_all_tag(app_state: AppState, collection: &str) -> HandleResult<Vec<String>> {
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
    get_all_tag(app_state, COLLECTION_TASK).await
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
            req.content = utf8_slice::till(req.content.as_str(), 200).to_string();
        }
        req.content = req.content.replace("\n", " ");
        result.push(req);
    }
    Response::ok(result)
}

// 获取所有笔记标签
pub async fn get_note_tags(Extension(app_state): Extension<AppState>) -> HandleResult<Vec<String>> {
    get_all_tag(app_state, COLLECTION_NOTE).await
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

// 添加日程
pub async fn add_calendar(
    Extension(app_state): Extension<AppState>,
    Json(payload): Json<Calendar>,
) -> HandleResult<String> {
    // 添加到数据库
    let res = app_state.db.insert_one(COLLECTION_CALENDAR, payload).await;
    return match res {
        Ok(uuid) => Response::ok(uuid),
        Err(e) => Response::err(e.to_string().as_str()),
    };
}

// 获取日程列表
pub async fn get_calendar(
    Extension(app_state): Extension<AppState>,
    Query(args): Query<HashMap<String, String>>,
) -> HandleResult<Vec<CalendarInfo>> {
    let mut result = Vec::new();
    // 获取开始时间
    let year_arg = args.get("year");
    let month_arg = args.get("month");
    if year_arg.is_none() || month_arg.is_none() {
        return Response::err("year 和 month 不能为空");
    }
    let year = year_arg.unwrap().parse::<i32>();
    let month = month_arg.unwrap().parse::<u32>();
    if year.is_err() || month.is_err() {
        return Response::err("year 和 month 必须是数字");
    }

    let start = NaiveDate::parse_from_str(
        format!("{}-{}-01", year.clone().unwrap(), month.clone().unwrap()).as_str(),
        "%Y-%m-%d",
    )
    .unwrap();
    let end: NaiveDate;
    // 12月得特殊处理
    if month.clone().unwrap() == 12 {
        end = NaiveDate::parse_from_str(
            format!("{}-01-01", year.clone().unwrap() + 1).as_str(),
            "%Y-%m-%d",
        )
        .unwrap()
        .pred_opt()
        .unwrap();
    } else {
        end = start
            .with_day(1)
            .unwrap()
            .with_month(month.unwrap() + 1)
            .unwrap()
            .pred_opt()
            .unwrap();
    }
    // 按照时间范围来进行过滤
    let res = app_state
        .db
        .find_data::<Calendar>(
            COLLECTION_CALENDAR,
            Some(doc! {
                "$or": [
                    {"start_time": {"$gte": naive_date_to_timestamp(start),"$lte": naive_date_to_timestamp(end)}},
                    {"end_time": {"$gte": naive_date_to_timestamp(start),"$lte": naive_date_to_timestamp(end)}},
                ]
            }),
            None,
        )
        .await;
    if let Err(e) = res {
        return Response::err(e.to_string().as_str());
    }
    // 获取最新的一次大姨妈时间
    let res2 = app_state
        .db
        .find_data::<Calendar>(
            COLLECTION_CALENDAR,
            Some(doc! {"calendar_type": 2}),
            Some(
                FindOptions::builder()
                    .sort(doc! {"start_time": -1})
                    .limit(1)
                    .build(),
            ),
        )
        .await;
    let mut menstruation_start_time = 0;
    let mut menstruation_end_time = 0;
    if let Ok(calendar_list) = res2 {
        if !calendar_list.is_empty() {
            menstruation_start_time = calendar_list.get(0).unwrap().start_time + 3600 * 24 * 27;
            menstruation_end_time = menstruation_start_time + 3600 * 24 * 4;
        }
    }
    // 遍历这个月每一天
    let mut current = start;
    let calendar_iter = res.unwrap();
    while current <= end {
        let timestamp_start = naive_date_to_timestamp(current);
        let timestamp_end = naive_date_to_timestamp(current.add(Duration::days(1))) - 1;
        for calendar in calendar_iter.iter().clone() {
            // 判断一下是否是当天的日程，只需要判断两个区间是否有重叠即可
            if is_overlap(
                (calendar.start_time, calendar.end_time),
                (timestamp_start, timestamp_end),
            ) {
                result.push(CalendarInfo {
                    id: calendar._id.unwrap().to_hex(),
                    title: calendar.title.to_string(),
                    desc: calendar.desc.to_string(),
                    date: current.format("%Y-%m-%d").to_string(),
                    calendar_type: calendar.calendar_type,
                    sex: calendar.sex,
                });
            }
        }
        // 如果是大姨妈
        if menstruation_start_time <= timestamp_start && timestamp_start <= menstruation_end_time {
            result.push(CalendarInfo {
                id: "".to_string(),
                title: "大姨妈".to_string(),
                desc: "预测时间，注意提前准备(*^_^*)".to_string(),
                date: current.format("%Y-%m-%d").to_string(),
                calendar_type: 2,
                sex: 2,
            });
        }
        current += Duration::days(1);
    }

    return Response::ok(result);
}

// 新增相册
pub async fn add_album(
    Extension(app_state): Extension<AppState>,
    Json(payload): Json<Album>,
) -> HandleResult<String> {
    // 添加到数据库
    let res = app_state.db.insert_one(COLLECTION_ALBUM, payload).await;
    return match res {
        Ok(uuid) => Response::ok(uuid),
        Err(e) => Response::err(e.to_string().as_str()),
    };
}

// 获取相册列表
pub async fn get_album_list(
    Extension(app_state): Extension<AppState>,
) -> HandleResult<Vec<AlbumInfo>> {
    let mut result = Vec::new();
    // 获取所有倒计时
    let res = app_state
        .db
        .find_data::<Album>(
            COLLECTION_ALBUM,
            None,
            Some(FindOptions::builder().sort(doc! {"timestamp": -1 }).build()),
        )
        .await;
    if let Err(e) = res {
        return Response::err(e.to_string().as_str());
    }
    for item in res.unwrap() {
        let mut info = AlbumInfo {
            id: item._id.unwrap().to_hex(),
            title: item.title,
            preview: "".to_string(),
            count: item.photos.len() as i32,
        };
        if let Some(pre) = item.photos.last() {
            info.preview = pre.to_string();
        }

        result.push(info);
    }
    Response::ok(result)
}

// 获取相册详情
pub async fn get_album_detail(
    Extension(app_state): Extension<AppState>,
    id: Path<String>,
) -> HandleResult<Album> {
    let res = app_state
        .db
        .find_data::<Album>(
            COLLECTION_ALBUM,
            Some(doc! {"_id": app_state.db.str_to_object_id(id.as_str()).unwrap()}),
            None,
        )
        .await;
    if let Err(e) = res {
        return Response::err(e.to_string().as_str());
    }
    if let Ok(mut result) = res {
        if !result.is_empty() {
            let mut album = result.remove(0);
            album.photos.reverse();
            return Response::ok(album);
        }
    }
    return Response::err("未找到相册");
}

// 相册添加图片
pub async fn add_album_photos(
    Extension(app_state): Extension<AppState>,
    id: Path<String>,
    Json(payload): Json<AlbumPhotoInfo>,
) -> HandleResult<String> {
    // 添加到数据库
    let res = app_state
        .db
        .update_data::<Album>(
            COLLECTION_ALBUM,
            doc! {"_id": app_state.db.str_to_object_id(id.as_str()).unwrap()},
            doc! {"$push": {"photos": {"$each": payload.urls}}},
        )
        .await;
    return match res {
        Ok(_) => Response::ok2(),
        Err(e) => Response::err(e.to_string().as_str()),
    };
}

// 相册删除图片
pub async fn delete_album_photos(
    Extension(app_state): Extension<AppState>,
    id: Path<String>,
    Json(payload): Json<AlbumPhotoInfo>,
) -> HandleResult<String> {
    // 添加到数据库
    let res = app_state
        .db
        .update_data::<Album>(
            COLLECTION_ALBUM,
            doc! {"_id": app_state.db.str_to_object_id(id.as_str()).unwrap()},
            doc! {"$pull": {"photos": {"$in": payload.urls}}},
        )
        .await;
    return match res {
        Ok(_) => Response::ok2(),
        Err(e) => Response::err(e.to_string().as_str()),
    };
}

// 获取图片信息
pub async fn get_img_info(Query(args): Query<HashMap<String, String>>) -> HandleResult<ImageInfo> {
    let url = args.get("url");
    if let None = url {
        return Response::err("参数错误");
    }
    let mut cache = IMG_SIZE_CACHE.lock().unwrap();
    // 判断缓存中是否存在
    if cache.get(url.unwrap()).is_some() {
        let info = cache.get(url.unwrap()).unwrap();
        return Response::ok(ImageInfo {..*info });
    }
    let img_path = FilePath::new(url.unwrap());
    let file = image::open(img_path);
    return if let Ok(img) = file {
        let (width, height) = img.dimensions();
        // 缓存当前数据
        cache.put(url.unwrap().to_string(), ImageInfo { width, height });
        Response::ok(ImageInfo { width, height })
    } else {
        Response::err("文件不存在")
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
