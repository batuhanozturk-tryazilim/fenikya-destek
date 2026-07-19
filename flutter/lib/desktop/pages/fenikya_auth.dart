// Fenikya Destek - Giris kapisi (login / kayit / sifre sifirlama)
// Backend: https://destek.fenikya.com.tr/api/auth/*  (http paketi ile)

import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher_string.dart';

const kFenikyaBase = 'https://destek.fenikya.com.tr';

// ---- Fenikya marka renkleri ----
const _kBrand = Color(0xFF0EA5B7);
const _kBlue = Color(0xFF1D4ED8);
const _kBlueD = Color(0xFF1E40AF);
const _kInk = Color(0xFF0B2440);
const _kInk2 = Color(0xFF31465E);
const _kMuted = Color(0xFF7189A3);
const _kLine = Color(0xFFE6EEF5);

// ==================== API ====================
class FenikyaAuthApi {
  static Future<Map<String, dynamic>> _post(String path, Map body) async {
    late http.Response r;
    try {
      r = await http
          .post(Uri.parse('$kFenikyaBase$path'),
              headers: const {
                'Content-Type': 'application/json',
                'Accept': 'application/json'
              },
              body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw 'Sunucuya ulaşılamadı. İnternet bağlantınızı kontrol edin.';
    }
    Map<String, dynamic> j;
    try {
      j = jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {
      throw 'Sunucu beklenmeyen bir yanıt döndü.';
    }
    if ((r.statusCode == 200 || r.statusCode == 201) && j['success'] == true) {
      return (j['data'] as Map<String, dynamic>?) ?? {};
    }
    throw (j['message'] ?? 'İşlem başarısız.').toString();
  }

  static Future<String> login(String email, String pw) async {
    final d = await _post('/api/auth/login', {'email': email, 'password': pw});
    return (d['token'] ?? '').toString();
  }

  static Future<String> register(
      String name, String email, String phone, String pw) async {
    final d = await _post('/api/auth/register',
        {'name': name, 'email': email, 'phone': phone, 'password': pw});
    return (d['token'] ?? '').toString();
  }

  static Future<void> forgot(String email) async {
    await _post('/api/auth/forgot', {'email': email});
  }
}

// ==================== EKRAN ====================
class FenikyaAuthScreen extends StatefulWidget {
  final void Function(String token) onAuthed;
  const FenikyaAuthScreen({Key? key, required this.onAuthed}) : super(key: key);
  @override
  State<FenikyaAuthScreen> createState() => _FenikyaAuthScreenState();
}

class _FenikyaAuthScreenState extends State<FenikyaAuthScreen> {
  String mode = 'login'; // login | register | forgot
  bool loading = false;
  String? error;
  String? info;

  final nameC = TextEditingController();
  final emailC = TextEditingController();
  final phoneC = TextEditingController();
  final pwC = TextEditingController();
  bool kvkk = false;

  late final _tapKvkk = TapGestureRecognizer()
    ..onTap = () => launchUrlString('$kFenikyaBase/kvkk');
  late final _tapGiz = TapGestureRecognizer()
    ..onTap = () => launchUrlString('$kFenikyaBase/gizlilik');

  @override
  void dispose() {
    nameC.dispose();
    emailC.dispose();
    phoneC.dispose();
    pwC.dispose();
    _tapKvkk.dispose();
    _tapGiz.dispose();
    super.dispose();
  }

  void _go(String m) => setState(() {
        mode = m;
        error = null;
        info = null;
      });

  Future<void> _run(Future<void> Function() action) async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
      info = null;
    });
    try {
      await action();
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _submitLogin() => _run(() async {
        final email = emailC.text.trim();
        final pw = pwC.text;
        if (email.isEmpty || pw.isEmpty) throw 'E-posta ve şifre gerekli.';
        final token = await FenikyaAuthApi.login(email, pw);
        widget.onAuthed(token);
      });

  void _submitRegister() => _run(() async {
        final name = nameC.text.trim();
        final email = emailC.text.trim();
        final phone = phoneC.text.trim();
        final pw = pwC.text;
        if (name.isEmpty) throw 'Ad soyad gerekli.';
        if (email.isEmpty) throw 'E-posta gerekli.';
        if (phone.replaceAll(RegExp(r'\D'), '').length < 10) {
          throw 'Geçerli bir telefon numarası girin.';
        }
        if (pw.length < 6) throw 'Şifre en az 6 karakter olmalı.';
        if (!kvkk) throw 'Devam etmek için KVKK ve Gizlilik metnini onaylayın.';
        final token = await FenikyaAuthApi.register(name, email, phone, pw);
        widget.onAuthed(token);
      });

  void _submitForgot() => _run(() async {
        final email = emailC.text.trim();
        if (email.isEmpty) throw 'E-posta gerekli.';
        await FenikyaAuthApi.forgot(email);
        setState(() =>
            info = 'Sıfırlama bağlantısı e-posta adresinize gönderildi.');
      });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: 'Segoe UI',
        colorScheme:
            ColorScheme.fromSeed(seedColor: _kBrand, brightness: Brightness.light),
        textSelectionTheme: TextSelectionThemeData(
            cursorColor: _kBlue, selectionColor: _kBlue.withOpacity(.25)),
      ),
      child: Container(
        color: Colors.white,
        child: Row(children: [
          _brandPanel(),
          Expanded(child: _formPanel()),
        ]),
      ),
    );
  }

  Widget _brandPanel() {
    return SizedBox(
      width: 380,
      child: Stack(fit: StackFit.expand, children: [
        Image.asset('assets/fenikya_istanbul.png',
            fit: BoxFit.cover, alignment: Alignment.center),
        Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_kInk.withOpacity(.80), _kBlueD.withOpacity(.85)]))),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 30, 28, 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(11)),
                  child:
                      Image.asset('assets/fenikya_logo.png', width: 26, height: 26)),
              const SizedBox(width: 11),
              const Text('Fenikya Destek',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 17)),
            ]),
            const Spacer(),
            const Text('Uzak masaüstü desteği,\nsaniyeler içinde.',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 23,
                    height: 1.25)),
            const SizedBox(height: 13),
            Text('Fenikya hesabınızla giriş yapın; güvenli uzak destek alın veya verin.',
                style: TextStyle(
                    color: Colors.white.withOpacity(.85),
                    fontSize: 13,
                    height: 1.5)),
            const SizedBox(height: 24),
            _feat(Icons.shield_rounded, 'Uçtan uca şifreli · 256-bit AES'),
            const SizedBox(height: 13),
            _feat(Icons.bolt_rounded, 'Hızlı, kurulumsuz bağlantı'),
            const SizedBox(height: 13),
            _feat(Icons.verified_rounded, 'Tamamen ücretsiz'),
            const Spacer(),
            Text('© 2026 fenikya.com',
                style:
                    TextStyle(color: Colors.white.withOpacity(.6), fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  Widget _feat(IconData ic, String t) => Row(children: [
        Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(.16),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(ic, color: Colors.white, size: 17)),
        const SizedBox(width: 11),
        Expanded(
            child: Text(t,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600))),
      ]);

  Widget _formPanel() {
    return Container(
      color: Colors.white,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 340),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0.05, 0), end: Offset.zero)
                        .animate(anim),
                    child: child,
                  ),
                ),
                layoutBuilder: (cur, prev) => Stack(
                    alignment: Alignment.topCenter,
                    children: [...prev, if (cur != null) cur]),
                child: KeyedSubtree(
                  key: ValueKey(mode),
                  child: mode == 'register'
                      ? _registerForm()
                      : (mode == 'forgot' ? _forgotForm() : _loginForm()),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _banner() {
    if (error == null && info == null) return const SizedBox(height: 4);
    final isErr = error != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
          color: isErr ? const Color(0xFFFDECEC) : const Color(0xFFE8FAF1),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
              color: isErr ? const Color(0xFFF5C2C2) : const Color(0xFFBEEBD3))),
      child: Row(children: [
        Icon(isErr ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            size: 18, color: isErr ? const Color(0xFFD64545) : const Color(0xFF0E9F6E)),
        const SizedBox(width: 10),
        Expanded(
            child: Text(isErr ? error! : info!,
                style: TextStyle(
                    color: isErr ? const Color(0xFF9B2C2C) : const Color(0xFF066B4A),
                    fontSize: 12.8,
                    fontWeight: FontWeight.w600,
                    height: 1.35))),
      ]),
    );
  }

  Widget _loginForm() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Tekrar hoş geldiniz',
              style: TextStyle(
                  fontSize: 25, fontWeight: FontWeight.w800, color: _kInk)),
          const SizedBox(height: 6),
          const Text('Hesabınıza giriş yapın.',
              style: TextStyle(color: _kMuted, fontSize: 14)),
          const SizedBox(height: 24),
          _banner(),
          _FField(emailC, 'E-posta', Icons.mail_outline_rounded, 'ornek@email.com',
              keyboard: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _FField(pwC, 'Şifre', Icons.lock_outline_rounded, '••••••••',
              obscure: true, onSubmit: _submitLogin),
          const SizedBox(height: 10),
          Align(
              alignment: Alignment.centerRight,
              child: _Hover('Şifremi unuttum?',
                  size: 13, onTap: () => _go('forgot'))),
          const SizedBox(height: 20),
          _SubmitButton('Giriş Yap', Icons.login_rounded, loading, _submitLogin),
          const SizedBox(height: 22),
          _switchRow('Hesabınız yok mu?', 'Kayıt olun', () => _go('register')),
        ]);
  }

  Widget _registerForm() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Hesap oluştur',
              style: TextStyle(
                  fontSize: 25, fontWeight: FontWeight.w800, color: _kInk)),
          const SizedBox(height: 6),
          const Text('Ücretsiz Fenikya Destek hesabı.',
              style: TextStyle(color: _kMuted, fontSize: 14)),
          const SizedBox(height: 18),
          _banner(),
          _FField(nameC, 'Ad Soyad', Icons.person_outline_rounded,
              'Adınız Soyadınız'),
          const SizedBox(height: 12),
          _FField(emailC, 'E-posta', Icons.mail_outline_rounded, 'ornek@email.com',
              keyboard: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _FField(phoneC, 'Telefon', Icons.phone_outlined, '05XX XXX XX XX',
              isRequired: true, keyboard: TextInputType.phone),
          const SizedBox(height: 12),
          _FField(pwC, 'Şifre', Icons.lock_outline_rounded, 'En az 6 karakter',
              obscure: true, onSubmit: _submitRegister),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GestureDetector(
                onTap: () => setState(() => kvkk = !kvkk),
                child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                        gradient: kvkk
                            ? const LinearGradient(colors: [_kBrand, _kBlue])
                            : null,
                        color: kvkk ? null : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border:
                            Border.all(color: kvkk ? _kBlue : _kLine, width: 1.5)),
                    child: AnimatedScale(
                        scale: kvkk ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutBack,
                        child: const Icon(Icons.check_rounded,
                            size: 15, color: Colors.white)))),
            const SizedBox(width: 10),
            Expanded(
                child: Text.rich(TextSpan(
                    style: const TextStyle(
                        color: _kMuted, fontSize: 12.5, height: 1.4),
                    children: [
                  const TextSpan(text: 'KVKK '),
                  TextSpan(
                      text: 'Aydınlatma Metni',
                      style: const TextStyle(
                          color: _kBlue,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: _kBlue),
                      mouseCursor: SystemMouseCursors.click,
                      recognizer: _tapKvkk),
                  const TextSpan(text: ' ve '),
                  TextSpan(
                      text: 'Gizlilik Politikası',
                      style: const TextStyle(
                          color: _kBlue,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: _kBlue),
                      mouseCursor: SystemMouseCursors.click,
                      recognizer: _tapGiz),
                  const TextSpan(text: "'nı okudum, onaylıyorum."),
                ]))),
          ]),
          const SizedBox(height: 18),
          _SubmitButton(
              'Kayıt Ol', Icons.person_add_alt_1_rounded, loading, _submitRegister),
          const SizedBox(height: 16),
          _switchRow('Zaten üye misiniz?', 'Giriş yapın', () => _go('login')),
        ]);
  }

  Widget _forgotForm() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _go('login'),
                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.arrow_back_rounded, size: 16, color: _kMuted),
                  SizedBox(width: 6),
                  Text('Giriş\'e dön',
                      style: TextStyle(
                          color: _kMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                      colors: [Color(0xFFE7F7FA), Color(0xFFDFEEFC)])),
              child: const Icon(Icons.lock_reset_rounded, color: _kBrand, size: 27),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Şifrenizi mi unuttunuz?',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800, color: _kInk)),
          const SizedBox(height: 6),
          const Text(
              'E-posta adresinizi girin, size şifre sıfırlama bağlantısı gönderelim.',
              style: TextStyle(color: _kMuted, fontSize: 14, height: 1.5)),
          const SizedBox(height: 22),
          _banner(),
          _FField(emailC, 'E-posta', Icons.mail_outline_rounded, 'ornek@email.com',
              keyboard: TextInputType.emailAddress, onSubmit: _submitForgot),
          const SizedBox(height: 20),
          _SubmitButton('Sıfırlama Bağlantısı Gönder', Icons.send_rounded, loading,
              _submitForgot),
          const SizedBox(height: 22),
          _switchRow('Şifrenizi hatırladınız mı?', 'Giriş yapın', () => _go('login')),
        ]);
  }

  Widget _switchRow(String q, String a, VoidCallback onTap) =>
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(q, style: const TextStyle(color: _kMuted, fontSize: 13.5)),
        const SizedBox(width: 6),
        _Hover(a, onTap: onTap),
      ]);
}

