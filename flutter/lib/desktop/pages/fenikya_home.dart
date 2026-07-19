// Fenikya Destek - markali ana ekran (DESTEK AL / DESTEK VER)
// RustDesk motoru uzerine giydirilmis ozel arayuz. Gercek ID + baglan mantigi
// gFFI.serverModel + connect() uzerinden baglanir.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../common.dart' hide Dialog;
import '../../common/formatter/id_formatter.dart';
import '../../models/server_model.dart';
import 'desktop_home_page.dart' show setPasswordDialog;

// ---- Fenikya marka renkleri ----
const kBrand = Color(0xFF0EA5B7);
const kBrandD = Color(0xFF0B7F8C);
const kBlue = Color(0xFF1D4ED8);
const kBlueD = Color(0xFF1E40AF);
const kInk = Color(0xFF0B2440);
const kInk2 = Color(0xFF31465E);
const kMuted = Color(0xFF7189A3);
const kLine = Color(0xFFE6EEF5);
const kOk = Color(0xFF12B76A);

class FenikyaHome extends StatefulWidget {
  const FenikyaHome({Key? key}) : super(key: key);
  @override
  State<FenikyaHome> createState() => _FenikyaHomeState();
}

class _FenikyaHomeState extends State<FenikyaHome> {
  int tab = 0; // 0 = DESTEK AL, 1 = DESTEK VER
  final _idCtrl = IDTextEditingController();
  final _pwCtrl = TextEditingController();
  bool _pwObscure = true;

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  void _doConnect() {
    final id = _idCtrl.id.trim();
    if (id.isEmpty) return;
    final pw = _pwCtrl.text.trim();
    connect(context, id,
        password: pw.isEmpty ? null : pw, isSharedPassword: false);
  }

