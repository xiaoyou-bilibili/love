import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import 'model.dart';
import 'http.dart';

class ApiService {
  static final HttpClient client = HttpClient();
  static const String base = "/api/v1";

  // 获取倒计时
  static Future<List<CountDown>> getCountDown() async {
    List<CountDown> list = [];
    List<dynamic> data = await client.get("$base/countdown");
    for (var item in data) {
      list.add(CountDown.fromJson(item));
    }
    return list;
  }

  // 创建倒计时
  static Future<String> addCountDown(AddCountDownReq body) async {
    dynamic data = await client.post("$base/countdown", body);
    return data;
  }

  // 获取所有任务标签
  static Future<List<String>> getTaskTagList() async {
    List<String> resp = [];
    List<dynamic> data = await client.get("$base/task/tags");
    for (var element in data) {
      resp.add(element);
    }
    return resp;
  }

  // 获取所有的任务
  static Future<List<TaskInfo>> getTaskList(String tag) async {
    List<TaskInfo> list = [];
    List<dynamic> data = await client.get("$base/tasks?tag=$tag");
    for (var item in data) {
      list.add(TaskInfo.fromJson(item));
    }
    return list;
  }

  // 更新任务
  static Future<void> updateTask(UpdateTaskReq body) async {
    await client.put("$base/task", body);
  }

  // 创建任务
  static Future<String> addTask(AddTaskReq body) async {
    dynamic data = await client.post("$base/task", body);
    return data;
  }

  // 获取动态列表
  static Future<List<DynamicComment>> getDynamicList() async {
    List<DynamicComment> list = [];
    List<dynamic> data = await client.get("$base/dynamic");
    for (var item in data) {
      list.add(DynamicComment.fromJson(item));
    }
    return list;
  }

  // 获取所有笔记标签
  static Future<List<String>> getNoteTagList() async {
    List<String> resp = [];
    List<dynamic> data = await client.get("$base/note/tags");
    for (var element in data) {
      resp.add(element);
    }
    return resp;
  }

  // 获取笔记列表
  static Future<List<NoteInfo>> getNoteList(String tag) async {
    List<NoteInfo> list = [];
    List<dynamic> data = await client.get("$base/note?tag=$tag");
    for (var item in data) {
      list.add(NoteInfo.fromJson(item));
    }
    return list;
  }

  // 上传动态
  static Future<void> addDynamic(DynamicInfo body) async {
    client.post("$base/dynamic", body);
  }

  // 上传笔记
  static Future<void> addNoteInfo(NoteInfo body) async {
    client.post("$base/note", body);
  }

  // 获取具体某个笔记
  static Future<NoteInfo> getNote(String id) async {
    Map<String, dynamic> data = await client.get("$base/note/$id");
    return NoteInfo.fromJson(data);
  }

  // 更新笔记
  static Future<void> updateNote(NoteInfo body) async {
    client.put("$base/note", body);
  }

  // 文件上传
  static Future<String> uploadFile(XFile image) async {
    var bytes = await image.readAsBytes();
    String data = await client.postFrom(
        "$base/file/upload",
        FormData.fromMap({
          "file": MultipartFile.fromBytes(bytes, filename: image.name),
        }));
    return data;
  }

  // 获取应用设置
  static Future<AppSetting> getAppSetting() async {
    Map<String, dynamic> data = await client.get("$base/app");
    return AppSetting.fromJson(data);
  }

  // 添加评论
  static Future<void> addComment(CommentInfo body) async {
    client.post("$base/comment", body);
  }

  // 添加日程
  static Future<void> addCalendar(AddCalendarReq body) async {
    client.post("$base/calender", body);
  }

  // 获取日程
  static Future<List<CalendarInfo>> getCalendarList(
      String year, String month) async {
    List<CalendarInfo> list = [];
    List<dynamic> data =
        await client.get("$base/calender?year=$year&month=$month");
    for (var item in data) {
      list.add(CalendarInfo.fromJson(item));
    }
    return list;
  }

  // 添加相册
  static Future<void> addAlbum(Album body) async {
    client.post("$base/album", body);
  }

  // 获取相册列表
  static Future<List<AlbumInfo>> getAlbumList() async {
    List<AlbumInfo> list = [];
    List<dynamic> data = await client.get("$base/album");
    for (var item in data) {
      list.add(AlbumInfo.fromJson(item));
    }
    return list;
  }

  // 获取相册详情
  static Future<Album> getAlbumInfo(String id) async {
    Map<String, dynamic> data = await client.get("$base/album/$id");
    return Album.fromJson(data);
  }

  // 相册添加图片
  static Future<void> albumAddPhoto(String id, AlbumPhotoInfo photo) async {
    client.post("$base/album/$id/photos", photo);
  }
}
