use crate::lib::db::DbServer;
use axum::Json;
use mongodb::bson::oid::ObjectId;
use serde::{Deserialize, Serialize};

pub type HandleResult<T> = Json<Response<T>>;

// 应用状态共享
#[derive(Clone)]
pub struct AppState {
    // 数据库
    pub db: DbServer,
}

// 自定义通用返回
#[derive(Serialize)]
pub struct Response<T> {
    pub code: i32,
    pub data: Option<T>,
    pub msg: String,
}

// 自定义通用返回快捷方法
impl<T> Response<T>
where
    T: Serialize,
{
    pub fn new(code: i32, msg: String, data: Option<T>) -> Self {
        Self { code, msg, data }
    }
    // 请求成功
    pub fn ok(data: T) -> HandleResult<T> {
        Json(Self::new(0, "ok".to_string(), Some(data)))
    }
    // 请求成功不返回数据
    pub fn ok2() -> HandleResult<T> {
        Json(Self::new(0, "ok".to_string(), None))
    }
    // 请求失败
    pub fn err(msg: &str) -> HandleResult<T> {
        Json(Self::new(-1, String::from(msg), None))
    }
}

// 倒计时
#[derive(Debug, Serialize, Deserialize)]
pub struct CountDown {
    pub id: String,           // 倒计时ID
    pub title: String,        // 倒计时标题
    pub time: String,         // 时间信息
    pub count: String,        // 剩余时间
    pub sex: i32,             // 性别
    pub count_down_type: i32, // 倒计时类型 1 正计时 2 倒计时
    pub diff: i64,            // 相差时间
}

// 添加倒计时
#[derive(Debug, Serialize, Deserialize)]
pub struct AddCountDownReq {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub _id: Option<ObjectId>, // object id
    pub title: String,        // 标题
    pub time: String,         // 时间信息
    pub count_down_type: i32, // 倒计时类型 1 正计时 2 倒计时
    pub sex: i32,             // 身份 1 男  2 女
}

// 添加计划
#[derive(Debug, Serialize, Deserialize)]
pub struct TaskInfo {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub _id: Option<ObjectId>, // object id
    #[serde(skip_serializing_if = "Option::is_none")]
    pub id: Option<String>, // 任务id
    pub title: String,  // 标题
    pub tag: String,    // 标签
    pub done: bool,     // 任务是否完成
    pub sex: i32,       // 性别
    pub timestamp: i64, // 时间戳
}

// 更新计划
#[derive(Debug, Serialize, Deserialize)]
pub struct UpdateTaskReq {
    pub id: String, // 任务id
    pub done: bool, // 任务是否完成
}

// 动态信息
#[derive(Debug, Serialize, Deserialize)]
pub struct DynamicInfo {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub _id: Option<ObjectId>, // object id
    #[serde(skip_serializing_if = "Option::is_none")]
    pub id: Option<String>, // 动态id
    pub content: String,     // 内容
    pub images: Vec<String>, // 标签
    pub timestamp: i64,      // 时间戳
    pub sex: i32,            // 性别
}

// 笔记信息
#[derive(Debug, Serialize, Deserialize)]
pub struct NoteInfo {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub _id: Option<ObjectId>, // object id
    #[serde(skip_serializing_if = "Option::is_none")]
    pub id: Option<String>, // 动态id
    pub title: String,   // 笔记标题
    pub tag: String,     // 笔记标签
    pub content: String, // 笔记内容
    pub timestamp: i64,  // 时间戳
    pub sex: i32,        // 性别
}

// 系统设置
#[derive(Debug, Serialize, Deserialize)]
pub struct AppSetting {
    pub man_avatar: String,   // 男性头像
    pub woman_avatar: String, // 女性头像
}

// 评论信息
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct CommentInfo {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub _id: Option<ObjectId>, // object id
    #[serde(skip_serializing_if = "Option::is_none")]
    pub id: Option<String>, // 评论id
    pub relation_id: String, // 关联的id，包括动态/笔记等
    pub content: String,     // 评论内容
    pub timestamp: i64,      // 时间戳
    pub sex: i32,            // 性别
}

// 新版动态
#[derive(Debug, Serialize, Deserialize)]
pub struct DynamicComment {
    pub dynamic: DynamicInfo,       // 动态信息
    pub comments: Vec<CommentInfo>, // 评论信息
}

// 日程安排
#[derive(Debug, Serialize, Deserialize)]
pub struct Calendar {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub _id: Option<ObjectId>, // object id
    pub title: String,      // 标题
    pub desc: String,       // 备注
    pub start_time: i64,    // 开始时间
    pub end_time: i64,      // 结束时间
    pub calendar_type: i32, // 日历类型 1 普通范围
    pub sex: i32,           // 身份 1 男  2 女
    pub timestamp: i64,     // 创建时间
}

// 获取日程
#[derive(Debug, Serialize, Deserialize)]
pub struct CalendarInfo {
    pub id: String,         // 日程id
    pub title: String,      // 标题
    pub desc: String,       // 备注
    pub date: String,       // 日期
    pub calendar_type: i32, // 日历类型
    pub sex: i32,           // 身份 1 男  2 女
}

// 添加相册
#[derive(Debug, Serialize, Deserialize)]
pub struct Album {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub _id: Option<ObjectId>, // object id
    pub title: String,       // 标题
    pub photos: Vec<String>, // 相册列表
    pub sex: i32,            // 身份 1 男  2 女
    pub timestamp: i64,      // 创建时间
}

// 获取相册列表
#[derive(Debug, Serialize, Deserialize)]
pub struct AlbumInfo {
    pub id: String,      // 相册id
    pub title: String,   // 标题
    pub preview: String, // 预览图
    pub count: i32,      // 图片数量
}

// 获取相册列表
#[derive(Debug, Serialize, Deserialize)]
pub struct AlbumPhotoInfo {
    pub urls: Vec<String>, // 待新增的图片列表
}

// 图片信息
#[derive(Debug, Serialize, Deserialize)]
pub struct ImageInfo {
    pub width: u32, // 宽度
    pub height: u32, // 高度
}

// 获取图片信息请求
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct GetImageInfoReq {
    pub url: String, // 宽度
}