  @override
  Widget build(BuildContext context) {
    // Uygulama koyu temada olsa bile bu ekran DAIMA acik (light) tema kullanir;
    // aksi halde text field'lar koyu dolgu alip yazilan gorunmez.
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
            seedColor: kBrand, brightness: Brightness.light),
        inputDecorationTheme: const InputDecorationTheme(
            filled: false, border: InputBorder.none),
        textSelectionTheme: TextSelectionThemeData(
            cursorColor: kBlue, selectionColor: kBlue.withOpacity(.25)),
      ),
      child: Container(
        color: Colors.white,
        child: Column(children: [
          _header(),
          Expanded(child: _body()),
          _footer(),
        ]),
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _header() {
    Widget tabBtn(String t, IconData ic, int i) {
      final active = tab == i;
      return GestureDetector(
        onTap: () => setState(() => tab = i),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: active
              ? BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: kInk.withOpacity(.05), blurRadius: 3)])
              : null,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(ic, size: 17, color: active ? kBrand : kMuted),
            const SizedBox(width: 8),
            Text(t,
                style: TextStyle(
                    color: active ? kBrand : kMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5)),
          ]),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(26, 14, 20, 14),
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: kLine))),
      child: Row(children: [
        Image.asset('assets/fenikya_logo.png', width: 38, height: 38),
        const SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(
              color: const Color(0xFFEEF4F8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kLine)),
          padding: const EdgeInsets.all(5),
          child: Row(children: [
            tabBtn('DESTEK AL', Icons.download_rounded, 0),
            tabBtn('DESTEK VER', Icons.upload_rounded, 1),
          ]),
        ),
        const Spacer(),
        _statusPill(),
        const SizedBox(width: 10),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: () => showDialog(
                context: context,
                barrierColor: kInk.withOpacity(.32),
                builder: (_) => const _SettingsDialog()),
            child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: kLine)),
                child: const Icon(Icons.tune_rounded, size: 18, color: kInk2)),
          ),
        ),
        const SizedBox(width: 10),
        Container(
            width: 34,
            height: 23,
            decoration: BoxDecoration(
                color: const Color(0xFFE30A17),
                borderRadius: BorderRadius.circular(5)),
            child: const Center(
                child: Text('☾★',
                    style: TextStyle(color: Colors.white, fontSize: 13)))),
      ]),
    );
  }

  Widget _statusPill() {
    return ChangeNotifierProvider.value(
      value: gFFI.serverModel,
      child: Consumer<ServerModel>(builder: (context, model, _) {
        // connectStatus: 1 = hazir/aktif, 0 = baglaniyor, -1 = hazir degil
        final ready = model.connectStatus == 1;
        final label = ready ? 'Aktif' : 'Bağlanıyor';
        final bg = ready ? const Color(0xFFE8FAF1) : const Color(0xFFFEF3E7);
        final border =
            ready ? const Color(0xFFC7F0DA) : const Color(0xFFF6D9B0);
        final dot = ready ? kOk : const Color(0xFFE59A2B);
        final txt =
            ready ? const Color(0xFF0E7A45) : const Color(0xFF9A6212);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: border)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: dot, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: txt, fontWeight: FontWeight.bold, fontSize: 12.5)),
          ]),
        );
      }),
    );
  }

  // ---------------- BODY ----------------
  Widget _body() {
    return SizedBox(
      width: double.infinity,
      child: Stack(children: [
        // Istanbul arka plan - tum govdeyi doldurur
        Positioned.fill(
          child: Image.asset('assets/fenikya_istanbul.png',
              fit: BoxFit.cover, alignment: Alignment.center),
        ),
        Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: IgnorePointer(
                child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                      Colors.white.withOpacity(.85),
                      Colors.white.withOpacity(0)
                    ]))))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: Center(child: tab == 0 ? _alBody() : _verBody()),
        ),
      ]),
    );
  }

  // ---------------- DESTEK AL ----------------
  Widget _alBody() {
    return ChangeNotifierProvider.value(
      value: gFFI.serverModel,
      child: Consumer<ServerModel>(builder: (context, model, _) {
        final id = model.serverId.text;
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                      colors: [Color(0xFFE7F7FA), Color(0xFFDFEEFC)])),
              child: const Icon(Icons.groups_rounded, color: kBrand, size: 26)),
          const SizedBox(height: 14),
          _glass(
              600,
              22,
              Column(children: [
                const Text("DESTEK ID'NİZ",
                    style: TextStyle(
                        color: kMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: .5)),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  ShaderMask(
                      shaderCallback: (r) =>
                          const LinearGradient(colors: [kBrand, kBlue])
                              .createShader(r),
                      child: Text(id,
                          style: const TextStyle(
                              fontSize: 46,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 4,
                              height: 1))),
                  const SizedBox(width: 16),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(13),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: id));
                        showToast(translate("Copied"));
                      },
                      child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(color: kLine)),
                          child: const Icon(Icons.copy_rounded,
                              color: kInk2, size: 20)),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                const Text("Bu ID'yi destek sağlayıcınızla paylaşın.",
                    style: TextStyle(color: kMuted, fontSize: 13.5)),
              ])),
          const SizedBox(height: 16),
          _glass(
              600,
              16,
              Row(children: [
                Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: const Color(0xFFE8FAF1),
                        borderRadius: BorderRadius.circular(12)),
                    child:
                        const Icon(Icons.shield_rounded, color: kOk, size: 22)),
                const SizedBox(width: 16),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('Hazır',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kInk)),
                      Text('Güvenli bağlantı aktif',
                          style: TextStyle(fontSize: 13, color: kMuted)),
                    ]),
                const Spacer(),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(11),
                    onTap: () => setPasswordDialog(),
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                            color: const Color(0xFFEEF4F8),
                            borderRadius: BorderRadius.circular(11)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: const [
                          Icon(Icons.key_rounded, size: 15, color: kInk2),
                          SizedBox(width: 6),
                          Text('Kalıcı Şifre',
                              style: TextStyle(
                                  color: kInk2,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5)),
                        ])),
                  ),
                ),
              ])),
        ]);
      }),
    );
  }

  // ---------------- DESTEK VER ----------------
  Widget _verBody() {
    return _glass(
        470,
        24,
        Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                      colors: [Color(0xFFE8EEFC), Color(0xFFEEF2FD)])),
              child: const Icon(Icons.desktop_windows_rounded,
                  color: kBlue, size: 24)),
          const SizedBox(height: 10),
          const Text('Başka bir bilgisayara bağlanın',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: kInk)),
          const SizedBox(height: 3),
          const Text('Karşı cihazdaki 9 haneli ID numarasını girin.',
              style: TextStyle(color: kMuted, fontSize: 13.5)),
          const SizedBox(height: 14),
          _fieldLabel('Uzak Cihaz ID'),
          _fieldBox(
            child: Row(children: [
              const Icon(Icons.arrow_forward_rounded,
                  size: 18, color: Color(0xFF93A6BA)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _idCtrl,
                  inputFormatters: [IDTextInputFormatter()],
                  keyboardType: TextInputType.visiblePassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  cursorColor: kBlue,
                  onSubmitted: (_) => _doConnect(),
                  style: const TextStyle(
                      color: kInk, fontSize: 16, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                      isCollapsed: true,
                      filled: true,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: '9 haneli ID',
                      hintStyle:
                          TextStyle(color: Color(0xFF9DB0C4), fontSize: 16)),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final data = await Clipboard.getData('text/plain');
                  if (data?.text != null) {
                    setState(() => _idCtrl.id = data!.text!.trim());
                  }
                },
                child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                        color: const Color(0xFFEEF4F8),
                        borderRadius: BorderRadius.circular(9)),
                    child: const Text('Yapıştır',
                        style: TextStyle(
                            color: kInk2,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5))),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          _fieldLabel('Şifre · kalıcı erişim (opsiyonel)'),
          _fieldBox(
            child: Row(children: [
              const Icon(Icons.lock_outline_rounded,
                  size: 18, color: Color(0xFF93A6BA)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _pwCtrl,
                  obscureText: _pwObscure,
                  cursorColor: kBlue,
                  onSubmitted: (_) => _doConnect(),
                  style: const TextStyle(
                      color: kInk, fontSize: 14, fontWeight: FontWeight.w400),
                  decoration: const InputDecoration(
                      isCollapsed: true,
                      filled: true,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: 'Şifreyi biliyorsanız onaysız bağlanın',
                      hintStyle:
                          TextStyle(color: Color(0xFF9DB0C4), fontSize: 14)),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _pwObscure = !_pwObscure),
                child: Icon(
                    _pwObscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: const Color(0xFF93A6BA)),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(13),
              onTap: _doConnect,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [kBlue, kBlueD]),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                          color: kBlue.withOpacity(.35),
                          blurRadius: 22,
                          offset: const Offset(0, 8))
                    ]),
                child: const Center(
                    child: Text('➜  BAĞLAN',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15))),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
            Icon(Icons.lock_rounded, size: 13, color: kMuted),
            SizedBox(width: 7),
            Flexible(
              child: Text(
                  'Şifre yoksa karşı taraf onay vermeden bağlantı başlamaz.',
                  style: TextStyle(color: kMuted, fontSize: 12)),
            ),
          ]),
        ]));
  }

  Widget _fieldLabel(String t) => Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: const TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w700, color: kInk2)),
      ));

  Widget _fieldBox({required Widget child}) => Container(
        height: 46,
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(.9),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: kLine, width: 1.5)),
        padding: const EdgeInsets.symmetric(horizontal: 13),
        child: child,
      );

  // ---------------- FOOTER ----------------
  Widget _footer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
      decoration:
          const BoxDecoration(border: Border(top: BorderSide(color: kLine))),
      child: Row(children: [
        Expanded(
            child: Row(children: const [
          _Dot(),
          SizedBox(width: 8),
          Text('Uçtan uca şifreli bağlantı',
              style: TextStyle(
                  color: kMuted, fontWeight: FontWeight.w600, fontSize: 12))
        ])),
        const Text('✦  Güvenli. Hızlı. Kolay.  ✦',
            style: TextStyle(
                color: kInk, fontWeight: FontWeight.w800, fontSize: 12)),
        Expanded(
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: const [
          Icon(Icons.lock_rounded, size: 13, color: kBrand),
          SizedBox(width: 6),
          Text('256-bit AES',
              style: TextStyle(
                  color: kMuted, fontWeight: FontWeight.w600, fontSize: 12)),
          SizedBox(width: 8),
          Text('v1.0.0',
              style: TextStyle(
                  color: kInk2, fontWeight: FontWeight.w700, fontSize: 11)),
        ])),
      ]),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) => Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(color: kOk, shape: BoxShape.circle));
}

