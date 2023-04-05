mod web;
mod lib;

use log::info;
use std::net::SocketAddr;
use axum::extract::DefaultBodyLimit;
use axum::ServiceExt;
use web::router::new_router;
use lib::db::DbServer;
use tower::{ServiceBuilder};
// use tower_http::cors::{CorsLayer, Any};

#[tokio::main]
async fn main() {
    let config = crate::lib::config::config::get_config();
    // 初始化log RUST_LOG = info
    // export RUST_LOG=info
    env_logger::init();
    // 初始化数据库
    let db = DbServer::build(config.mongo.as_str(), "love").await;
    // 构建我们自己的路由
    let app = new_router(db, config.secret);
    let app = ServiceBuilder::new()
        // .layer(CorsLayer::new().allow_origin(Any).allow_methods(Any).allow_headers(Any))
        .layer(DefaultBodyLimit::max(1024 * 1024 * 100))
        .service(app);
    // 绑定端口
    let addr = SocketAddr::from(([0, 0, 0, 0], 3000));
    info!("server listen on 3000");
    //启动服务
    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await
        .unwrap();
}