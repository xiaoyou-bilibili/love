import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import 'model.dart';
import 'http.dart';

class ApiService {
  static final HttpClient _client = HttpClient();
  static const String base = "/api/v1";

  // 获取倒计时
  static Future<List<CountDown>> getCountDown() async {
    List<CountDown> list = [];
    List<dynamic> data = await _client.get("$base/countdown");
    for (var item in data) {
      list.add(CountDown.fromJson(item));
    }
    return list;
  }

  // 创建倒计时
  static Future<String> addCountDown(AddCountDownReq body) async {
    dynamic data = await _client.post("$base/countdown", body);
    return data;
  }

  // 获取所有标签
  static Future<List<String>> getTagList() async {
    List<String> resp = [];
    List<dynamic> data = await _client.get("$base/task/tags");
    for (var element in data) {
      resp.add(element);
    }
    return resp;
  }

  // 获取所有的任务
  static Future<List<TaskInfo>> getTaskList(String tag) async {
    List<TaskInfo> list = [];
    List<dynamic> data = await _client.get("$base/tasks?tag=$tag");
    for (var item in data) {
      list.add(TaskInfo.fromJson(item));
    }
    return list;
  }

  // 更新任务
  static Future<void>  updateTask(UpdateTaskReq body) async {
    await _client.put("$base/task", body);
  }

  // 创建任务
  static Future<String> addTask(AddTaskReq body) async {
    dynamic data = await _client.post("$base/task", body);
    return data;
  }

  // 获取动态列表
  static Future<List<DynamicInfo>> getDynamicList() async {
    List<DynamicInfo> list = [];
    List<dynamic> data = await _client.get("$base/dynamic");
    for (var item in data) {
      list.add(DynamicInfo.fromJson(item));
    }
    return list;
  }

  // 获取笔记列表
  static Future<List<NoteInfo>> getNoteList() async {
    List<NoteInfo> list = [];
    List<dynamic> data = await _client.get("$base/note");
    for (var item in data) {
      list.add(NoteInfo.fromJson(item));
    }
    return list;
  }

  // 上传动态
  static Future<void> addDynamic(DynamicInfo body) async {
    _client.post("$base/dynamic", body);
  }

  // 上传笔记
  static Future<void> addNoteInfo(NoteInfo body) async {
    _client.post("$base/note", body);
  }

  // 获取具体某个笔记
  static Future<NoteInfo> getNote(String id) async {
    Map<String, dynamic> data = await  _client.get("$base/note/$id");
    return NoteInfo.fromJson(data);
  }

  // 更新笔记
  static Future<void> updateNote(NoteInfo body) async {
    _client.put("$base/note", body);
  }

  // 文件上传
  static Future<String> uploadFile(XFile image) async {
    var bytes = await image.readAsBytes();
    String data = await _client.postFrom("$base/file/upload", FormData.fromMap({
        "file": MultipartFile.fromBytes(bytes, filename: image.name),
    }));
    return data;
  }

  // 获取应用设置
  static Future<AppSetting> getAppSetting() async {
    Map<String, dynamic> data = await _client.get("$base/app");
    return AppSetting.fromJson(data);
  }
}

