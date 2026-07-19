import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/desktop/widgets/tabbar_widget.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:window_manager/window_manager.dart';

// Fenikya marka renkleri (kurulum ekrani)
const _kBrand = Color(0xFF0EA5B7);
const _kBlue = Color(0xFF1D4ED8);
const _kBlueD = Color(0xFF1E40AF);
const _kInk = Color(0xFF0B2440);
const _kInk2 = Color(0xFF31465E);
const _kMuted = Color(0xFF7189A3);
const _kLine = Color(0xFFE6EEF5);

class InstallPage extends StatefulWidget {
  const InstallPage({Key? key}) : super(key: key);

  @override
  State<InstallPage> createState() => _InstallPageState();
}

class _InstallPageState extends State<InstallPage> {
  final tabController = DesktopTabController(tabType: DesktopTabType.main);

  _InstallPageState() {
    Get.put<DesktopTabController>(tabController);
    const label = "install";
    tabController.add(TabInfo(
        key: label,
        label: label,
        closable: false,
        page: _InstallPageBody(
          key: const ValueKey(label),
        )));
  }

  @override
  void dispose() {
    super.dispose();
    Get.delete<DesktopTabController>();
  }

  @override
  Widget build(BuildContext context) {
    return DragToResizeArea(
      resizeEdgeSize: stateGlobal.resizeEdgeSize.value,
      enableResizeEdges: windowManagerEnableResizeEdges,
      child: Container(
        child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.background,
            body: DesktopTab(controller: tabController)),
      ),
    );
  }
}

class _InstallPageBody extends StatefulWidget {
  const _InstallPageBody({Key? key}) : super(key: key);

  @override
  State<_InstallPageBody> createState() => _InstallPageBodyState();
}

