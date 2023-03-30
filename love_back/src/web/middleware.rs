use axum::{
    body::{Body, BoxBody},
    http::{Request, Response},
};
use futures::future::BoxFuture;
use tower::{Service};
use std::task::{Context, Poll};


#[derive(Clone)]
pub struct AuthMiddleware<S> {
    pub inner: S,
    pub token: String,
}

impl<S> Service<Request<Body>> for AuthMiddleware<S>
    where
        S: Service<Request<Body>, Response = Response<BoxBody>> + Clone + Send + 'static,
        S::Future: Send + 'static,
{
    type Response = S::Response;
    type Error = S::Error;
    type Future = BoxFuture<'static, Result<Self::Response, Self::Error>>;

    fn poll_ready(&mut self, cx: &mut Context<'_>) -> Poll<Result<(), Self::Error>> {
        self.inner.poll_ready(cx)
    }

    fn call(&mut self, req: Request<Body>) -> Self::Future {
        let token = req.headers().get("token");
        // 获取token信息
        if token.is_none() || token.unwrap().to_str().unwrap() != self.token {
            return Box::pin(async move {
                Ok(Response::builder().status(401).body(BoxBody::default()).unwrap())
            });
        }

        // best practice is to clone the inner service like this
        let clone = self.inner.clone();
        let mut inner = std::mem::replace(&mut self.inner, clone);

        Box::pin(async move {
            // 调用服务获取结果并返回
            let res: Response<BoxBody> = inner.call(req).await?;
            Ok(res)
        })
    }
}