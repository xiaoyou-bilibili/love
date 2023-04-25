// 倒计时组件
class CountDown {
  String id;
  String title;
  String time;
  String count;
  int sex;

  CountDown(
      {required this.id,
      required this.title,
      required this.time,
      required this.count,
      required this.sex});

  factory CountDown.fromJson(Map<String, dynamic> json) {
    return CountDown(
        id: json['id'],
        title: json['title'],
        time: json['time'],
        count: json['count'],
        sex: json['sex']);
  }
}

// 添加倒计时
class AddCountDownReq {
  String title;
  String time;
  int countDownType;
  int sex;

  AddCountDownReq(this.title, this.time, this.countDownType, this.sex);

  Map toJson() {
    Map map = {
      "title": title,
      "time": time,
      "count_down_type": countDownType,
      "sex": sex
    };
    return map;
  }
}

// 任务列表
class TaskInfo {
  String id;
  String title;
  String tag;
  bool done;
  int sex;
  int timestamp;

  TaskInfo(this.id, this.title, this.tag, this.done, this.sex, this.timestamp);

  factory TaskInfo.fromJson(Map<String, dynamic> json) {
    return TaskInfo(json['id'], json['title'], json['tag'], json['done'],
        json['sex'], json['timestamp']);
  }
}

// 更新任务
class UpdateTaskReq {
  String id;
  bool done;

  UpdateTaskReq(this.id, this.done);

  Map toJson() {
    Map map = {
      "id": id,
      "done": done,
    };
    return map;
  }
}

// 添加任务
class AddTaskReq {
  String title;
  String tag;
  int sex;
  int timestamp;

  AddTaskReq(this.title, this.tag, this.sex, this.timestamp);

  Map toJson() {
    Map map = {
      "title": title,
      "tag": tag,
      "done": false,
      "sex": sex,
      "timestamp": timestamp
    };
    return map;
  }
}

// 动态列表
class DynamicInfo {
  String id;
  String content;
  List<String> images;
  int timestamp;
  int sex;

  DynamicInfo(
      {this.id = "",
      required this.content,
      required this.images,
      required this.timestamp,
      required this.sex});

  factory DynamicInfo.fromJson(Map<String, dynamic> json) {
    return DynamicInfo(
        id: json['id'],
        content: json['content'],
        images: List.from(json["images"]),
        timestamp: json['timestamp'],
        sex: json['sex']);
  }

  Map toJson() {
    return {
      "content": content,
      "images": List.from(images),
      "timestamp": timestamp,
      "sex": sex
    };
  }
}

// 笔记本
class NoteInfo {
  String id;
  String title;
  String content;
  String tag;
  int timestamp;
  int sex;

  NoteInfo(
      {this.id = "",
      required this.title,
      required this.content,
      required this.timestamp,
      required this.tag,
      required this.sex});

  factory NoteInfo.fromJson(Map<String, dynamic> json) {
    return NoteInfo(
        id: json['id'],
        title: json['title'],
        content: json['content'],
        tag: json['tag'],
        timestamp: json['timestamp'],
        sex: json['sex']);
  }

  Map toJson() {
    Map<String, dynamic> info = {
      "title": title,
      "content": content,
      "tag": tag,
      "timestamp": timestamp,
      "sex": sex
    };
    if (id != "") {
      info["id"] = id;
    }
    return info;
  }
}

// 应用设施
class AppSetting {
  String manAvatar;
  String womanAvatar;

  AppSetting({required this.manAvatar, required this.womanAvatar});

  factory AppSetting.fromJson(Map<String, dynamic> json) {
    return AppSetting(
        manAvatar: json['man_avatar'], womanAvatar: json['woman_avatar']);
  }

  Map toJson() {
    return {
      "man_avatar": manAvatar,
      "woman_avatar": womanAvatar,
    };
  }
}

// 评论
class CommentInfo {
  String id;
  String relationId;
  String content;
  int timestamp;
  int sex;

  CommentInfo(
      {this.id = "",
      required this.relationId,
      required this.content,
      required this.timestamp,
      required this.sex});

  factory CommentInfo.fromJson(Map<String, dynamic> json) {
    return CommentInfo(
        id: json['id'],
        relationId: json['relation_id'],
        content: json['content'],
        timestamp: json['timestamp'],
        sex: json['sex']);
  }

  Map toJson() {
    Map<String, dynamic> info = {
      "relation_id": relationId,
      "content": content,
      "timestamp": timestamp,
      "sex": sex
    };
    if (id != "") {
      info["id"] = id;
    }
    return info;
  }
}

//动态评论
class DynamicComment {
  DynamicInfo dynamicInfo;
  List<CommentInfo> comments;

  DynamicComment({required this.dynamicInfo, required this.comments});

  factory DynamicComment.fromJson(Map<String, dynamic> json) {
    List<CommentInfo> commentList = [];
    for (var item in json['comments']) {
      commentList.add(CommentInfo.fromJson(item));
    }
    return DynamicComment(
        dynamicInfo: DynamicInfo.fromJson(json['dynamic']),
        comments: commentList);
  }
}

// 添加日程
class AddCalendarReq {
  String title;
  String desc;
  int startTime;
  int endTime;
  int calendarType;
  int sex;
  int timestamp;

  AddCalendarReq(
      {required this.title,
      required this.desc,
      required this.startTime,
      required this.endTime,
      required this.calendarType,
      required this.timestamp,
      required this.sex});

  Map toJson() {
    return {
      "title": title,
      "desc": desc,
      "start_time": startTime,
      "end_time": endTime,
      "calendar_type": calendarType,
      "timestamp": timestamp,
      "sex": sex
    };
  }
}

// 获取日程
class CalendarInfo {
  String id;
  String title;
  String desc;
  String date;
  int calendarType;
  int sex;

  CalendarInfo(
      {required this.id,
        required this.title,
        required this.desc,
        required this.date,
        required this.calendarType,
        required this.sex});

  factory CalendarInfo.fromJson(Map<String, dynamic> json) {
    return CalendarInfo(
        id: json['id'],
        title: json['title'],
        desc: json['desc'],
        date: json['date'],
        calendarType: json['calendar_type'],
        sex: json['sex']);
  }
}