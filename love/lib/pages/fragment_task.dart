import 'package:bruno/bruno.dart';
import 'package:flutter/material.dart';
import 'package:love/component/item_task.dart';
import 'package:love/utils/api.dart';
import 'package:love/utils/model.dart';
import 'package:love/pages/fragment.dart';
import 'package:love/utils/storage.dart';
import 'package:love/utils/utils.dart';

// 主页视图
class TaskFragment extends StatefulWidget implements PageFragment {
  final GlobalKey _key;

  const TaskFragment(this._key) : super(key: _key);

  @override
  State<StatefulWidget> createState() => _TaskFragmentState();

  @override
  void addCallback() {
    (_key.currentState as _TaskFragmentState).addTask();
  }
}

class _TaskFragmentState extends State<TaskFragment>
    with TickerProviderStateMixin {
  // 所有的标签
  List<String> _tags = [""];
  // 所有的任务
  List<TaskInfo> _tasks = [];
  // 下标index
  int _index = 0;
  // 任务名称
  String _title = "";
  String _tag = "";
  List<bool> _selectStatus = [];

  @override
  void initState() {
    // 页面初始化获取一下所有的tag
    ApiService.getTaskTagList().then(
      (tags) => {
        if (tags.isNotEmpty)
          {
            _selectStatus = List.generate(tags.length, (index) => false),
            setState(() {
              _tags = tags;
            }),
            // 直接获取第一个标签来请求任务列表
            _getTaskList(tags.first)
          }
      },
    );
    super.initState();
  }

  // 获取所有的任务
  void _getTaskList(String tag) {
    ApiService.getTaskList(tag).then(
      (taskList) => setState(() {
        _tasks = taskList;
      }),
    );
  }

  // 添加任务
  void addTask() {
    // 显示一个弹窗
    showCustomDialog(
      context: context,
      title: "添加任务",
      children: [
        BrnTextInputFormItem(
          title: "任务名称",
          hint: "任务名称",
          onChanged: (newValue) {
            _title = newValue;
          },
        ),
        SizedBox(
          width: double.maxFinite,
          child: BrnTextQuickSelectFormItem(
            isEdit: true,
            title: "标签",
            btnsTxt: _tags,
            value: _tag,
            selectBtnList: _selectStatus,
            isBtnsScroll: true,
            prefixIconType: BrnPrefixIconType.add,
            onBtnSelectChanged: (index) {
              _tag = _tags[index];
              // 修改其他按钮的状态，只能有一个按钮被点击
              for (var i = 0; i < _tags.length; i++) {
                _selectStatus[i] = i == index;
              }
              (context as Element).markNeedsBuild();
            },
            onAddTap: () {
              BrnMiddleInputDialog(
                title: "标签名称",
                hintText: '新标签名称',
                onConfirm: (value) {
                  _tag = value;
                  Navigator.pop(context);
                  (context as Element).markNeedsBuild();
                },
                onCancel: () => Navigator.pop(context),
              ).show(context);
            },
          ),
        )
      ],
      onConfirm: () {
        var resp = ApiService.addTask(AddTaskReq(
          _title,
          _tag,
          Storage.getSexSync(),
          getUnixNow(),
        ));
        requestProcess(context, resp, () {
          _getTaskList(_tag);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 顶部标签
    var tabs = <BadgeTab>[];
    for (String tab in _tags) {
      tabs.add(BadgeTab(text: tab));
    }
    TabController controller =
        TabController(length: tabs.length, vsync: this, initialIndex: _index);
    // 底部任务栏
    var taskList = <ComponentItemTaskBox>[];
    for (var task in _tasks) {
      taskList.add(ComponentItemTaskBox(task));
    }

    return Column(children: [
      BrnTabBar(
        padding: const EdgeInsets.all(0),
        tabs: tabs,
        controller: controller,
        onTap: (state, index) {
          _index = index;
          _getTaskList(_tags[index]);
        },
      ),
      Expanded(
        child: ListView(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          children: taskList,
        ),
      )
    ]);
  }
}