class _InstallPageBodyState extends State<_InstallPageBody>
    with WindowListener {
  late final TextEditingController controller;
  final RxBool startmenu = true.obs;
  final RxBool desktopicon = true.obs;
  final RxBool printer = false.obs;
  final RxBool showProgress = false.obs;
  final RxBool btnEnabled = true.obs;

  // todo move to theme.
  final buttonStyle = OutlinedButton.styleFrom(
    textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 12),
  );

  _InstallPageBodyState() {
    controller = TextEditingController(text: bind.installInstallPath());
    final installOptions = jsonDecode(bind.installInstallOptions());
    startmenu.value = installOptions['STARTMENUSHORTCUTS'] != '0';
    desktopicon.value = installOptions['DESKTOPSHORTCUTS'] != '0';
    printer.value = installOptions['PRINTER'] == '1';
  }

  @override
  void initState() {
    windowManager.addListener(this);
    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() {
    gFFI.close();
    super.onWindowClose();
    windowManager.setPreventClose(false);
    windowManager.close();
  }

  Widget _opt(RxBool option, String label, IconData ic) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => btnEnabled.value ? option.value = !option.value : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kLine, width: 1.4),
        ),
        child: Row(children: [
          Icon(ic, size: 19, color: _kBrand),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: _kInk, fontSize: 14, fontWeight: FontWeight.w600))),
          Obx(() => AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 44,
                height: 26,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                    gradient: option.value
                        ? const LinearGradient(colors: [_kBrand, _kBlue])
                        : null,
                    color: option.value ? null : const Color(0xFFD8E2EC),
                    borderRadius: BorderRadius.circular(999)),
                alignment:
                    option.value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle)),
              )),
        ]),
      ),
    );
  }

  Widget _hero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(30, 26, 30, 26),
      decoration:
          const BoxDecoration(gradient: LinearGradient(colors: [_kBrand, _kBlue])),
      child: Row(children: [
        Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(13)),
            child: Image.asset('assets/fenikya_logo.png', width: 32, height: 32)),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('Fenikya Destek',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
          SizedBox(height: 2),
          Text('Kurulum Sihirbazı',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: 'Segoe UI',
        colorScheme:
            ColorScheme.fromSeed(seedColor: _kBrand, brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFFEFF5F9),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFEFF5F9),
        body: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _hero(),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 22, 28, 26),
              child: Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _kLine),
                  boxShadow: [
                    BoxShadow(
                        color: _kInk.withOpacity(.07),
                        blurRadius: 30,
                        offset: const Offset(0, 12))
                  ],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Bilgisayarınıza kurun',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800, color: _kInk)),
                  const SizedBox(height: 4),
                  const Text(
                      'Fenikya Destek\'i kurarak masaüstünden tek tıkla başlatabilirsiniz.',
                      style: TextStyle(color: _kMuted, fontSize: 13.5)),
                  const SizedBox(height: 20),
                  const Text('Kurulum Konumu',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _kInk2)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF7FAFC),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: _kLine, width: 1.4)),
                        child: Row(children: [
                          const Icon(Icons.folder_rounded,
                              size: 17, color: Color(0xFF93A6BA)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: controller,
                              readOnly: true,
                              style: const TextStyle(color: _kInk, fontSize: 13),
                              decoration: const InputDecoration(
                                  isCollapsed: true,
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  border: InputBorder.none),
                            ).workaroundFreezeLinuxMint(),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Obx(() => InkWell(
                          borderRadius: BorderRadius.circular(11),
                          onTap: btnEnabled.value ? selectInstallPath : null,
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: const Color(0xFFEEF4F8),
                                borderRadius: BorderRadius.circular(11)),
                            child: const Text('Değiştir',
                                style: TextStyle(
                                    color: _kInk2,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ),
                        )),
                  ]),
                  const SizedBox(height: 20),
                  _opt(startmenu, 'Başlat menüsü kısayolu oluştur',
                      Icons.push_pin_outlined),
                  _opt(desktopicon, 'Masaüstü simgesi oluştur',
                      Icons.desktop_windows_outlined),
                  _opt(printer, 'Fenikya Destek Yazıcısını kur',
                      Icons.print_outlined),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF0F7FB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDCEAF2))),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.shield_rounded, size: 22, color: _kBrand),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                  'Kurmaya devam ederek uçtan uca şifreli, güvenli uzak destek koşullarını kabul etmiş olursunuz.',
                                  style: TextStyle(
                                      color: _kInk2, fontSize: 12.8, height: 1.45)),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => launchUrlString(
                                    'https://destek.fenikya.com.tr/gizlilik'),
                                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                                  Icon(Icons.launch_rounded, size: 14, color: _kBlue),
                                  SizedBox(width: 6),
                                  Text('Gizlilik ve Kullanım Koşulları',
                                      style: TextStyle(
                                          color: _kBlue,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.8,
                                          decoration: TextDecoration.underline,
                                          decorationColor: _kBlue)),
                                ]),
                              ),
                            ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  Obx(() => showProgress.value
                      ? const Padding(
                          padding: EdgeInsets.only(bottom: 14),
                          child: ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            child: LinearProgressIndicator(
                                minHeight: 6, color: _kBrand),
                          ),
                        )
                      : const SizedBox.shrink()),
                  Row(children: [
                    Offstage(
                      offstage: bind.installShowRunWithoutInstall(),
                      child: Obx(() => InkWell(
                            onTap: btnEnabled.value
                                ? () => bind.installRunWithoutInstall()
                                : null,
                            child: const Text('Kurmadan çalıştır',
                                style: TextStyle(
                                    color: _kMuted,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    decoration: TextDecoration.underline)),
                          )),
                    ),
                    const Spacer(),
                    Obx(() => InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap:
                              btnEnabled.value ? () => windowManager.close() : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 13),
                            decoration: BoxDecoration(
                                color: const Color(0xFFEEF4F8),
                                borderRadius: BorderRadius.circular(12)),
                            child: const Text('İptal',
                                style: TextStyle(
                                    color: _kInk2,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                          ),
                        )),
                    const SizedBox(width: 12),
                    Obx(() => Opacity(
                          opacity: btnEnabled.value ? 1 : .6,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: btnEnabled.value ? install : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 26, vertical: 13),
                              decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                      colors: [_kBrand, _kBlue]),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                        color: _kBlue.withOpacity(.32),
                                        blurRadius: 18,
                                        offset: const Offset(0, 7))
                                  ]),
                              child: Row(mainAxisSize: MainAxisSize.min, children: const [
                                Icon(Icons.download_rounded,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('Kabul Et ve Kur',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14.5)),
                              ]),
                            ),
                          ),
                        )),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void install() {
    do_install() {
      btnEnabled.value = false;
      showProgress.value = true;
      String args = '';
      if (startmenu.value) args += ' startmenu';
      if (desktopicon.value) args += ' desktopicon';
      if (printer.value) args += ' printer';
      bind.installInstallMe(options: args, path: controller.text);
    }

    do_install();
  }

  void selectInstallPath() async {
    String? install_path = await FilePicker.platform
        .getDirectoryPath(initialDirectory: controller.text);
    if (install_path != null) {
      controller.text = join(install_path, await bind.mainGetAppName());
    }
  }
}