// ---- odaklaninca canlanan yazilabilir alan ----
class _FField extends StatefulWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final bool obscure, isRequired;
  final TextInputType? keyboard;
  final VoidCallback? onSubmit;
  const _FField(this.controller, this.label, this.icon, this.hint,
      {this.obscure = false,
      this.isRequired = false,
      this.keyboard,
      this.onSubmit});
  @override
  State<_FField> createState() => _FFieldState();
}

class _FFieldState extends State<_FField> {
  final _fn = FocusNode();
  bool _hover = false;
  late bool _obscure = widget.obscure;

  @override
  void initState() {
    super.initState();
    _fn.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _fn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _fn.hasFocus;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(widget.label,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: active ? _kBlue : _kInk2)),
        if (widget.isRequired)
          const Text(' *',
              style: TextStyle(
                  color: Color(0xFFE5484D),
                  fontWeight: FontWeight.w800,
                  fontSize: 13)),
      ]),
      const SizedBox(height: 6),
      MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOut,
          height: 46,
          decoration: BoxDecoration(
            color: active ? Colors.white : const Color(0xFFF7FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: active
                    ? _kBlue
                    : (_hover ? const Color(0xFFC6D6E4) : _kLine),
                width: active ? 1.8 : 1.5),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: _kBlue.withOpacity(.14),
                        blurRadius: 12,
                        offset: const Offset(0, 3))
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(children: [
            Icon(widget.icon,
                size: 18, color: active ? _kBlue : const Color(0xFF93A6BA)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _fn,
                obscureText: _obscure,
                keyboardType: widget.keyboard,
                cursorColor: _kBlue,
                onSubmitted: (_) => widget.onSubmit?.call(),
                style: const TextStyle(
                    color: _kInk, fontSize: 14.5, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                    isCollapsed: true,
                    filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: const TextStyle(
                        color: Color(0xFF9DB0C4), fontSize: 14.5)),
              ),
            ),
            if (widget.obscure)
              GestureDetector(
                onTap: () => setState(() => _obscure = !_obscure),
                child: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: const Color(0xFF93A6BA)),
              ),
          ]),
        ),
      ),
      // hint (TextField bos oldugunda)
      const SizedBox(height: 0),
    ]);
  }
}

