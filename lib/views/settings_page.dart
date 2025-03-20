import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../adaptive_widgets/appbar.dart';
import '../adaptive_widgets/buttons.dart';
import '../adaptive_widgets/icons.dart';
import '../adaptive_widgets/listtile.dart';
import '../controllers/PlayerController.dart';
import '../models/SettingItem.dart';
import '../utils/constants.dart';
import '../widgets/color_icon.dart';
import '../widgets/text_styles.dart';
import 'home_page.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  TextEditingController searchController = TextEditingController();

  bool? isBatteryOptimisationDisabled;

  String searchText = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdaptiveAppBar(
        // leading: AdaptiveBackButton(),
        title: Text("إعدادت", style: bigTextStyle(context, bold: false)),
        centerTitle: true,
        automaticallyImplyLeading: true,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Directionality(
            textDirection: TextDirection.ltr, // Set text direction to RTL

            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                ...settingScreenData(context).map((e) {
                  return AdaptiveListTile(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    title: Text(
                      e.title,
                      style: textStyle(context, bold: false)
                          .copyWith(fontSize: 16),
                    ),
                    leading: (e.icon != null)
                        ? ColorIcon(
                            color: e.color,
                            icon: e.icon!,
                          )
                        : null,
                    trailing: e.trailing != null
                        ? e.trailing!(context)
                        : (e.hasNavigation
                            ? Icon(
                                AdaptiveIcons.chevron_right,
                                size: 30,
                              )
                            : null),
                    onTap: () {
                      e.onTap!(context);
                    },
                    subtitle: e.subtitle != null ? e.subtitle!(context) : null,
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final PlayerController c = Get.find<PlayerController>();
final Uri other_apps = Uri.parse('$other_apps');
final Uri main_app = Uri.parse('${Constants.BASE_URL_flutter}');

Future<void> _launchUrl(Uri url) async {
  if (!await launchUrl(url)) {
    throw Exception('Could not launch $other_apps');
  }
}

List<SettingItem> settingScreenData(BuildContext context) => [
      SettingItem(
        title: "تحميل الأناشيد",
        icon: Icons.download_rounded,
        color: Colors.accents[0],
        hasNavigation: true,
        onTap: (context) => c.downloadAllSongs(),
      ),
      SettingItem(
        title: "تحديث الأناشيد",
        icon: CupertinoIcons.music_note_list,
        color: Colors.accents[1],
        hasNavigation: true,
        onTap: (context) async => await c.checkfornewsongs(context),
      ),
      SettingItem(
        title: "مشاركة التطبيق",
        icon: CupertinoIcons.share,
        color: Colors.accents[2],
        hasNavigation: true,
        onTap: (context) =>
            Share.share('Check out this app: ${Constants.BASE_URL_flutter}'),
      ),
      SettingItem(
          title: "تطبيقاتنا الأخرى ",
          icon: Icons.settings_backup_restore_outlined,
          color: Colors.accents[3],
          hasNavigation: true,
          onTap: (context) => _launchUrl(other_apps)),
      SettingItem(
        title: "حول المطور",
        icon: Icons.info_rounded,
        color: Colors.accents[4],
        hasNavigation: true,
        onTap: (context) async {
          _launchUrl(other_apps);
        },
      ),
      SettingItem(
        title: "تحديث التطبيق",
        icon: Icons.update_outlined,
        color: Colors.accents[5],
        onTap: (context) async {
          _launchUrl(main_app);
        },
      ),
    ];

List<SettingItem> allSettingsData(BuildContext context) => [
      ...settingScreenData(context),
    ];
