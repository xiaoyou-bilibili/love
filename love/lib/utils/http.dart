import 'package:dio/dio.dart';

// 服务器地址
const String host = "http://172.17.174.226:3000";

class HttpClient {
  Dio dio = Dio();
  final Map<String, String> _headers = {
    "token": "xiaoyou" // 请求token
  };

  dynamic responseInterceptor(Response response) {
    if (response.statusCode != 200) {
      throw Exception("请求失败");
    }

    print("resp is ${response.toString()}");

    Map<String, dynamic> data = response.data;
    if (data['code'] != 0) {
      throw Exception("服务错误 ${data['msg']}");
    }

    return data['data'];
  }

  // 发送get请求
  Future<dynamic> get(String url) async {
    Response response = await dio.get(host+url, options: Options(headers: _headers));
    return responseInterceptor(response);
  }

  // 发送post请求
  Future<dynamic> post(String url, dynamic body) async {
    Response response = await dio.post(host+url, data: body, options: Options(contentType: Headers.jsonContentType, headers: _headers));
    return responseInterceptor(response);
  }

  // 发送post form请求
  Future<dynamic> postFrom(String url, dynamic body) async {
    Response response = await dio.post(host+url, data: body, options: Options(contentType: Headers.multipartFormDataContentType, headers: _headers));
    return responseInterceptor(response);
  }

  // 发送put请求
  Future<dynamic> put(String url, dynamic body) async {
    Response response = await dio.put(host+url, data: body, options: Options(contentType: Headers.jsonContentType, headers: _headers));
    return responseInterceptor(response);
  }
}