// ortak cam kart
Widget _glass(double maxW, double radius, Widget child) => Container(
      constraints: BoxConstraints(maxWidth: maxW),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white.withOpacity(.64), Colors.white.withOpacity(.50)]),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withOpacity(.6)),
        boxShadow: [
          BoxShadow(
              color: kInk.withOpacity(.12),
              blurRadius: 44,
              offset: const Offset(0, 18))
        ],
      ),
      child: child,
    );

// ---------------- AYARLAR / HAKKIMIZDA DIALOG ----------------
class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog();
  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 460,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: kInk.withOpacity(.30),
                blurRadius: 60,
                offset: const Offset(0, 22))
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 18, 16, 18),
            decoration:
                const BoxDecoration(gradient: LinearGradient(colors: [kBrand, kBlue])),
            child: Row(children: [
              const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              const Text('Ayarlar',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 17)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.2),
                        borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 18)),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _row(Icons.language_rounded, 'Dil',
                  trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                          color: const Color(0xFFEEF4F8),
                          borderRadius: BorderRadius.circular(9)),
                      child: const Text('Türkçe',
                          style: TextStyle(
                              color: kInk2,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)))),
            ]),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(22, 8, 22, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFFF6FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kLine)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Image.asset('assets/fenikya_logo.png', width: 30, height: 30),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('Fenikya Destek',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, color: kInk, fontSize: 15)),
                  Text('Sürüm 1.0.0',
                      style: TextStyle(color: kMuted, fontSize: 12.5)),
                ]),
              ]),
              const SizedBox(height: 12),
              const Text(
                  'fenikya.com tarafından sunulan ücretsiz, uçtan uca şifreli uzak masaüstü destek yazılımı. Verileriniz üçüncü taraflarla paylaşılmaz.',
                  style: TextStyle(color: kInk2, fontSize: 12.8, height: 1.5)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
            child: Row(children: [
              Expanded(
                  child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [kBrand, kBlue]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: kBlue.withOpacity(.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6))
                        ]),
                    child: const Text('Kapat',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14))),
              )),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _row(IconData ic, String label,
          {required Widget trailing, VoidCallback? onTap}) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(children: [
              Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: const Color(0xFFEFF5F9),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(ic, size: 18, color: kBrand)),
              const SizedBox(width: 13),
              Text(label,
                  style: const TextStyle(
                      color: kInk, fontWeight: FontWeight.w600, fontSize: 14.5)),
              const Spacer(),
              trailing,
            ]),
          ),
        ),
      );
  Widget _line() => Container(height: 1, color: kLine);
}