// ---- yuklenme + basma hissi olan gonder butonu ----
class _SubmitButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final bool loading;
  final VoidCallback onTap;
  const _SubmitButton(this.text, this.icon, this.loading, this.onTap);
  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _hover = false, _down = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) {
          setState(() => _down = false);
          if (!widget.loading) widget.onTap();
        },
        onTapCancel: () => setState(() => _down = false),
        child: AnimatedScale(
          scale: _down ? 0.97 : (_hover ? 1.015 : 1.0),
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_kBrand, _kBlue]),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                    color: _kBlue.withOpacity(_hover ? .42 : .30),
                    blurRadius: _hover ? 28 : 20,
                    offset: Offset(0, _hover ? 11 : 8))
              ],
            ),
            child: widget.loading
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(widget.icon, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Text(widget.text,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15.5)),
                  ]),
          ),
        ),
      ),
    );
  }
}

// ---- hover'da alti cizilen link ----
class _Hover extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;
  final double size;
  const _Hover(this.text, {this.onTap, this.size = 13.5});
  @override
  State<_Hover> createState() => _HoverState();
}

class _HoverState extends State<_Hover> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(widget.text,
            style: TextStyle(
                color: _kBlue,
                fontSize: widget.size,
                fontWeight: FontWeight.w800,
                decoration: _h ? TextDecoration.underline : null,
                decorationColor: _kBlue)),
      ),
    );
  }
}
