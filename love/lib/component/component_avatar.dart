import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:love/utils/model.dart';
import 'package:love/utils/storage.dart';


class ComponentAvatar extends StatelessWidget {
  final int sex;
  const ComponentAvatar(this.sex, {super.key});

  @override
  Widget build(BuildContext context) {
    AppSetting setting = Storage.getAppSetting();

    if(sex == 1 || sex == 2) {
      return Container(width: 35, alignment: Alignment.center, child: CircleAvatar(radius: 15, backgroundImage: CachedNetworkImageProvider(sex == 1 ? setting.man_avatar : setting.woman_avatar)));
    }
    return SizedBox(
      width: 45,
      child: Stack(children: [
        CircleAvatar(radius: 15, backgroundImage: CachedNetworkImageProvider(setting.man_avatar)),
        Positioned(left: 15, child: CircleAvatar(radius: 15, backgroundImage: CachedNetworkImageProvider(setting.woman_avatar)))
      ]),
    );
  }
}