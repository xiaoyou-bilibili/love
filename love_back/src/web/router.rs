use crate::web::{handle, middleware};
use crate::lib::db::DbServer;
use crate::web::model::AppState;
use axum::{http::StatusCode, routing::{get, post, put}, Extension, Router};
use axum::routing::get_service;
use tower_http::{services::ServeDir};
use tower::{layer::layer_fn};

// 初始化所有的router
pub fn new_router(db: DbServer, secret: String) -> Router {
    //构建路由
    let router = Router::new()
        // 主路由
        .route("/", get(handle::pong))
        // 创建倒计时
        .route("/countdown", post(handle::add_count_down))
        // 获取倒计时
        .route("/countdown", get(handle::get_count_down))
        // 创建任务
        .route("/task", post(handle::add_task))
        // 获取所有的任务
        .route("/tasks", get(handle::get_task_list))
        // 更新任务
        .route("/task", put(handle::update_task))
        // 获取所有任务标签
        .route("/task/tags", get(handle::get_task_tags))
        // 添加动态
        .route("/dynamic", post(handle::add_dynamic))
        // 获取所有动态
        .route("/dynamic", get(handle::get_dynamic_list))
        // 添加笔记
        .route("/note", post(handle::add_note))
        // 获取所有的笔记
        .route("/note", get(handle::get_note_list))
        // 获取所有的笔记标签
        .route("/note/tags", get(handle::get_note_tags))
        // 获取具体某个笔记
        .route("/note/:id", get(handle::get_note))
        // 更新笔记
        .route("/note", put(handle::update_note))
        // app配置
        .route("/app", get(handle::get_app))
        // 添加评论
        .route("/comment", post(handle::add_comment))
        // 添加一个时间范围
        .route("/calender", post(handle::add_calendar))
        // 获取所有日程
        .route("/calender", get(handle::get_calendar))
        // 新增相册
        .route("/album", post(handle::add_album))
        // 获取相册列表
        .route("/album", get(handle::get_album_list))
        // 获取相册详情
        .route("/album/:id", get(handle::get_album_detail))
        // 相册添加图片
        .route("/album/:id/photos", post(handle::add_album_photos))



        // 文件上传
        .route("/file/upload", post(handle::upload_file))
        // 全局状态共享
        .layer(Extension(AppState { db }))
        // 自定义认证中间件
        .layer(layer_fn(move |inner| middleware::AuthMiddleware { inner, token: secret.clone() }));
    // 路由分组
    Router::new()
        .nest("/api/v1", router)
        // 静态资源访问
        .nest_service("/static",get_service(ServeDir::new("static")).handle_error(|error: std::io::Error| async move {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                format!("Unhandled internal error: {}", error),
            )
        }))
}
