import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart' show CupertinoPicker;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ═════════════════════════════════════════════════════════════════════════
//  طبيبك للأطباء — تطبيق الأخصائي
//  • نفس تصميم تطبيق المرضى وتطبيق المراكز (ألوان، خط، كروت، أزرار).
//  • التسجيل برقم المجلس الطبي + رقم الهاتف (رمز تحقق).
//  • الملف المهني: صورة (اختيارية) · المؤهلات · التخصص · التخصص الفرعي · الدرجة.
//  • أماكن العمل: اختيار مركز مسجّل في طبيبك، أو إضافة مكان جديد ودعوته بواتساب.
//  • عيانين الليلة: قائمة المرضى + التاريخ المرضي + الفحوصات + آخر مقابلة + ملاحظات الكشف.
//  • البيانات محلية في الذاكرة (DocState) ولا يوجد خادم حقيقي بعد — انظر قسم «نقاط الربط».
// ═════════════════════════════════════════════════════════════════════════

// ───────────────────────── Design tokens ─────────────────────────
const kRed = Color(0xFFD9141E);
const kInk = Color(0xFF1B2A4A);
const kGrey = Color(0xFF7B8494);
const kSub = Color(0xFF4B5873);
const kLine = Color(0xFFE9EDF2);
const kBg = Color(0xFFF6F7FB);
const kChip = Color(0xFFF1F3F7);
const kTint = Color(0xFFFDECEE);
const kGreen = Color(0xFF2EAD5C);
const kGreenDk = Color(0xFF2A8F4F);
const kGreenBg = Color(0xFFD9F3E1);
const kAmber = Color(0xFFB7791F);
const kAmberBg = Color(0xFFFFF1D6);
const kGold = Color(0xFFFFB400);
const kBlue = Color(0xFF3B6EF5);
const kBlueBg = Color(0xFFE9EFFF);
const kTeal = Color(0xFF0E9F8E);
const kTealBg = Color(0xFFDDF5F1);
const kOrange = Color(0xFFF2780C);
const kOrangeBg = Color(0xFFFFEEDB);

const kGradient = LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFFF2434D), Color(0xFFC40F1A)]);
const kShadow = [BoxShadow(color: Color(0x141B2A4A), blurRadius: 24, offset: Offset(0, 10)), BoxShadow(color: Color(0x0A1B2A4A), blurRadius: 3, offset: Offset(0, 1))];
const kGlow = [BoxShadow(color: Color(0x40D9141E), blurRadius: 20, offset: Offset(0, 10))];

LinearGradient grad(Color c) => LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [c, Color.alphaBlend(const Color(0x40000000), c)]);

const kFont = 'IBM Plex Sans Arabic';

TextStyle t(double s, {FontWeight w = FontWeight.w700, Color c = kInk, double? h}) {
  try {
    return GoogleFonts.getFont(kFont, fontSize: s, fontWeight: w, color: c, height: h);
  } catch (_) {
    return GoogleFonts.cairo(fontSize: s, fontWeight: w, color: c, height: h);
  }
}

TextTheme appTextTheme() {
  final base = ThemeData.light().textTheme;
  try {
    return GoogleFonts.getTextTheme(kFont, base);
  } catch (_) {
    return GoogleFonts.cairoTextTheme(base);
  }
}

// ───────────────────────── Small helpers ─────────────────────────
Future<T?> go<T>(BuildContext c, Widget w) => Navigator.push<T>(c, MaterialPageRoute<T>(builder: (_) => w));
void home(BuildContext c) => Navigator.pushAndRemoveUntil(c, MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false);

Icon chev([Color c = kRed, double s = 24]) => Icon(Icons.chevron_left_rounded, color: c, size: s, textDirection: TextDirection.ltr);
Icon chevR([Color c = kRed, double s = 24]) => Icon(Icons.chevron_right_rounded, color: c, size: s, textDirection: TextDirection.ltr);

String money(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
int toInt(String s) => int.tryParse(s.replaceAll(',', '')) ?? 0;
Widget gap([double h = 12]) => SizedBox(height: h);
Widget gapW([double w = 10]) => SizedBox(width: w);
String initial(String n) {
  final p = n.replaceFirst('د. ', '').trim();
  return p.isEmpty ? '؟' : p.substring(0, 1);
}

const kWeek = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
const kMonths = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
String dayLabel(DateTime d) => '${kWeek[d.weekday - 1]} ${d.day} ${kMonths[d.month - 1]}';

void snack(BuildContext c, String m, {bool ok = false}) {
  final sm = ScaffoldMessenger.of(c);
  sm.hideCurrentSnackBar();
  sm.showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: kInk,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    content: Row(children: [
      Icon(ok ? Icons.check_circle_rounded : Icons.info_rounded, color: ok ? const Color(0xFF5BD68A) : Colors.white, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(m, style: t(13, w: FontWeight.w600, c: Colors.white))),
    ]),
  ));
}

Future<bool> confirm(BuildContext c, String title, String body, {String yes = 'تأكيد', String no = 'تراجع', bool danger = true}) async {
  final r = await showDialog<bool>(
    context: c,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          tileIcon(danger ? Icons.warning_amber_rounded : Icons.help_outline_rounded, size: 60),
          gap(14),
          Text(title, textAlign: TextAlign.center, style: t(17)),
          gap(6),
          Text(body, textAlign: TextAlign.center, style: t(13, w: FontWeight.w500, c: kGrey, h: 1.6)),
          gap(20),
          RedButton(yes, height: 48, onTap: () => Navigator.pop(ctx, true)),
          gap(10),
          OutBtn(no, onTap: () => Navigator.pop(ctx, false)),
        ]),
      ),
    ),
  );
  return r ?? false;
}

Future<T?> sheet<T>(BuildContext c, Widget child) => showModalBottomSheet<T>(
      context: c,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 20),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 42, height: 4, decoration: BoxDecoration(color: kLine, borderRadius: BorderRadius.circular(2))),
            gap(16),
            child,
          ]),
        ),
      ),
    );

/// يعرض رقم/بريد مع زر نسخ (بديل الاتصال المباشر بدون حزم إضافية).
void contactSheet(BuildContext c, String title, String value, {IconData icon = Icons.phone_rounded}) {
  sheet(
    c,
    Column(children: [
      tileIcon(icon, size: 62),
      gap(12),
      Text(title, style: t(16)),
      gap(6),
      Directionality(textDirection: TextDirection.ltr, child: Text(value, style: t(21, c: kRed))),
      gap(18),
      RedButton('نسخ', icon: Icons.content_copy_rounded, onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        Navigator.pop(c);
        snack(c, 'تم النسخ إلى الحافظة', ok: true);
      }),
    ]),
  );
}

// ───────────────────────── Tap (tactile press) ─────────────────────────
class Tap extends StatefulWidget {
  const Tap({super.key, required this.child, this.onTap, this.scale = .96});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  @override
  State<Tap> createState() => _TapState();
}

class _TapState extends State<Tap> {
  bool down = false;
  void press(bool v) {
    if (down != v) setState(() => down = v);
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: on ? (_) => press(true) : null,
      onTapUp: on ? (_) => press(false) : null,
      onTapCancel: on ? () => press(false) : null,
      onTap: on
          ? () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(scale: down ? widget.scale : 1, duration: const Duration(milliseconds: 100), child: widget.child),
    );
  }
}

// ───────────────────────── Buttons ─────────────────────────
class RedButton extends StatelessWidget {
  const RedButton(this.text, {super.key, required this.onTap, this.icon, this.arrow = false, this.height = 54, this.loading = false, this.enabled = true});
  final String text;
  final VoidCallback onTap;
  final IconData? icon;
  final bool arrow, loading, enabled;
  final double height;
  @override
  Widget build(BuildContext context) {
    final on = enabled && !loading;
    return Semantics(
      button: true,
      enabled: on,
      label: text,
      child: Tap(
        onTap: on ? onTap : null,
        child: Container(
          height: height,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: on ? kGradient : null,
            color: on ? null : const Color(0xFFD5DAE2),
            borderRadius: BorderRadius.circular(18),
            boxShadow: on ? kGlow : null,
          ),
          child: loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 8)],
                  Text(text, style: t(16, c: Colors.white)),
                  if (arrow) ...[const SizedBox(width: 8), const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20)],
                ]),
        ),
      ),
    );
  }
}

class OutBtn extends StatelessWidget {
  const OutBtn(this.text, {super.key, required this.onTap, this.height = 48, this.icon, this.danger = false});
  final String text;
  final VoidCallback onTap;
  final double height;
  final IconData? icon;
  final bool danger;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: text,
        child: Tap(
          onTap: onTap,
          child: Container(
            height: height,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: danger ? kTint : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kRed.withAlpha(danger ? 0 : 200), width: 1.4)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, color: kRed, size: 19), const SizedBox(width: 7)],
              Text(text, style: t(14.5, c: kRed)),
            ]),
          ),
        ),
      );
}

Widget ring(double s, Color c) => Container(width: s, height: s, decoration: BoxDecoration(shape: BoxShape.circle, color: c));

/// Translucent round button used on gradient headers.
Widget glass(Widget icon, VoidCallback onTap, {Color bg = const Color(0x2EFFFFFF)}) => Tap(
      onTap: onTap,
      child: Container(width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: icon),
    );

// ───────────────────────── Icons / tiles / pills ─────────────────────────
Widget tileIcon(IconData i, {double size = 44, Color color = kRed, Color bg = kTint}) => Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * .32)),
      child: Icon(i, color: color, size: size * .5),
    );

/// Gradient tile with a soft highlight (hero icons).
Widget gTile(IconData i, {double size = 56, Color color = kRed}) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(gradient: grad(color), borderRadius: BorderRadius.circular(size * .32), boxShadow: [BoxShadow(color: color.withAlpha(70), blurRadius: 14, offset: const Offset(0, 7))]),
      child: Stack(alignment: Alignment.center, children: [
        Positioned(top: -size * .22, right: -size * .22, child: ring(size * .7, const Color(0x24FFFFFF))),
        Icon(i, color: Colors.white, size: size * .5),
      ]),
    );

Widget pill(String text, Color bg, Color fg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: t(11.5, c: fg)),
    );
Widget pillOk(String s) => pill(s, kGreenBg, kGreenDk);
Widget pillWarn(String s) => pill(s, kAmberBg, kAmber);

Widget statusPill(String s) {
  switch (s) {
    case 'مؤكد':
    case 'مكتمل':
      return pillOk(s);
    case 'قيد التأكيد':
    case 'قيد التنفيذ':
      return pillWarn(s);
    case 'ملغي':
      return pill(s, kTint, kRed);
    default:
      return pill(s, kChip, kInk);
  }
}

BoxDecoration cardBox([double r = 22, Color color = Colors.white]) => BoxDecoration(color: color, borderRadius: BorderRadius.circular(r), boxShadow: kShadow, border: Border.all(color: const Color(0xFFF1F3F7)));

Widget sec(String s) => Padding(padding: const EdgeInsets.only(top: 20, bottom: 10), child: Text(s, style: t(15.5)));
Widget secRow(String s, {String? more, VoidCallback? onMore}) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Row(children: [
        Expanded(child: Text(s, style: t(15.5))),
        if (more != null) Tap(onTap: onMore, child: Text(more, style: t(12.5, c: kRed))),
      ]),
    );

Widget panel(List<Widget> ch) => Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: cardBox(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: ch),
    );
Widget group(List<Widget> ch) => Container(margin: const EdgeInsets.only(bottom: 4), decoration: cardBox(20), clipBehavior: Clip.antiAlias, child: Column(children: ch));

Widget kv(String k, String v, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(k, style: t(13, w: FontWeight.w500, c: kGrey)),
        const SizedBox(width: 12),
        Expanded(child: Text(v, textDirection: v.startsWith('+') ? TextDirection.ltr : null, textAlign: TextAlign.end, style: t(13.5, w: bold ? FontWeight.w800 : FontWeight.w700, c: bold ? kRed : kInk))),
      ]),
    );

Widget two(String a, String b) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(a, style: t(15)),
      const SizedBox(height: 1),
      Text(b, textDirection: b.startsWith('+') ? TextDirection.ltr : null, style: t(12, w: FontWeight.w500, c: kGrey)),
    ]);

Widget menuRow(IconData i, String s, {Widget? trailing, VoidCallback? onTap, Color color = kRed, Color text = kInk}) => InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          tileIcon(i, size: 38, color: color, bg: color == kRed ? kTint : color.withAlpha(30)),
          const SizedBox(width: 14),
          Expanded(child: Text(s, style: t(14, w: FontWeight.w600, c: text))),
          trailing ?? chev(kGrey, 20),
        ]),
      ),
    );

Widget cnt(String n) => Row(mainAxisSize: MainAxisSize.min, children: [pill(n, kChip, kInk), const SizedBox(width: 6), chev(kGrey, 20)]);

Widget stars(double v, {double size = 16}) => Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < 5; i++) Icon(i < v.round() ? Icons.star_rounded : Icons.star_outline_rounded, size: size, color: i < v.round() ? kGold : const Color(0xFFD6DBE6)),
    ]);


// ───────────────────────── Decorative hero pieces ─────────────────────────
class HeartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final heart = Path()
      ..moveTo(w * .5, h * .93)
      ..cubicTo(w * -.1, h * .52, w * .1, h * -.04, w * .5, h * .27)
      ..cubicTo(w * .9, h * -.04, w * 1.1, h * .52, w * .5, h * .93)
      ..close();
    canvas.drawPath(heart, Paint()..shader = kGradient.createShader(Offset.zero & s));
    final ecg = Path()
      ..moveTo(w * .1, h * .5)
      ..lineTo(w * .36, h * .5)
      ..lineTo(w * .43, h * .32)
      ..lineTo(w * .54, h * .68)
      ..lineTo(w * .61, h * .45)
      ..lineTo(w * .66, h * .5)
      ..lineTo(w * .9, h * .5);
    canvas.drawPath(
        ecg,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * .04
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

/// Concentric rings + a centre tile: the modern replacement for the old stock photo.
class Orb extends StatelessWidget {
  const Orb(this.child, {super.key, this.size = 240, this.onDark = false, this.white = false});
  final Widget child;
  final double size;
  final bool onDark, white;
  @override
  Widget build(BuildContext context) {
    final cols = onDark ? const [Color(0x14FFFFFF), Color(0x1FFFFFFF), Color(0x2EFFFFFF)] : const [Color(0x0DD9141E), Color(0x14D9141E), Color(0x1FD9141E)];
    final plain = white || onDark;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        ring(size, cols[0]),
        ring(size * .78, cols[1]),
        ring(size * .58, cols[2]),
        Container(
          width: size * .4,
          height: size * .4,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: plain ? null : kGradient,
            color: plain ? Colors.white : null,
            borderRadius: BorderRadius.circular(size * .12),
            boxShadow: plain ? const [BoxShadow(color: Color(0x26000000), blurRadius: 24, offset: Offset(0, 12))] : kGlow,
          ),
          child: child,
        ),
      ]),
    );
  }
}

Widget floatChip(IconData i, String s, Color c) => Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: kShadow),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 28, height: 28, decoration: BoxDecoration(color: c.withAlpha(30), shape: BoxShape.circle), child: Icon(i, color: c, size: 16)),
        const SizedBox(width: 8),
        Text(s, style: t(12.5)),
      ]),
    );

// ───────────────────────── Page scaffolds ─────────────────────────
/// Gradient header (back on the left, optional action on the right) + rounded sheet.
class RedPage extends StatelessWidget {
  const RedPage({super.key, required this.title, required this.body, this.nav, this.action, this.bottomBar, this.back = true});
  final String title;
  final Widget body;
  final Widget? nav, action, bottomBar;
  final bool back;
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kRed,
        body: Container(
          decoration: const BoxDecoration(gradient: kGradient),
          child: Stack(children: [
            Positioned(top: -70, left: -50, child: ring(200, const Color(0x14FFFFFF))),
            Positioned(top: 24, right: -60, child: ring(150, const Color(0x0FFFFFFF))),
            Column(children: [
              SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 64,
                  child: Row(children: [
                    SizedBox(width: 68, child: Center(child: action)),
                    Expanded(child: Text(title, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: t(19, c: Colors.white))),
                    SizedBox(
                      width: 68,
                      child: Center(
                        child: back ? glass(const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28, textDirection: TextDirection.ltr), () => Navigator.maybePop(context)) : null,
                      ),
                    ),
                  ]),
                ),
              ),
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(color: kBg, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                  child: Column(children: [Expanded(child: body), if (bottomBar != null) bottomBar!, if (nav != null) nav!]),
                ),
              ),
            ]),
          ]),
        ),
      );
}

/// White bar with the main call-to-action(s) pinned to the bottom of a page.
Widget btnBar(BuildContext c, String text, VoidCallback onTap, {String? alt, VoidCallback? onAlt, bool enabled = true, bool loading = false, IconData? icon, Widget? lead}) => Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(c).padding.bottom + 12),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24)), boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, -4))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (lead != null) ...[lead, const SizedBox(height: 10)],
        RedButton(text, onTap: onTap, enabled: enabled, loading: loading, icon: icon),
        if (alt != null) ...[const SizedBox(height: 10), OutBtn(alt, onTap: onAlt ?? () {})],
      ]),
    );


// ───────────────────────── Inputs ─────────────────────────
class AppSearch extends StatelessWidget {
  const AppSearch(this.hint, {super.key, this.controller, this.onChanged, this.onTap, this.readOnly = false, this.autofocus = false, this.fill = const Color(0xFFF1F3F8), this.trailing});
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly, autofocus;
  final Color fill;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Container(
        height: 52,
        decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          const SizedBox(width: 14),
          const Icon(Icons.search_rounded, color: kGrey, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              autofocus: autofocus,
              onTap: onTap,
              onChanged: onChanged,
              style: t(14, w: FontWeight.w500),
              decoration: InputDecoration(border: InputBorder.none, isCollapsed: true, hintText: hint, hintStyle: t(13.5, w: FontWeight.w500, c: kGrey), contentPadding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
          if (controller != null)
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller!,
              builder: (_, v, __) => v.text.isEmpty
                  ? const SizedBox(width: 6)
                  : Tap(
                      onTap: () {
                        controller!.clear();
                        onChanged?.call('');
                      },
                      child: const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.close_rounded, color: kGrey, size: 20)),
                    ),
            ),
          if (trailing != null) trailing!,
        ]),
      );
}

/// Horizontal scrolling filter chips (controlled by the parent).
class FilterChips extends StatelessWidget {
  const FilterChips(this.items, {super.key, required this.sel, required this.onChanged});
  final List<String> items;
  final int sel;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) => Tap(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: i == sel ? kGradient : null,
                color: i == sel ? null : Colors.white,
                borderRadius: BorderRadius.circular(21),
                border: i == sel ? null : Border.all(color: kLine),
                boxShadow: i == sel ? kGlow : null,
              ),
              child: Text(items[i], style: t(13.5, w: i == sel ? FontWeight.w700 : FontWeight.w600, c: i == sel ? Colors.white : kSub)),
            ),
          ),
        ),
      );
}

class AppField extends StatelessWidget {
  const AppField(this.label, {super.key, this.controller, this.hint, this.icon, this.type, this.lines = 1, this.ltr = false, this.error, this.readOnly = false, this.onTap, this.prefixText, this.onChanged, this.maxLength});
  final String label;
  final TextEditingController? controller;
  final String? hint, error, prefixText;
  final IconData? icon;
  final TextInputType? type;
  final int lines;
  final bool ltr, readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 14, bottom: 7), child: Text(label, style: t(12.5, c: kSub))),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: error != null ? kRed : kLine, width: error != null ? 1.5 : 1)),
          child: TextField(
            controller: controller,
            keyboardType: type,
            maxLines: lines,
            maxLength: maxLength,
            readOnly: readOnly,
            onTap: onTap,
            onChanged: onChanged,
            textDirection: ltr ? TextDirection.ltr : null,
            textAlign: ltr ? TextAlign.left : TextAlign.start,
            style: t(14, w: FontWeight.w600),
            decoration: InputDecoration(
              border: InputBorder.none,
              counterText: '',
              hintText: hint,
              hintStyle: t(13, w: FontWeight.w500, c: kGrey),
              prefixIcon: icon == null ? null : Icon(icon, color: kGrey, size: 20),
              prefixText: prefixText,
              prefixStyle: t(14, w: FontWeight.w700, c: kInk),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 5, right: 4), child: Text(error!, style: t(11.5, w: FontWeight.w600, c: kRed))),
      ]);
}

class ChipWrap extends StatefulWidget {
  const ChipWrap(this.items, {super.key, this.sel = const {0}, this.multi = false, this.onChanged});
  final List<String> items;
  final Set<int> sel;
  final bool multi;
  final ValueChanged<Set<int>>? onChanged;
  @override
  State<ChipWrap> createState() => _ChipWrapState();
}

class _ChipWrapState extends State<ChipWrap> {
  late Set<int> s = {...widget.sel};
  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: [
        for (var i = 0; i < widget.items.length; i++)
          Tap(
            onTap: () {
              setState(() {
                if (widget.multi) {
                  if (s.contains(i)) {
                    s.remove(i);
                  } else {
                    s.add(i);
                  }
                } else {
                  s = {i};
                }
              });
              widget.onChanged?.call({...s});
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: s.contains(i) ? kGradient : null,
                color: s.contains(i) ? null : Colors.white,
                border: s.contains(i) ? null : Border.all(color: kLine),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (widget.multi && s.contains(i)) ...[const Icon(Icons.check_rounded, color: Colors.white, size: 15), const SizedBox(width: 5)],
                Text(widget.items[i], style: t(13, w: FontWeight.w600, c: s.contains(i) ? Colors.white : kSub)),
              ]),
            ),
          ),
      ]);
}

class RadioPick extends StatefulWidget {
  const RadioPick(this.items, {super.key, this.sel = 0, this.onChanged});
  final List<(String, String)> items;
  final int sel;
  final ValueChanged<int>? onChanged;
  @override
  State<RadioPick> createState() => _RadioPickState();
}

class _RadioPickState extends State<RadioPick> {
  late int s = widget.sel;
  @override
  Widget build(BuildContext context) => Column(children: [
        for (var i = 0; i < widget.items.length; i++)
          Tap(
            scale: .985,
            onTap: () {
              setState(() => s = i);
              widget.onChanged?.call(i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: s == i ? const Color(0xFFFFF5F6) : Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: s == i ? kRed : kLine, width: 1.5)),
              child: Row(children: [
                Icon(s == i ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: s == i ? kRed : kGrey),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.items[i].$1, style: t(14)),
                    if (widget.items[i].$2.isNotEmpty) Text(widget.items[i].$2, style: t(11.5, w: FontWeight.w500, c: kGrey)),
                  ]),
                ),
              ]),
            ),
          ),
      ]);
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.icon, this.title, this.sub, {super.key, this.btn, this.onTap});
  final IconData icon;
  final String title, sub;
  final String? btn;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Orb(Icon(icon, color: Colors.white, size: 34), size: 160),
            gap(10),
            Text(title, textAlign: TextAlign.center, style: t(17)),
            gap(6),
            Text(sub, textAlign: TextAlign.center, style: t(13, w: FontWeight.w500, c: kGrey, h: 1.6)),
            if (btn != null) ...[gap(20), SizedBox(width: 230, child: RedButton(btn!, height: 48, onTap: onTap ?? () {}))],
          ]),
        ),
      );
}

// ───────────────────────── Auth header / phone ─────────────────────────
Widget authHeader({double height = 270}) => Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(gradient: kGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(56))),
      child: Stack(children: [
        Positioned(top: -60, left: -40, child: ring(200, const Color(0x14FFFFFF))),
        Positioned(bottom: -50, right: -30, child: ring(170, const Color(0x0FFFFFFF))),
        SafeArea(
          child: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 82,
                height: 82,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 12))]),
                child: SizedBox(width: 44, height: 40, child: CustomPaint(painter: HeartPainter())),
              ),
              gap(10),
              Text('طبيبك', style: t(32, c: Colors.white)),
              Text('صحتك .. أولويتنا', style: t(13, w: FontWeight.w500, c: const Color(0xE6FFFFFF))),
            ]),
          ),
        ),
      ]),
    );

/// يتحقق من رقم سوداني (9 أرقام بعد +249) ويعيده منظّفاً أو null.
String? cleanPhone(String raw) {
  final d = raw.replaceAll(RegExp(r'\D'), '');
  final n = d.startsWith('249') ? d.substring(3) : (d.startsWith('0') ? d.substring(1) : d);
  return RegExp(r'^[19]\d{8}$').hasMatch(n) ? n : null;
}


// ═════════════════════════════════════════════════════════════════════════
//  نقاط الربط (Config) — غيّر هذه القيم قبل النشر
// ═════════════════════════════════════════════════════════════════════════
/// true = حساب تجريبي معبّأ بأماكن عمل ومرضى الليلة. false = حساب جديد فارغ.
const kDemoData = true;

/// رقم الدعم الفني الظاهر في «المساعدة والدعم».
const kSupportPhone = '+249 912 000 000';

/// رابط تنزيل «طبيبك للمراكز». إن لم يكن فارغاً يُضاف إلى رسالة واتساب للمراكز.
const kCenterAppUrl = '';

// ───────────────────────── Time / text helpers ─────────────────────────
const kDays = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];

/// فهرس اليوم الحالي في kDays (السبت = 0 ... الجمعة = 6).
int get todayIdx => (DateTime.now().weekday + 1) % 7;

/// الدقائق منذ منتصف الليل → «5:30 م».
String fmtTime(int m) {
  final h24 = m ~/ 60, mn = m % 60;
  final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
  return '$h12:${mn.toString().padLeft(2, '0')} ${h24 >= 12 ? 'م' : 'ص'}';
}

String daysLabel(Set<int> d) {
  if (d.isEmpty) return 'لم تُحدَّد الأيام';
  if (d.length == 7) return 'كل الأيام';
  final s = d.toList()..sort();
  var run = true;
  for (var i = 1; i < s.length; i++) {
    if (s[i] != s[i - 1] + 1) run = false;
  }
  if (run && s.length >= 3) return '${kDays[s.first]} - ${kDays[s.last]}';
  return s.map((i) => kDays[i]).join('، ');
}

String ageLabel(int a) => a == 1 ? 'سنة' : (a == 2 ? 'سنتان' : (a <= 10 ? '$a سنوات' : '$a سنة'));

String agoLabel(int d) {
  if (d <= 0) return 'اليوم';
  if (d == 1) return 'أمس';
  if (d == 2) return 'قبل يومين';
  if (d < 7) return 'قبل $d أيام';
  if (d < 14) return 'قبل أسبوع';
  if (d < 21) return 'قبل أسبوعين';
  if (d < 30) return 'قبل ${d ~/ 7} أسابيع';
  if (d < 60) return 'قبل شهر';
  if (d < 90) return 'قبل شهرين';
  if (d < 365) {
    final m = d ~/ 30;
    return m > 10 ? 'قبل $m شهراً' : 'قبل $m أشهر';
  }
  return 'قبل أكثر من سنة';
}

/// «قبل 3 أسابيع · 11 أكتوبر»
String whenLabel(int d) {
  final x = DateTime.now().subtract(Duration(days: d));
  return '${agoLabel(d)} · ${x.day} ${kMonths[x.month - 1]}';
}

/// يحوّل أي صيغة لرقم دولي بلا + (السودان 249).
String waNumber(String raw) {
  final d = raw.replaceAll(RegExp(r'\D'), '');
  if (d.startsWith('249')) return d;
  if (d.startsWith('0')) return '249${d.substring(1)}';
  return d.length == 9 ? '249$d' : d;
}

String waLink(String phone, String msg) => 'https://wa.me/${waNumber(phone)}?text=${Uri.encodeComponent(msg)}';

/// نقطة الربط (1) — فتح واتساب.
/// هذه النسخة بلا حزم إضافية: تنسخ الرسالة ويلصقها الطبيب في محادثة المركز.
/// لفتح واتساب مباشرة: أضف الحزمة url_launcher ثم استبدل السطرين التاليين بـ
///   return launchUrl(Uri.parse(waLink(phone, msg)), mode: LaunchMode.externalApplication);
/// (وفي AndroidManifest أضف <queries> لـ https و whatsapp).
Future<bool> openWhatsApp(BuildContext c, String phone, String msg) async {
  await Clipboard.setData(ClipboardData(text: msg));
  if (c.mounted) snack(c, 'تم نسخ الرسالة — الصقها في محادثة المركز على واتساب', ok: true);
  return true;
}

/// نقطة الربط (2) — اختيار صورة شخصية.
/// بلا حزم: تُرجع null. لتفعيلها أضف image_picker ثم:
///   final x = await ImagePicker().pickImage(source: camera ? ImageSource.camera : ImageSource.gallery, maxWidth: 800, imageQuality: 80);
///   return x?.readAsBytes();
Future<Uint8List?> pickPhotoBytes(bool camera) async => null;

/// عجلة اختيار وقت (بدون حزم تعريب). تُرجع الدقائق منذ منتصف الليل.
Future<int?> pickTime(BuildContext c, int initial, String title) async {
  final h24 = initial ~/ 60;
  var h = h24 % 12 == 0 ? 12 : h24 % 12, m = (initial % 60) ~/ 5, pm = h24 >= 12 ? 1 : 0;
  final hc = FixedExtentScrollController(initialItem: h - 1);
  final mc = FixedExtentScrollController(initialItem: m);
  final pc = FixedExtentScrollController(initialItem: pm);
  Widget wheel(FixedExtentScrollController ctl, List<String> items, ValueChanged<int> on) => Expanded(
        child: CupertinoPicker(
          scrollController: ctl,
          itemExtent: 38,
          onSelectedItemChanged: on,
          children: [for (final s in items) Center(child: Text(s, style: t(18, w: FontWeight.w600)))],
        ),
      );
  return sheet<int>(
    c,
    Column(children: [
      Text(title, style: t(16)),
      gap(8),
      SizedBox(
        height: 190,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(children: [
            wheel(hc, [for (var i = 1; i <= 12; i++) '$i'], (v) => h = v + 1),
            wheel(mc, [for (var i = 0; i < 12; i++) (i * 5).toString().padLeft(2, '0')], (v) => m = v),
            wheel(pc, const ['ص', 'م'], (v) => pm = v),
          ]),
        ),
      ),
      gap(10),
      Builder(builder: (ctx) => RedButton('تأكيد', onTap: () => Navigator.pop(ctx, ((h % 12) + (pm == 1 ? 12 : 0)) * 60 + m * 5))),
    ]),
  );
}

// ───────────────────────── Static lists ─────────────────────────
const kSpecs = ['باطنية', 'أطفال', 'نساء وتوليد', 'جراحة عامة', 'قلب', 'عظام', 'جلدية', 'أنف وأذن وحنجرة', 'عيون', 'مسالك بولية', 'أعصاب', 'نفسية', 'طب أسرة', 'أسنان', 'أخرى'];

const kSubs = {
  'باطنية': ['غدد صماء وسكري', 'جهاز هضمي وكبد', 'كلى', 'صدرية', 'روماتيزم', 'أمراض الدم'],
  'أطفال': ['حديثي الولادة', 'قلب أطفال', 'أعصاب أطفال', 'صدر وحساسية أطفال'],
  'نساء وتوليد': ['حمل عالي الخطورة', 'عقم وحقن مجهري', 'مناظير نسائية'],
  'جراحة عامة': ['مناظير', 'جراحة أورام', 'أوعية دموية'],
  'قلب': ['قسطرة تداخلية', 'إيكو وتخطيط', 'كهرباء القلب'],
  'عظام': ['مفاصل', 'عمود فقري', 'إصابات رياضية', 'عظام أطفال'],
  'جلدية': ['تجميل وليزر', 'أمراض الشعر', 'حساسية جلدية'],
  'عيون': ['شبكية', 'مياه بيضاء', 'عيون أطفال'],
  'أعصاب': ['صرع', 'سكتات دماغية', 'اضطرابات الحركة'],
  'مسالك بولية': ['حصوات', 'عقم الرجال', 'بروستاتا'],
};

const kGrades = [
  ('مسجّل', 'Registrar', 'طبيب في مرحلة التخصص'),
  ('أخصائي', 'Specialist', 'أنهى برنامج التخصص'),
  ('استشاري', 'Consultant', 'أعلى درجة تخصصية'),
];

const kQualHints = ['MBBS', 'MD', 'البورد السوداني (SMSB)', 'MRCP', 'FRCS', 'ماجستير', 'دكتوراه', 'دبلوم'];

const kKinds = ['مركز طبي', 'مستشفى', 'عيادة خاصة'];
const kKindIcons = [Icons.local_hospital_rounded, Icons.apartment_rounded, Icons.storefront_rounded];
const kAreas = ['الخرطوم', 'بحري', 'أم درمان', 'شرق النيل', 'أخرى'];

// ───────────────────────── Models ─────────────────────────
/// مركز/مستشفى مسجّل في «طبيبك للمراكز» (يظهر في قائمة الاختيار).
class RegCenter {
  const RegCenter(this.name, this.kind, this.area, this.address, this.phone);
  final String name, area, address, phone;
  final int kind;
}

const kRegCenters = [
  RegCenter('مركز المسباح', 0, 'بحري', 'الخرطوم - بحري - المسبح', '+249 912 000 111'),
  RegCenter('مركز الشرق', 0, 'أم درمان', 'الخرطوم - أم درمان', '+249 912 000 222'),
  RegCenter('مركز النيل الطبي', 0, 'شرق النيل', 'الخرطوم - شرق النيل', '+249 912 000 333'),
  RegCenter('مستشفى السلام', 1, 'أم درمان', 'الخرطوم - أم درمان', '+249 912 000 401'),
  RegCenter('مستشفى النيل', 1, 'بحري', 'الخرطوم - بحري', '+249 912 000 402'),
  RegCenter('مستشفى المدينة', 1, 'شرق النيل', 'الخرطوم - شرق النيل', '+249 912 000 403'),
  RegCenter('مركز الأمل المنزلي', 0, 'الخرطوم', 'الخرطوم - وسط', '+249 912 000 501'),
  RegCenter('مركز الشفاء للرعاية', 0, 'بحري', 'الخرطوم - بحري', '+249 912 000 502'),
];

enum WpStatus { active, pending, offApp }

/// مكان عمل الطبيب.
/// active  = المركز مسجّل ومفعّل → الحجز المباشر متاح للمرضى.
/// pending = المركز مسجّل لكنه لم يؤكد إضافتك بعد.
/// offApp  = المركز غير مسجّل → يظهر للمرضى كمكان عمل فقط بلا حجز.
class Workplace {
  Workplace(this.name, this.kind, this.area, {this.address = '', this.phone = '', this.status = WpStatus.offApp, Set<int>? days, this.from = 1020, this.to = 1260, this.fee = 0, this.invitedAt, this.invites = 0}) : days = days ?? <int>{};
  String name, area, address, phone;
  int kind, from, to, fee, invites;
  WpStatus status;
  Set<int> days;
  DateTime? invitedAt;
  bool get onToday => days.contains(todayIdx);
  String get schedule => '${daysLabel(days)} · ${fmtTime(from)} - ${fmtTime(to)}';
}

/// فحص/نتيجة: flag 0 طبيعي · 1 مرتفع · 2 منخفض · 3 غير طبيعي — kind 0 مختبر · 1 أشعة · 2 تخطيط/أخرى
class Lab {
  const Lab(this.name, this.result, this.daysAgo, {this.flag = 0, this.kind = 0});
  final String name, result;
  final int daysAgo, flag, kind;
}

class LastVisit {
  const LastVisit(this.daysAgo, this.place, this.by, this.diagnosis, this.plan, {this.vitals = ''});
  final int daysAgo;
  final String place, by, diagnosis, plan, vitals;
}

class Patient {
  Patient(this.id, this.name, this.age, this.female, this.phone, this.time, this.place, this.reason,
      {this.arrived = false, this.status = 0, this.conditions = const [], this.allergies = const [], this.meds = const [], this.surgeries = const [], this.family = '', this.labs = const [], this.last});
  final int id, age, time; // time: دقائق منذ منتصف الليل
  final bool female;
  final String name, phone, place, reason, family;
  final List<String> conditions, allergies, meds, surgeries;
  final List<Lab> labs;
  final LastVisit? last;
  bool arrived;
  int status; // 0 بانتظار · 1 قيد الكشف · 2 تم الكشف · 3 لم يحضر
  String diagnosis = '', plan = '', followUp = '';
}

class Notif {
  Notif(this.icon, this.title, this.body, this.time, {this.unread = false, this.dest = 0, this.today = true});
  final IconData icon;
  final String title, body, time;
  bool unread, today;
  final int dest; // 0 لا شيء · 1 عيانين الليلة · 2 أماكن عملي · 3 حسابي
}

// ───────────────────────── State ─────────────────────────
class DocState extends ChangeNotifier {
  bool registered = false, verified = false, accepting = true, notifOn = true;
  String council = '', phone = '', name = '', specialty = '', sub = '', bio = '';
  int gender = -1, grade = -1, exp = -1; // exp = -1 → غير محدد
  List<String> quals = [];
  Uint8List? photo;
  final workplaces = <Workplace>[];
  final patients = <Patient>[];
  final notifs = <Notif>[];

  String get dn => name.trim().startsWith('د.') ? name.trim() : 'د. ${name.trim()}';
  String get first => name.replaceFirst('د.', '').trim().split(' ').first;
  String get gradeName => grade < 0 ? '' : kGrades[grade].$1;
  String get gradeFull => grade < 0 ? '' : '${kGrades[grade].$1} · ${kGrades[grade].$2}';
  String get specLine => [gradeName, specialty].where((s) => s.isNotEmpty).join(' ');
  int get unread => notifs.where((n) => n.unread).length;

  int get waiting => patients.where((p) => p.status == 0).length;
  int get inSessionCount => patients.where((p) => p.status == 1).length;
  int get doneCount => patients.where((p) => p.status == 2).length;
  int get missedCount => patients.where((p) => p.status == 3).length;

  Patient? get inSession {
    for (final p in patients) {
      if (p.status == 1) return p;
    }
    return null;
  }

  /// التالي: من وصل أولاً (حسب الموعد) ثم بقية المنتظرين.
  Patient? get next {
    final w = patients.where((p) => p.status == 0).toList()..sort((a, b) => a.time.compareTo(b.time));
    for (final p in w) {
      if (p.arrived) return p;
    }
    return w.isEmpty ? null : w.first;
  }

  List<Workplace> get today => (workplaces.where((w) => w.onToday).toList()..sort((a, b) => a.from.compareTo(b.from)));
  int get activeCount => workplaces.where((w) => w.status == WpStatus.active).length;

  /// عناصر اكتمال الملف: (العنوان، مكتمل؟، الوجهة 0 تعديل الملف · 1 أماكن العمل)
  List<(String, bool, int)> get checklist => [
        ('صورة شخصية', photo != null, 0),
        ('المؤهلات العلمية', quals.isNotEmpty, 0),
        ('سنوات الخبرة', exp >= 0, 0),
        ('نبذة تعريفية', bio.trim().length >= 20, 0),
        ('إضافة مكان عمل', workplaces.isNotEmpty, 1),
        ('مكان عمل مفعّل للحجز المباشر', activeCount > 0, 1),
      ];
  double get complete => checklist.where((e) => e.$2).length / checklist.length;

  void ping() => notifyListeners();

  void note(IconData i, String title, String body, {int dest = 0}) {
    notifs.insert(0, Notif(i, title, body, 'الآن', unread: true, dest: dest));
    notifyListeners();
  }

  void markAllRead() {
    for (final n in notifs) {
      n.unread = false;
    }
    notifyListeners();
  }

  void begin(String c, String ph) {
    council = c;
    phone = ph;
  }

  void finishSetup() {
    registered = true;
    verified = false;
    if (kDemoData) seedDemo();
    notifs.insert(0, Notif(Icons.waving_hand_rounded, 'أهلاً بك في طبيبك', 'ابدأ بإضافة أماكن عملك ليراك المرضى ويحجزوا معك.', 'الآن', unread: true, dest: 2));
    notifyListeners();
  }

  void reset() {
    registered = false;
    verified = false;
    accepting = true;
    notifOn = true;
    council = phone = name = specialty = sub = bio = '';
    gender = grade = exp = -1;
    quals = [];
    photo = null;
    workplaces.clear();
    patients.clear();
    notifs.clear();
    notifyListeners();
  }

  void seedDemo() {
    workplaces.addAll([
      Workplace('مركز المسباح', 0, 'بحري', address: 'الخرطوم - بحري - المسبح', phone: '+249 912 000 111', status: WpStatus.active, days: {0, 1, 2, 3, 4, 5}, from: 1020, to: 1200, fee: 10000),
      Workplace('مركز النيل الطبي', 0, 'شرق النيل', address: 'الخرطوم - شرق النيل', phone: '+249 912 000 333', status: WpStatus.active, days: {0, 1, 2, 3, 4, 5}, from: 1230, to: 1350, fee: 9000),
      Workplace('مستشفى السلام', 1, 'أم درمان', address: 'الخرطوم - أم درمان', phone: '+249 912 000 401', status: WpStatus.pending, days: {1, 3}, from: 540, to: 720, fee: 12000),
      Workplace('عيادة الأمل', 2, 'بحري', address: 'بحري - الدروشاب', phone: '+249 91 777 6655', status: WpStatus.offApp, days: {0, 2, 4}, from: 720, to: 900, fee: 8000),
    ]);
    patients.addAll([
      Patient(1, 'فاطمة أحمد', 41, true, '+249 99 888 7766', 1020, 'مركز المسباح', 'مراجعة نتيجة تحاليل الغدة الدرقية',
          status: 2,
          conditions: ['قصور الغدة الدرقية'],
          meds: ['ليفوثيروكسين 75 مكغ صباحاً'],
          labs: [Lab('TSH', '6.8 mIU/L', 12, flag: 1), Lab('T4 الحر', '0.9 ng/dL', 12)],
          last: const LastVisit(40, 'مركز المسباح', 'معك', 'قصور الغدة الدرقية', 'بدء ليفوثيروكسين 75 مكغ وإعادة التحليل بعد 6 أسابيع', vitals: 'ضغط 120/80 · نبض 74'))
        ..diagnosis = 'قصور الغدة الدرقية — استجابة جزئية'
        ..plan = 'رفع الجرعة إلى 100 مكغ صباحاً على معدة فارغة + إعادة TSH بعد 6 أسابيع'
        ..followUp = '6 أسابيع',
      Patient(2, 'خالد يوسف', 58, false, '+249 91 555 0101', 1050, 'مركز المسباح', 'متابعة السكري والضغط — صداع ودوخة منذ 3 أيام',
          arrived: true,
          conditions: ['السكري من النوع الثاني (منذ 12 سنة)', 'ارتفاع ضغط الدم', 'ارتفاع الكوليسترول'],
          allergies: ['البنسلين'],
          meds: ['ميتفورمين 1000 ملغ مرتين يومياً', 'أملوديبين 10 ملغ صباحاً', 'أتورفاستاتين 20 ملغ ليلاً'],
          surgeries: ['استئصال المرارة (2018)'],
          family: 'الأب: سكري وجلطة قلبية',
          labs: [
            Lab('سكر تراكمي HbA1c', '8.9%', 6, flag: 1),
            Lab('سكر صائم', '182 mg/dL', 6, flag: 1),
            Lab('كوليسترول LDL', '162 mg/dL', 6, flag: 1),
            Lab('كرياتينين', '1.1 mg/dL', 6),
            Lab('تخطيط القلب ECG', 'طبيعي', 90, kind: 2),
          ],
          last: const LastVisit(21, 'مركز المسباح', 'معك', 'سكري غير منضبط وارتفاع ضغط', 'زيادة جرعة الميتفورمين، حمية غذائية، مراجعة بعد 3 أسابيع مع التحاليل', vitals: 'ضغط 150/95 · نبض 82 · سكر عشوائي 240')),
      Patient(3, 'آمنة إبراهيم', 34, true, '+249 923 111 222', 1080, 'مركز المسباح', 'ألم أسفل البطن وغثيان منذ يومين',
          conditions: ['فقر دم (نقص حديد)'],
          meds: ['حديد 200 ملغ يومياً', 'فوليك أسيد'],
          surgeries: ['ولادة قيصرية (2021)'],
          labs: [
            Lab('هيموغلوبين', '9.8 g/dL', 14, flag: 2),
            Lab('فيريتين', '8 ng/mL', 14, flag: 2),
            Lab('تحليل بول', 'طبيعي', 14),
            Lab('موجات صوتية للحوض', 'طبيعية', 30, kind: 1),
          ],
          last: const LastVisit(14, 'مركز المسباح', 'معك', 'فقر دم بنقص الحديد', 'حديد عن طريق الفم + فوليك أسيد، وإعادة صورة الدم بعد شهر', vitals: 'ضغط 105/65 · نبض 96')),
      Patient(4, 'محمد عبد الرحيم', 45, false, '+249 912 345 678', 1110, 'مركز المسباح', 'سعال مستمر وضيق نفس خفيف',
          conditions: ['ربو شعبي', 'مدخّن (منذ 10 سنوات)'],
          allergies: ['الغبار', 'الأسبرين'],
          meds: ['بخاخ سالبيوتامول عند اللزوم', 'بخاخ بوديزونيد صباحاً ومساءً'],
          family: 'الأم: ربو',
          labs: [
            Lab('أشعة سينية للصدر', 'طبيعية', 95, kind: 1),
            Lab('وظائف الرئة FEV1', '72% من المتوقع', 95, flag: 2, kind: 2),
            Lab('صورة دم كاملة', 'طبيعية', 95),
          ],
          last: const LastVisit(95, 'مركز المسباح', 'د. سارة عبد الله', 'ربو شعبي مستقر', 'الاستمرار على البخاخات والإقلاع عن التدخين', vitals: 'ضغط 125/80 · تشبّع الأكسجين 96%')),
      Patient(5, 'ليلى محمود', 29, true, '+249 92 444 3322', 1140, 'مركز المسباح', 'صداع نصفي متكرر منذ شهرين',
          allergies: ['السلفا'],
          meds: ['باراسيتامول عند اللزوم'],
          labs: [Lab('فيتامين D', '14 ng/mL', 5, flag: 2), Lab('صورة دم كاملة', 'طبيعية', 5)]),
      Patient(6, 'سمير علي', 67, false, '+249 91 888 1010', 1230, 'مركز النيل الطبي', 'ألم في الصدر عند المجهود منذ أسبوع',
          conditions: ['مرض الشريان التاجي', 'ارتفاع ضغط الدم', 'السكري من النوع الثاني'],
          meds: ['أسبرين 75 ملغ', 'بيسوبرولول 5 ملغ', 'ميتفورمين 500 ملغ'],
          surgeries: ['قسطرة وتركيب دعامة (2020)'],
          family: 'الأخ: جلطة قلبية',
          labs: [
            Lab('تخطيط القلب ECG', 'تغيّرات ST-T غير نوعية', 8, flag: 3, kind: 2),
            Lab('تروبونين', 'سلبي', 8),
            Lab('كرياتينين', '1.4 mg/dL', 8, flag: 1),
            Lab('إيكو القلب', 'كسر القذف 50%', 60, flag: 3, kind: 2),
          ],
          last: const LastVisit(60, 'مركز النيل الطبي', 'د. عمر الطيب', 'ذبحة صدرية مستقرة', 'تعديل جرعة بيسوبرولول ومراجعة بعد شهرين', vitals: 'ضغط 140/85 · نبض 64')),
      Patient(7, 'نجلاء إبراهيم', 52, true, '+249 91 222 3344', 1260, 'مركز النيل الطبي', 'آلام المفاصل وتورّم الركبتين',
          conditions: ['هشاشة العظام', 'خشونة المفاصل'],
          allergies: ['الإيبوبروفين (تهيّج المعدة)'],
          meds: ['كالسيوم + فيتامين D'],
          family: 'الأم: هشاشة عظام',
          labs: [
            Lab('أشعة الركبتين', 'خشونة درجة 2', 42, flag: 3, kind: 1),
            Lab('سرعة الترسيب ESR', '38 mm/hr', 42, flag: 1),
            Lab('حمض اليوريك', '5.1 mg/dL', 42),
            Lab('كثافة العظام DEXA', 'T-score -2.7', 120, flag: 2, kind: 2),
          ],
          last: const LastVisit(42, 'مركز النيل الطبي', 'معك', 'خشونة مفاصل وهشاشة عظام', 'مسكّن موضعي + علاج طبيعي، وتجنّب مضادات الالتهاب الفموية', vitals: 'ضغط 130/80 · وزن 82 كغ')),
      Patient(8, 'عمر حسن', 8, false, '+249 90 321 4455', 1290, 'مركز النيل الطبي', 'حرارة وسعال منذ يومين (المرافق: الأب)',
          conditions: ['حساسية صدر موسمية'],
          surgeries: ['استئصال اللوزتين (2023)'],
          family: 'الأب: ربو',
          last: const LastVisit(150, 'مركز النيل الطبي', 'د. حسن محمود (أطفال)', 'التهاب شعب هوائية', 'بخاخ موسّع للشعب وسوائل، وتحسّن خلال 5 أيام', vitals: 'وزن 26 كغ · حرارة 37.2')),
    ]);
    notifs.addAll([
      Notif(Icons.how_to_reg_rounded, 'وصل المريض خالد يوسف', 'بانتظارك في مركز المسباح — موعده 5:30 م.', 'منذ 3 دقائق', unread: true, dest: 1),
      Notif(Icons.check_circle_rounded, 'مركز المسباح فعّل حجزك المباشر', 'يستطيع المرضى الآن حجز موعدك مباشرة من التطبيق.', 'منذ ساعة', unread: true, dest: 2),
      Notif(Icons.chat_rounded, 'عيادة الأمل لم تفعّل حسابها بعد', 'أرسل لهم دعوة عبر واتساب ليتمكّن المرضى من الحجز معك.', 'أمس 6:20 م', dest: 2, today: false),
      Notif(Icons.verified_user_rounded, 'حسابك قيد التوثيق', 'نراجع رقم المجلس الطبي وسنُعلمك فور اكتمال التوثيق.', 'أمس 9:00 ص', dest: 3, today: false),
    ]);
  }
}

final me = DocState();

// ═════════════════════════════════════════════════════════════════════════
//  App shell
// ═════════════════════════════════════════════════════════════════════════
void main() => runApp(const DoctorApp());

class DoctorApp extends StatelessWidget {
  const DoctorApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'طبيبك للأطباء',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: kRed,
          scaffoldBackgroundColor: Colors.white,
          textTheme: appTextTheme(),
          textSelectionTheme: const TextSelectionThemeData(cursorColor: kRed, selectionHandleColor: kRed),
        ),
        builder: (c, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
        home: const SplashScreen(),
      );
}

/// صورة الطبيب (أو الحرف الأول من اسمه إذا لم يضف صورة).
class DocAvatar extends StatelessWidget {
  const DocAvatar({super.key, this.size = 66, this.light = false});
  final double size;
  final bool light;
  @override
  Widget build(BuildContext context) => me.photo != null
      ? ClipOval(child: Image.memory(me.photo!, width: size, height: size, fit: BoxFit.cover))
      : Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(gradient: light ? null : kGradient, color: light ? Colors.white : null, shape: BoxShape.circle, boxShadow: light ? null : kGlow),
          child: Text(initial(me.name), style: t(size * .42, c: light ? kRed : Colors.white)),
        );
}

class DocNav extends StatelessWidget {
  const DocNav({super.key, this.active = 0});
  final int active;
  static const items = [
    (Icons.home_rounded, Icons.home_outlined, 'الرئيسية'),
    (Icons.apartment_rounded, Icons.apartment_outlined, 'أماكن عملي'),
    (Icons.notifications_rounded, Icons.notifications_none_rounded, 'إشعارات'),
    (Icons.person_rounded, Icons.person_outline_rounded, 'حسابي'),
  ];

  void open(BuildContext c, int i) {
    if (i == 0) {
      Navigator.popUntil(c, (r) => r.isFirst);
      return;
    }
    if (i == active) return;
    final Widget page = i == 1 ? const WorkplacesScreen() : (i == 2 ? const NotificationsScreen() : const AccountScreen());
    Navigator.pushAndRemoveUntil(c, MaterialPageRoute(builder: (_) => page), (r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: me,
        builder: (c, _) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28)), boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, -5))]),
          child: SafeArea(
            top: false,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                child: Row(children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: Tap(
                        onTap: () => open(c, i),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                            decoration: BoxDecoration(color: i == active ? kTint : Colors.transparent, borderRadius: BorderRadius.circular(16)),
                            child: Stack(clipBehavior: Clip.none, children: [
                              Icon(i == active ? items[i].$1 : items[i].$2, size: 24, color: i == active ? kRed : kGrey),
                              if (i == 2 && me.unread > 0)
                                Positioned(
                                  top: -3,
                                  right: -5,
                                  child: Container(
                                    width: 15,
                                    height: 15,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(color: kRed, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                                    child: Text('${me.unread}', style: t(8.5, c: Colors.white)),
                                  ),
                                ),
                            ]),
                          ),
                          const SizedBox(height: 2),
                          Text(items[i].$3, style: t(10.5, w: i == active ? FontWeight.w700 : FontWeight.w500, c: i == active ? kRed : kGrey)),
                        ]),
                      ),
                    ),
                ]),
              ),
            ),
          ),
        ),
      );
}

/// ينتقل إلى تبويب: 0 الرئيسية · 1 أماكن عملي · 2 إشعارات · 3 حسابي.
void tab(BuildContext c, int i) => const DocNav().open(c, i);

/// صف خطأ صغير تحت مجموعات الاختيار.
Widget errText(String? e) => e == null ? const SizedBox.shrink() : Padding(padding: const EdgeInsets.only(top: 6, right: 4), child: Text(e, style: t(11.5, w: FontWeight.w600, c: kRed)));

/// مربع الموافقة (نفس شكل تطبيق المرضى).
Widget checkRow(bool on, String text, VoidCallback toggle, {bool err = false, VoidCallback? onMore}) => Tap(
      onTap: toggle,
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: on ? kRed : Colors.white, borderRadius: BorderRadius.circular(8), border: on ? null : Border.all(color: err ? kRed : const Color(0xFFD5DAE2), width: 1.6)),
          child: on ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: t(12.5, w: FontWeight.w600, c: kSub))),
        if (onMore != null) Tap(onTap: onMore, child: Text('عرض', style: t(12.5, c: kRed))),
      ]),
    );

// ═════════════════════════════════════════════════════════════════════════
//  1. Splash
// ═════════════════════════════════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashState();
}

class _SplashState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController ctl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

  @override
  void dispose() {
    ctl.dispose();
    super.dispose();
  }

  Widget bob(Widget w, double k) => AnimatedBuilder(
        animation: ctl,
        builder: (_, child) => Transform.translate(offset: Offset(0, (ctl.value - .5) * 14 * k), child: child),
        child: w,
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(children: [
          Positioned.fill(
            child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFFFF1F2)]))),
          ),
          Positioned(top: -100, right: -80, child: ring(300, const Color(0x14D9141E))),
          Positioned(top: 140, left: -130, child: ring(250, const Color(0x0F3B6EF5))),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(children: [
                const Spacer(),
                SizedBox(
                  width: 330,
                  height: 300,
                  child: Stack(alignment: Alignment.center, children: [
                    Orb(SizedBox(width: 56, height: 52, child: CustomPaint(painter: HeartPainter())), size: 270, white: true),
                    Positioned(top: 14, right: 0, child: bob(floatChip(Icons.nights_stay_rounded, 'عيانين الليلة', kRed), 1)),
                    Positioned(top: 112, left: 0, child: bob(floatChip(Icons.event_available_rounded, 'حجز مباشر', kOrange), -1)),
                    Positioned(bottom: 52, right: 4, child: bob(floatChip(Icons.apartment_rounded, 'أماكن عملي', kTeal), -1.2)),
                    Positioned(bottom: 6, left: 24, child: bob(floatChip(Icons.badge_rounded, 'ملفك المهني', kBlue), 1.2)),
                  ]),
                ),
                gap(6),
                ShaderMask(
                  shaderCallback: (r) => kGradient.createShader(r),
                  child: Text('طبيبك', style: t(62, c: Colors.white, h: 1.25)),
                ),
                Text('للأطباء', style: t(18, w: FontWeight.w600, c: kSub)),
                gap(10),
                Text('أدِر أماكن عملك، وتابع مرضاك، ودع المرضى يحجزون معك مباشرة.', textAlign: TextAlign.center, style: t(13.5, w: FontWeight.w500, c: kGrey, h: 1.7)),
                const Spacer(),
                RedButton('ابدأ الآن', arrow: true, height: 58, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()))),
                gap(8),
              ]),
            ),
          ),
        ]),
      );
}

// ═════════════════════════════════════════════════════════════════════════
//  2. تسجيل الدخول / إنشاء حساب — رقم المجلس + رقم الهاتف
// ═════════════════════════════════════════════════════════════════════════
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthState();
}

class _AuthState extends State<AuthScreen> {
  final cn = TextEditingController(), ph = TextEditingController();
  bool agree = false;
  String? eCouncil, ePhone, eAgree;

  @override
  void dispose() {
    cn.dispose();
    ph.dispose();
    super.dispose();
  }

  void send() {
    final c = cn.text.replaceAll(RegExp(r'\s'), '');
    final p = cleanPhone(ph.text);
    String? ep = p == null ? 'أدخل رقم هاتف صحيح مكوّن من 9 أرقام' : null;
    if (p != null && me.registered && me.council == c && me.phone != '+249 $p') {
      ep = 'رقم المجلس هذا مسجّل برقم هاتف آخر. تواصل مع الدعم لتغيير الرقم.';
    }
    setState(() {
      eCouncil = RegExp(r'^\d{3,8}$').hasMatch(c) ? null : 'أدخل رقم المجلس الطبي (أرقام فقط)';
      ePhone = ep;
      eAgree = agree ? null : 'يجب الموافقة على الشروط للمتابعة';
    });
    if (eCouncil != null || ePhone != null || eAgree != null) return;
    go(context, OtpScreen('+249 $p', c));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: Column(children: [
          authHeader(height: 250),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(24, 22, 24, 16), children: [
              Center(child: Text('دخول الأطباء', style: t(22))),
              gap(4),
              Center(child: Text('سجّل برقم المجلس الطبي ورقم هاتفك — حساب جديد أو دخول', textAlign: TextAlign.center, style: t(13, w: FontWeight.w500, c: kGrey, h: 1.6))),
              AppField('رقم المجلس الطبي', controller: cn, hint: 'مثال: 12345', icon: Icons.badge_outlined, type: TextInputType.number, ltr: true, maxLength: 8, error: eCouncil, onChanged: (_) {
                if (eCouncil != null) setState(() => eCouncil = null);
              }),
              AppField('رقم الهاتف', controller: ph, hint: '9XX XXX XXX', icon: Icons.phone_outlined, type: TextInputType.phone, ltr: true, prefixText: '+249  ', error: ePhone, onChanged: (_) {
                if (ePhone != null) setState(() => ePhone = null);
              }),
              gap(8),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.info_outline_rounded, color: kGrey, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text('نراجع رقم المجلس الطبي لتوثيق حسابك. يمكنك استخدام التطبيق أثناء المراجعة.', style: t(11.5, w: FontWeight.w500, c: kGrey, h: 1.6))),
              ]),
              gap(16),
              checkRow(agree, 'أوافق على الشروط وسياسة الخصوصية وسرّية بيانات المرضى', () => setState(() {
                    agree = !agree;
                    eAgree = null;
                  }), err: eAgree != null, onMore: () => go(context, const TermsScreen())),
              errText(eAgree),
              gap(20),
              RedButton('إرسال رمز التحقق', arrow: true, onTap: send),
            ]),
          ),
        ]),
      );
}

class OtpScreen extends StatefulWidget {
  const OtpScreen(this.phone, this.council, {super.key});
  final String phone, council;
  @override
  State<OtpScreen> createState() => _OtpState();
}

class _OtpState extends State<OtpScreen> {
  final cs = List.generate(4, (_) => TextEditingController());
  final fs = List.generate(4, (_) => FocusNode());
  int left = 45;
  Timer? timer;
  String? err;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (left > 0 && mounted) setState(() => left--);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    for (final c in cs) {
      c.dispose();
    }
    for (final f in fs) {
      f.dispose();
    }
    super.dispose();
  }

  void verify() {
    if (busy) return;
    if (cs.any((c) => c.text.isEmpty)) {
      setState(() => err = 'أدخل الرمز المكوّن من 4 أرقام');
      return;
    }
    busy = true;
    if (me.registered && me.council == widget.council) {
      me.phone = widget.phone;
      snack(context, 'تم التحقق بنجاح، أهلاً ${me.dn}', ok: true);
      home(context);
    } else {
      me.reset();
      me.begin(widget.council, widget.phone);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfileFormScreen(setup: true)));
    }
  }

  void resend() {
    if (left > 0) return;
    setState(() {
      left = 45;
      err = null;
    });
    for (final c in cs) {
      c.clear();
    }
    fs[0].requestFocus();
    snack(context, 'تم إرسال رمز جديد', ok: true);
  }

  @override
  Widget build(BuildContext context) => RedPage(
        title: 'رمز التحقق',
        bottomBar: btnBar(context, 'تأكيد', verify),
        body: ListView(padding: const EdgeInsets.all(24), children: [
          gap(6),
          Center(child: gTile(Icons.verified_user_rounded, size: 78)),
          gap(16),
          Center(child: Text('أدخل رمز التحقق', style: t(20))),
          gap(6),
          Center(child: Text('أرسلنا رمزاً من 4 أرقام إلى', style: t(13, w: FontWeight.w500, c: kGrey))),
          Center(child: Directionality(textDirection: TextDirection.ltr, child: Text(widget.phone, style: t(15, c: kInk)))),
          gap(24),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < 4; i++)
                Container(
                  width: 60,
                  height: 66,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: err != null ? kRed : kLine, width: 1.5), boxShadow: kShadow),
                  child: TextField(
                    controller: cs[i],
                    focusNode: fs[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: t(24),
                    decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
                    onChanged: (v) {
                      if (err != null) setState(() => err = null);
                      if (v.isNotEmpty && i < 3) fs[i + 1].requestFocus();
                      if (v.isEmpty && i > 0) fs[i - 1].requestFocus();
                      if (v.isNotEmpty && i == 3) verify();
                    },
                  ),
                ),
            ]),
          ),
          if (err != null) Padding(padding: const EdgeInsets.only(top: 10), child: Center(child: Text(err!, style: t(12, c: kRed)))),
          gap(20),
          Center(
            child: left > 0
                ? Text.rich(TextSpan(text: 'إعادة إرسال الرمز بعد ', style: t(12.5, w: FontWeight.w500, c: kGrey), children: [TextSpan(text: '00:${left.toString().padLeft(2, '0')}', style: t(12.5, c: kRed))]))
                : Tap(onTap: resend, child: Padding(padding: const EdgeInsets.all(8), child: Text('إعادة إرسال الرمز', style: t(13.5, c: kRed)))),
          ),
          gap(6),
          Center(child: Text('نسخة تجريبية: أي 4 أرقام تفتح الحساب', style: t(11, w: FontWeight.w500, c: kGrey))),
        ]),
      );
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});
  static const items = [
    ('سرّية بيانات المرضى', 'تطّلع على بيانات المرضى لغرض العلاج فقط، ولا تنسخها أو تشاركها خارج نطاق الرعاية الصحية.'),
    ('صحة الملف المهني', 'تُقرّ بأن رقم المجلس الطبي والمؤهلات والدرجة المهنية التي أدخلتها صحيحة، وقد يُعلَّق الحساب عند ثبوت خلاف ذلك.'),
    ('أماكن العمل والمواعيد', 'أنت مسؤول عن تحديث أيام وساعات دوامك وأسعار الكشف. يظهر الحجز المباشر للمرضى فقط في المراكز المفعّلة على طبيبك.'),
    ('الخصوصية', 'نحتفظ ببياناتك لتقديم الخدمة ولا نشاركها مع أطراف خارجية دون موافقتك.'),
  ];
  @override
  Widget build(BuildContext context) => RedPage(
        title: 'الشروط والخصوصية',
        body: ListView(padding: const EdgeInsets.all(16), children: [
          for (final e in items) panel([Text(e.$1, style: t(14.5)), gap(6), Text(e.$2, style: t(12.5, w: FontWeight.w500, c: kSub, h: 1.7))]),
          gap(4),
          Center(child: Text('نص تمهيدي — يُستبدل بالنص القانوني المعتمد قبل النشر.', textAlign: TextAlign.center, style: t(11, w: FontWeight.w500, c: kGrey))),
        ]),
      );
}

// ═════════════════════════════════════════════════════════════════════════
//  3. الملف المهني (إعداد أول مرة + تعديل)
// ═════════════════════════════════════════════════════════════════════════
class ProfileFormScreen extends StatefulWidget {
  const ProfileFormScreen({super.key, this.setup = false});
  final bool setup;
  @override
  State<ProfileFormScreen> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileFormScreen> {
  late final nm = TextEditingController(text: me.name);
  late final sub = TextEditingController(text: me.sub);
  late final other = TextEditingController();
  late final qc = TextEditingController();
  late final ex = TextEditingController(text: me.exp >= 0 ? '${me.exp}' : '');
  late final bio = TextEditingController(text: me.bio);
  late int gender = me.gender, grade = me.grade;
  late List<String> quals = [...me.quals];
  late Uint8List? photo = me.photo;
  int specIdx = -1;
  String? eName, eGender, eSpec, eGrade, eExp;

  @override
  void initState() {
    super.initState();
    if (me.specialty.isNotEmpty) {
      final i = kSpecs.indexOf(me.specialty);
      if (i >= 0 && i < kSpecs.length - 1) {
        specIdx = i;
      } else {
        specIdx = kSpecs.length - 1;
        other.text = me.specialty;
      }
    }
  }

  @override
  void dispose() {
    for (final c in [nm, sub, other, qc, ex, bio]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get otherSpec => specIdx == kSpecs.length - 1;
  String get specName => specIdx < 0 ? '' : (otherSpec ? other.text.trim() : kSpecs[specIdx]);

  Future<void> photoSheet() async {
    final r = await sheet<int>(
      context,
      Builder(
        builder: (ctx) => Column(children: [
          Text('الصورة الشخصية', style: t(16)),
          gap(4),
          Text('اختيارية — تظهر للمرضى بجانب اسمك.', style: t(12, w: FontWeight.w500, c: kGrey)),
          gap(14),
          group([
            menuRow(Icons.photo_camera_rounded, 'التقاط صورة', onTap: () => Navigator.pop(ctx, 1)),
            menuRow(Icons.photo_library_rounded, 'اختيار من المعرض', onTap: () => Navigator.pop(ctx, 2)),
            if (photo != null) menuRow(Icons.delete_outline_rounded, 'إزالة الصورة', onTap: () => Navigator.pop(ctx, 0)),
          ]),
        ]),
      ),
    );
    if (r == null || !mounted) return;
    if (r == 0) {
      setState(() => photo = null);
      return;
    }
    final b = await pickPhotoBytes(r == 1);
    if (!mounted) return;
    if (b == null) {
      snack(context, 'اختيار الصور غير مفعّل في هذه النسخة التجريبية');
      return;
    }
    setState(() => photo = b);
  }

  void addQual() {
    final v = qc.text.trim();
    if (v.isEmpty) return;
    if (quals.contains(v)) {
      snack(context, 'المؤهل مضاف مسبقاً');
      return;
    }
    setState(() {
      quals.add(v);
      qc.clear();
    });
  }

  void hintQual(String s) {
    final txt = '$s - ';
    qc.value = TextEditingValue(text: txt, selection: TextSelection.collapsed(offset: txt.length));
  }

  void save() {
    final n = nm.text.trim();
    final exTxt = ex.text.trim();
    final expV = exTxt.isEmpty ? -1 : (int.tryParse(exTxt) ?? -2);
    final pending = qc.text.trim();
    if (pending.isNotEmpty && !quals.contains(pending)) quals.add(pending);
    setState(() {
      eName = n.length < 3 ? 'أدخل اسمك الكامل' : null;
      eGender = gender < 0 ? 'اختر الجنس' : null;
      eSpec = specName.isEmpty ? 'اختر التخصص' : null;
      eGrade = grade < 0 ? 'اختر درجتك المهنية' : null;
      eExp = (expV == -2 || expV > 60) ? 'أدخل عدد سنوات صحيح' : null;
    });
    if (eName != null || eGender != null || eSpec != null || eGrade != null || eExp != null) {
      snack(context, 'أكمل الحقول المطلوبة');
      return;
    }
    me
      ..name = n
      ..gender = gender
      ..specialty = specName
      ..sub = sub.text.trim()
      ..grade = grade
      ..quals = [...quals]
      ..exp = expV
      ..bio = bio.text.trim()
      ..photo = photo;
    if (widget.setup) {
      me.finishSetup();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
    } else {
      me.ping();
      snack(context, 'تم حفظ التغييرات', ok: true);
      Navigator.pop(context);
    }
  }

  Widget small(String s, VoidCallback on) => Tap(
        onTap: on,
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: kChip, borderRadius: BorderRadius.circular(14)), child: Text(s, style: t(11.5, w: FontWeight.w600, c: kSub))),
      );

  Widget qualChip(int i) => Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(child: Text(quals[i], style: t(12.5, w: FontWeight.w600))),
          const SizedBox(width: 6),
          Tap(onTap: () => setState(() => quals.removeAt(i)), child: const Icon(Icons.close_rounded, size: 17, color: kGrey)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final subs = kSubs[specName] ?? const <String>[];
    return RedPage(
      title: widget.setup ? 'أكمل ملفك المهني' : 'تعديل الملف المهني',
      back: !widget.setup,
      bottomBar: btnBar(context, widget.setup ? 'حفظ ومتابعة' : 'حفظ التغييرات', save),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
        gap(8),
        Center(
          child: Tap(
            onTap: photoSheet,
            child: Stack(clipBehavior: Clip.none, children: [
              photo != null
                  ? ClipOval(child: Image.memory(photo!, width: 96, height: 96, fit: BoxFit.cover))
                  : Container(width: 96, height: 96, alignment: Alignment.center, decoration: const BoxDecoration(color: kChip, shape: BoxShape.circle), child: const Icon(Icons.person_rounded, size: 52, color: kGrey)),
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: kGradient, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16)),
              ),
            ]),
          ),
        ),
        gap(8),
        Center(child: Text('صورة شخصية (اختيارية)', style: t(12.5, c: kSub))),
        gap(14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: kChip, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            const Icon(Icons.lock_outline_rounded, color: kGrey, size: 18),
            gapW(8),
            Expanded(child: Text('رقم المجلس: ${me.council}   ·   الهاتف: ${me.phone}', style: t(12, w: FontWeight.w600, c: kSub))),
          ]),
        ),
        AppField('الاسم الكامل', controller: nm, hint: 'مثال: أحمد محمد علي', icon: Icons.person_outline_rounded, error: eName, onChanged: (_) {
          if (eName != null) setState(() => eName = null);
        }),
        sec('الجنس'),
        ChipWrap(const ['ذكر', 'أنثى'], sel: gender < 0 ? const <int>{} : {gender}, onChanged: (s) => setState(() {
              gender = s.first;
              eGender = null;
            })),
        errText(eGender),
        sec('التخصص'),
        ChipWrap(kSpecs, sel: specIdx < 0 ? const <int>{} : {specIdx}, onChanged: (s) => setState(() {
              specIdx = s.first;
              eSpec = null;
            })),
        if (otherSpec) AppField('اسم التخصص', controller: other, hint: 'اكتب تخصصك', onChanged: (_) => setState(() => eSpec = null)),
        errText(eSpec),
        AppField('التخصص الفرعي (اختياري)', controller: sub, hint: 'مثال: غدد صماء وسكري', icon: Icons.account_tree_outlined),
        if (subs.isNotEmpty) ...[
          gap(8),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final s in subs) small(s, () => setState(() => sub.text = s))]),
        ],
        sec('الدرجة المهنية'),
        RadioPick([for (final g in kGrades) ('${g.$1} · ${g.$2}', g.$3)], sel: grade, onChanged: (i) => setState(() {
              grade = i;
              eGrade = null;
            })),
        errText(eGrade),
        sec('المؤهلات العلمية'),
        if (quals.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 4), child: Wrap(spacing: 8, runSpacing: 8, children: [for (var i = 0; i < quals.length; i++) qualChip(i)])),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: AppField('أضف مؤهلاً', controller: qc, hint: 'مثال: ماجستير باطنية - جامعة الخرطوم', icon: Icons.school_outlined)),
          gapW(10),
          Tap(onTap: addQual, child: Container(width: 50, height: 50, alignment: Alignment.center, decoration: BoxDecoration(gradient: kGradient, borderRadius: BorderRadius.circular(16), boxShadow: kGlow), child: const Icon(Icons.add_rounded, color: Colors.white, size: 26))),
        ]),
        gap(10),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final h in kQualHints) small(h, () => hintQual(h))]),
        AppField('سنوات الخبرة (اختياري)', controller: ex, hint: 'مثال: 8', icon: Icons.work_outline_rounded, type: TextInputType.number, maxLength: 2, error: eExp, onChanged: (_) {
          if (eExp != null) setState(() => eExp = null);
        }),
        AppField('نبذة تعريفية (اختيارية)', controller: bio, hint: 'اكتب نبذة قصيرة عن خبرتك واهتماماتك العلاجية...', lines: 4, maxLength: 300, onChanged: (_) => setState(() {})),
        Padding(padding: const EdgeInsets.only(top: 4, right: 4), child: Text('${bio.text.length}/300', style: t(11, w: FontWeight.w500, c: kGrey))),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  4. رسالة الترحيب
// ═════════════════════════════════════════════════════════════════════════
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Widget step(int n, IconData i, String title, String sub) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Container(width: 30, height: 30, alignment: Alignment.center, decoration: const BoxDecoration(gradient: kGradient, shape: BoxShape.circle), child: Text('$n', style: t(13.5, c: Colors.white))),
          gapW(12),
          Expanded(child: two(title, sub)),
          Icon(i, color: kRed, size: 22),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    const bits = [
      (-74.0, -70.0, Color(0xFF2EAD5C), .8),
      (74.0, -64.0, Color(0xFFF5A623), -.7),
      (92.0, -4.0, Color(0xFFE8559A), -.2),
      (-92.0, -12.0, Color(0xFFF5A623), .1),
      (-74.0, 50.0, Color(0xFFE8559A), -.6),
      (76.0, 56.0, Color(0xFF2EAD5C), .8),
    ];
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(children: [
            Expanded(
              child: ListView(children: [
                const SizedBox(height: 28),
                Center(
                  child: SizedBox(
                    width: 230,
                    height: 150,
                    child: Stack(alignment: Alignment.center, children: [
                      for (final b in bits) Transform.translate(offset: Offset(b.$1, b.$2), child: Transform.rotate(angle: b.$4, child: Container(width: 12, height: 6, decoration: BoxDecoration(color: b.$3, borderRadius: BorderRadius.circular(1.5))))),
                      DocAvatar(size: 104, light: me.photo == null),
                    ]),
                  ),
                ),
                gap(6),
                Text('أهلاً بك في طبيبك', textAlign: TextAlign.center, style: t(22)),
                gap(2),
                Text(me.dn, textAlign: TextAlign.center, style: t(17, c: kRed)),
                gap(10),
                Text(
                  'يسعدنا انضمامك إلينا. ملفك المهني جاهز الآن، وسنراجع رقم المجلس الطبي خلال 24 ساعة لتوثيق حسابك. ابدأ بإضافة أماكن عملك ليراك المرضى ويحجزوا معك.',
                  textAlign: TextAlign.center,
                  style: t(13, w: FontWeight.w500, c: const Color(0xFF6B7794), h: 1.8),
                ),
                gap(20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: cardBox(22),
                  child: Column(children: [
                    step(1, Icons.apartment_rounded, 'أضف أماكن عملك', 'مركز، مستشفى، أو عيادة خاصة'),
                    step(2, Icons.event_available_rounded, 'فعّل الحجز المباشر', 'ندعو المراكز غير المسجّلة عبر واتساب'),
                    step(3, Icons.nights_stay_rounded, 'تابع عيانين الليلة', 'ملفات المرضى وفحوصاتهم قبل الكشف'),
                  ]),
                ),
              ]),
            ),
            RedButton('ابدأ الاستخدام', height: 52, arrow: true, onTap: () => home(context)),
            gap(10),
            OutBtn('أضف مكان عمل', icon: Icons.add_location_alt_rounded, onTap: () {
              final nav = Navigator.of(context);
              nav.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false);
              nav.push(MaterialPageRoute(builder: (_) => const AddWorkplaceScreen()));
            }),
          ]),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  5. الرئيسية
// ═════════════════════════════════════════════════════════════════════════
const kLabIcons = [Icons.science_rounded, Icons.photo_camera_back_rounded, Icons.monitor_heart_rounded];

Widget patientPill(int s) => switch (s) {
      1 => pill('قيد الكشف', kBlueBg, kBlue),
      2 => pillOk('تم الكشف'),
      3 => pill('لم يحضر', kChip, kGrey),
      _ => pillWarn('بانتظار'),
    };

/// حالة مكان العمل: (النص، لون الخلفية، لون الخط).
(String, Color, Color) wpBadge(WpStatus s) => switch (s) {
      WpStatus.active => ('الحجز المباشر مفعّل', kGreenBg, kGreenDk),
      WpStatus.pending => ('بانتظار تأكيد المركز', kAmberBg, kAmber),
      WpStatus.offApp => ('المركز غير مفعّل', kTint, kRed),
    };

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String greet() => DateTime.now().hour < 12 ? 'صباح الخير' : 'مساء الخير';

  Widget header(BuildContext c) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(gradient: kGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(36))),
        child: Stack(children: [
          Positioned(top: -70, left: -50, child: ring(210, const Color(0x14FFFFFF))),
          Positioned(bottom: -40, right: -30, child: ring(140, const Color(0x0FFFFFFF))),
          Padding(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(c).padding.top + 12, 20, 22),
            child: Row(children: [
              Tap(
                onTap: () => tab(c, 3),
                child: Container(padding: const EdgeInsets.all(2.5), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: DocAvatar(size: 48, light: me.photo == null)),
              ),
              gapW(12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(greet(), style: t(12.5, w: FontWeight.w500, c: const Color(0xE6FFFFFF))),
                  Text(me.dn, maxLines: 1, overflow: TextOverflow.ellipsis, style: t(20, c: Colors.white)),
                  if (me.specLine.isNotEmpty) Text(me.specLine, maxLines: 1, overflow: TextOverflow.ellipsis, style: t(12, w: FontWeight.w500, c: const Color(0xE6FFFFFF))),
                ]),
              ),
              Stack(clipBehavior: Clip.none, children: [
                glass(const Icon(Icons.notifications_rounded, color: Colors.white, size: 24), () => tab(c, 2)),
                if (me.unread > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: kGold, shape: BoxShape.circle, border: Border.all(color: kRed, width: 2)),
                      child: Text('${me.unread}', style: t(9, c: kInk)),
                    ),
                  ),
              ]),
            ]),
          ),
        ]),
      );

  Widget banner(IconData i, String title, String body, {Color bg = kAmberBg, Color fg = kAmber, Widget? trailing}) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          Icon(i, color: fg, size: 26),
          gapW(12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: t(13.5, c: fg)),
              const SizedBox(height: 2),
              Text(body, style: t(11.5, w: FontWeight.w500, c: fg, h: 1.6)),
            ]),
          ),
          if (trailing != null) trailing,
        ]),
      );

  Widget heroStat(String v, String l) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(v, style: t(28, c: Colors.white, h: 1.1)),
          Text(l, style: t(11.5, w: FontWeight.w500, c: const Color(0xE6FFFFFF))),
        ]),
      );

  Widget tonight(BuildContext c) {
    final n = me.patients.length;
    final cur = me.inSession;
    final nx = cur ?? me.next;
    return Tap(
      onTap: () => go(c, const TonightScreen()),
      scale: .98,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(gradient: kGradient, borderRadius: BorderRadius.circular(28), boxShadow: kGlow),
        child: Stack(children: [
          Positioned(top: -50, left: -40, child: ring(170, const Color(0x1AFFFFFF))),
          Positioned(bottom: -60, right: -20, child: ring(150, const Color(0x12FFFFFF))),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 48, height: 48, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.nights_stay_rounded, color: kRed, size: 26)),
                gapW(12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('عيانين الليلة', style: t(20, c: Colors.white)),
                    Text(dayLabel(DateTime.now()), style: t(12, w: FontWeight.w500, c: const Color(0xE6FFFFFF))),
                  ]),
                ),
                const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ]),
              gap(16),
              if (n == 0)
                Text('لا توجد حجوزات الليلة حتى الآن.', style: t(13.5, w: FontWeight.w500, c: Colors.white))
              else
                Row(children: [heroStat('${me.waiting + me.inSessionCount}', 'بانتظارك'), heroStat('${me.doneCount}', 'تم الكشف'), heroStat('$n', 'الإجمالي')]),
              if (nx != null) ...[
                gap(14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0x26FFFFFF), borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    Icon(cur != null ? Icons.medical_services_rounded : Icons.person_pin_rounded, color: Colors.white, size: 20),
                    gapW(8),
                    Expanded(child: Text(cur != null ? 'قيد الكشف الآن: ${nx.name}' : 'التالي: ${nx.name} · ${fmtTime(nx.time)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: t(13, c: Colors.white))),
                  ]),
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  Widget todayCard() {
    final l = me.today;
    if (l.isEmpty) {
      return panel([
        Row(children: [
          tileIcon(Icons.event_busy_rounded, size: 44, color: kGrey, bg: kChip),
          gapW(12),
          Expanded(child: two('لا دوام اليوم', me.workplaces.isEmpty ? 'أضف أماكن عملك لتظهر هنا' : 'حسب جدولك الأسبوعي')),
        ]),
      ]);
    }
    return group([
      for (var i = 0; i < l.length; i++) ...[
        if (i > 0) const Divider(height: 1, color: kLine),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            tileIcon(kKindIcons[l[i].kind], size: 44),
            gapW(12),
            Expanded(child: two(l[i].name, '${fmtTime(l[i].from)} - ${fmtTime(l[i].to)}')),
            pill(wpBadge(l[i].status).$1, wpBadge(l[i].status).$2, wpBadge(l[i].status).$3),
          ]),
        ),
      ],
    ]);
  }

  Widget stat(IconData i, String v, String l) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: cardBox(18),
          child: Column(children: [Icon(i, color: kRed, size: 20), const SizedBox(height: 4), Text(v, style: t(17)), Text(l, style: t(11, w: FontWeight.w500, c: kGrey))]),
        ),
      );

  Widget completeness(BuildContext c) {
    final missing = me.checklist.where((e) => !e.$2).toList();
    if (missing.isEmpty) return const SizedBox.shrink();
    return panel([
      Row(children: [Expanded(child: Text('اكتمال ملفك المهني', style: t(14.5))), Text('${(me.complete * 100).round()}%', style: t(15, c: kRed))]),
      gap(10),
      ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: me.complete, minHeight: 8, backgroundColor: kChip, valueColor: const AlwaysStoppedAnimation<Color>(kRed))),
      gap(6),
      for (final m in missing.take(3))
        Tap(
          onTap: () {
            if (m.$3 == 0) {
              go(c, const ProfileFormScreen());
            } else {
              tab(c, 1);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [const Icon(Icons.radio_button_unchecked_rounded, color: kGrey, size: 18), gapW(10), Expanded(child: Text(m.$1, style: t(13, w: FontWeight.w600, c: kSub))), chev(kGrey, 20)]),
          ),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: me,
        builder: (c, _) => Scaffold(
          backgroundColor: kBg,
          body: Column(children: [
            header(c),
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 20), children: [
                if (!me.verified) banner(Icons.hourglass_top_rounded, 'حسابك قيد التوثيق', 'نراجع رقم المجلس الطبي خلال 24 ساعة. يمكنك إعداد ملفك في هذه الأثناء.'),
                if (!me.accepting)
                  banner(Icons.pause_circle_rounded, 'الحجوزات الجديدة متوقفة', 'لن يتمكن المرضى من الحجز معك حتى تعيد تفعيلها.', bg: kChip, fg: kSub, trailing: Switch(value: me.accepting, onChanged: (v) {
                    me.accepting = v;
                    me.ping();
                  })),
                tonight(c),
                secRow('دوامك اليوم · ${kDays[todayIdx]}'),
                todayCard(),
                secRow('أماكن عملي', more: 'عرض الكل', onMore: () => tab(c, 1)),
                Row(children: [
                  stat(Icons.apartment_rounded, '${me.workplaces.length}', 'أماكن عمل'),
                  stat(Icons.event_available_rounded, '${me.activeCount}', 'حجز مباشر'),
                  stat(Icons.chat_rounded, '${me.workplaces.where((w) => w.status == WpStatus.offApp).length}', 'تحتاج دعوة'),
                ]),
                gap(12),
                completeness(c),
              ]),
            ),
            const DocNav(active: 0),
          ]),
        ),
      );
}

// ═════════════════════════════════════════════════════════════════════════
//  6. عيانين الليلة
// ═════════════════════════════════════════════════════════════════════════
class TonightScreen extends StatefulWidget {
  const TonightScreen({super.key});
  @override
  State<TonightScreen> createState() => _TonightState();
}

class _TonightState extends State<TonightScreen> {
  final ctl = TextEditingController();
  int chip = 0;

  @override
  void dispose() {
    ctl.dispose();
    super.dispose();
  }

  List<String> get places => ['الكل', ...{for (final p in me.patients) p.place}];

  List<Patient> get list {
    final pl = places;
    final c = chip < pl.length ? chip : 0;
    final q = ctl.text.trim();
    return me.patients.where((p) => (c == 0 || p.place == pl[c]) && (q.isEmpty || p.name.contains(q) || p.reason.contains(q))).toList()..sort((a, b) => a.time.compareTo(b.time));
  }

  Widget timeBox(Patient p) {
    final parts = fmtTime(p.time).split(' ');
    final on = p.status == 1;
    final Color fg = on ? Colors.white : (p.status == 2 ? kGreenDk : (p.status == 3 ? kGrey : kRed));
    final Color bg = p.status == 2 ? kGreenBg : (p.status == 3 ? kChip : kTint);
    return Container(
      width: 62,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(gradient: on ? kGradient : null, color: on ? null : bg, borderRadius: BorderRadius.circular(18)),
      child: Column(children: [Text(parts[0], style: t(17, c: fg)), Text(parts[1], style: t(11, w: FontWeight.w600, c: fg))]),
    );
  }

  Widget card(BuildContext c, Patient p, bool showPlace) => Tap(
        onTap: () => go(c, PatientScreen(p)),
        scale: .985,
        child: Opacity(
          opacity: p.status >= 2 ? .75 : 1,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: cardBox(22),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              timeBox(p),
              gapW(12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: t(15.5))),
                    if (p.allergies.isNotEmpty) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.warning_amber_rounded, color: kRed, size: 18)),
                  ]),
                  Text('${ageLabel(p.age)} · ${p.female ? 'أنثى' : 'ذكر'}', style: t(12, w: FontWeight.w500, c: kGrey)),
                  const SizedBox(height: 4),
                  Text(p.reason, maxLines: 2, overflow: TextOverflow.ellipsis, style: t(12.5, w: FontWeight.w500, c: kSub, h: 1.5)),
                  gap(8),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    patientPill(p.status),
                    if (p.arrived && p.status == 0) pillOk('وصل'),
                    if (p.last == null) pill('مريض جديد', kBlueBg, kBlue),
                    if (showPlace) pill(p.place, kChip, kSub),
                  ]),
                ]),
              ),
              chev(kGrey, 22),
            ]),
          ),
        ),
      );

  Widget miniStat(String v, String l, Color col) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: cardBox(16),
          child: Column(children: [Text(v, style: t(19, c: col)), Text(l, style: t(11, w: FontWeight.w500, c: kGrey))]),
        ),
      );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: me,
        builder: (c, _) {
          final l = list;
          final pl = places;
          final sel = chip < pl.length ? chip : 0;
          final cur = me.inSession;
          final nx = cur ?? me.next;
          return RedPage(
            title: 'عيانين الليلة',
            bottomBar: nx == null
                ? null
                : btnBar(
                    c,
                    cur != null ? 'متابعة كشف ${cur.name}' : 'فتح ملف ${nx.name}',
                    () => go(c, PatientScreen(nx)),
                    icon: Icons.folder_open_rounded,
                    lead: Row(children: [
                      Icon(cur != null ? Icons.medical_services_rounded : Icons.person_pin_rounded, color: kRed, size: 20),
                      gapW(8),
                      Expanded(child: Text(cur != null ? 'قيد الكشف الآن' : 'المريض التالي · ${fmtTime(nx.time)}', style: t(12.5, w: FontWeight.w600, c: kSub))),
                    ]),
                  ),
            body: me.patients.isEmpty
                ? EmptyState(Icons.nights_stay_rounded, 'لا يوجد مرضى الليلة', 'ستظهر هنا حجوزات المرضى بمجرد حجزهم معك في أماكن عملك المفعّلة.', btn: 'أماكن عملي', onTap: () => tab(c, 1))
                : Column(children: [
                    Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 10), child: AppSearch('ابحث باسم المريض أو سبب الزيارة...', controller: ctl, fill: Colors.white, onChanged: (_) => setState(() {}))),
                    if (pl.length > 2) FilterChips(pl, sel: sel, onChanged: (v) => setState(() => chip = v)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                      child: Row(children: [
                        miniStat('${me.waiting + me.inSessionCount}', 'بانتظارك', kRed),
                        miniStat('${me.doneCount}', 'تم الكشف', kGreenDk),
                        miniStat('${me.missedCount}', 'لم يحضر', kGrey),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Row(children: [
                        const Icon(Icons.lock_outline_rounded, size: 14, color: kGrey),
                        gapW(5),
                        Expanded(child: Text('بيانات المرضى سرّية — للاستخدام العلاجي فقط', style: t(11, w: FontWeight.w500, c: kGrey))),
                      ]),
                    ),
                    Expanded(
                      child: l.isEmpty
                          ? EmptyState(Icons.search_off_rounded, 'لا توجد نتائج', 'غيّر البحث أو المكان وحاول مرة أخرى.', btn: 'مسح البحث', onTap: () => setState(() {
                                ctl.clear();
                                chip = 0;
                              }))
                          : ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), children: [for (final p in l) card(c, p, sel == 0 && pl.length > 2)]),
                    ),
                  ]),
          );
        },
      );
}

// ═════════════════════════════════════════════════════════════════════════
//  7. ملف المريض
// ═════════════════════════════════════════════════════════════════════════
class PatientScreen extends StatelessWidget {
  const PatientScreen(this.p, {super.key});
  final Patient p;

  void start(BuildContext c) {
    final cur = me.inSession;
    if (cur != null && cur != p) {
      snack(c, 'أنهِ كشف ${cur.name} أولاً');
      return;
    }
    p.status = 1;
    p.arrived = true;
    me.ping();
    snack(c, 'بدأ الكشف — ${p.name}', ok: true);
  }

  Future<void> finish(BuildContext c) async {
    final r = await sheet<(String, String, String)>(c, FinishSheet(p));
    if (r == null) return;
    p.diagnosis = r.$1;
    p.plan = r.$2;
    p.followUp = r.$3;
    p.status = 2;
    me.ping();
    if (c.mounted) snack(c, 'تم حفظ الكشف', ok: true);
  }

  Future<void> noShow(BuildContext c) async {
    final ok = await confirm(c, 'تسجيل عدم الحضور؟', 'سيُسجَّل أن ${p.name} لم يحضر موعده الليلة.', yes: 'تسجيل', no: 'تراجع', danger: false);
    if (!ok) return;
    p.status = 3;
    me.ping();
  }

  void reopen() {
    p.status = 0;
    me.ping();
  }

  Widget info(IconData i, String s) => Row(children: [
        Icon(i, color: kRed, size: 17),
        gapW(6),
        Expanded(child: Text(s, maxLines: 1, overflow: TextOverflow.ellipsis, style: t(12.5, w: FontWeight.w600, c: kSub))),
      ]);

  Widget head(BuildContext c) => Container(
        padding: const EdgeInsets.all(16),
        decoration: cardBox(24),
        child: Column(children: [
          Row(children: [
            Container(width: 62, height: 62, alignment: Alignment.center, decoration: BoxDecoration(gradient: kGradient, shape: BoxShape.circle, boxShadow: kGlow), child: Text(initial(p.name), style: t(26, c: Colors.white))),
            gapW(14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, style: t(17)),
                Text('${ageLabel(p.age)} · ${p.female ? 'أنثى' : 'ذكر'}', style: t(12.5, w: FontWeight.w500, c: kGrey)),
              ]),
            ),
            patientPill(p.status),
          ]),
          gap(14),
          Row(children: [Expanded(child: info(Icons.schedule_rounded, 'موعد ${fmtTime(p.time)}')), Expanded(child: info(Icons.apartment_rounded, p.place))]),
          gap(14),
          OutBtn('اتصال بالمريض', icon: Icons.phone_rounded, height: 44, onTap: () => contactSheet(c, p.name, p.phone)),
        ]),
      );

  Widget chipsBlock(String title, List<String> items) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: t(12.5, w: FontWeight.w600, c: kGrey)),
          gap(6),
          if (items.isEmpty)
            Text('لا يوجد', style: t(13, w: FontWeight.w500, c: kGrey))
          else
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in items) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: kChip, borderRadius: BorderRadius.circular(12)), child: Text(s, style: t(12.5, w: FontWeight.w600, c: kSub))),
            ]),
        ]),
      );

  Widget linesBlock(String title, List<String> items) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: t(12.5, w: FontWeight.w600, c: kGrey)),
          gap(6),
          if (items.isEmpty)
            Text('لا يوجد', style: t(13, w: FontWeight.w500, c: kGrey))
          else
            for (final s in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Padding(padding: EdgeInsets.only(top: 7), child: Icon(Icons.circle, size: 6, color: kRed)),
                  gapW(8),
                  Expanded(child: Text(s, style: t(13, w: FontWeight.w600, c: kSub, h: 1.5))),
                ]),
              ),
        ]),
      );

  Widget textBlock(String title, String v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: t(12.5, w: FontWeight.w600, c: kGrey)),
        gap(6),
        Text(v.isEmpty ? 'لا يوجد' : v, style: t(13, w: FontWeight.w600, c: v.isEmpty ? kGrey : kSub, h: 1.5)),
      ]);

  Widget labRow(Lab l) {
    final f = switch (l.flag) {
      1 => ('مرتفع', kTint, kRed),
      2 => ('منخفض', kBlueBg, kBlue),
      3 => ('غير طبيعي', kAmberBg, kAmber),
      _ => ('طبيعي', kGreenBg, kGreenDk),
    };
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        tileIcon(kLabIcons[l.kind], size: 40, color: l.flag == 0 ? kTeal : f.$3, bg: l.flag == 0 ? kTealBg : f.$2),
        gapW(12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.name, style: t(13.5)),
            Text(whenLabel(l.daysAgo), style: t(11, w: FontWeight.w500, c: kGrey)),
          ]),
        ),
        gapW(8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(l.result, textAlign: TextAlign.end, style: t(12.5, c: l.flag == 0 ? kInk : f.$3)),
            const SizedBox(height: 3),
            pill(f.$1, f.$2, f.$3),
          ]),
        ),
      ]),
    );
  }

  Widget labsCard() {
    if (p.labs.isEmpty) {
      return panel([Row(children: [tileIcon(Icons.science_outlined, size: 42, color: kGrey, bg: kChip), gapW(12), Expanded(child: two('لا توجد فحوصات مسجّلة', 'اطلب الفحوصات اللازمة أثناء الكشف'))])]);
    }
    return group([
      for (var i = 0; i < p.labs.length; i++) ...[
        if (i > 0) const Divider(height: 1, color: kLine),
        labRow(p.labs[i]),
      ],
    ]);
  }

  Widget lastVisit() {
    final v = p.last;
    if (v == null) {
      return panel([Row(children: [tileIcon(Icons.fiber_new_rounded, size: 42, color: kBlue, bg: kBlueBg), gapW(12), Expanded(child: two('أول زيارة لهذا المريض', 'لا توجد مقابلات سابقة مسجّلة'))])]);
    }
    return panel([
      kv('التاريخ', whenLabel(v.daysAgo)),
      kv('المكان', v.place),
      kv('الطبيب', v.by),
      if (v.vitals.isNotEmpty) kv('العلامات الحيوية', v.vitals),
      const Divider(height: 20, color: kLine),
      textBlock('التشخيص', v.diagnosis),
      gap(12),
      textBlock('الخطة والعلاج', v.plan),
    ]);
  }

  Widget? bar(BuildContext c) {
    switch (p.status) {
      case 0:
        return btnBar(c, 'بدء الكشف', () => start(c), icon: Icons.play_arrow_rounded, alt: 'لم يحضر', onAlt: () => noShow(c));
      case 1:
        return btnBar(c, 'إنهاء الكشف وحفظ الملاحظات', () => finish(c), icon: Icons.check_rounded);
      case 2:
        return btnBar(c, 'تعديل ملاحظات الكشف', () => finish(c), icon: Icons.edit_rounded);
      default:
        return btnBar(c, 'إعادة إلى قائمة الانتظار', reopen, icon: Icons.restart_alt_rounded);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: me,
        builder: (c, _) => RedPage(
          title: 'ملف المريض',
          bottomBar: bar(c),
          body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 20), children: [
            head(c),
            gap(12),
            panel([
              Row(children: [const Icon(Icons.edit_note_rounded, color: kRed, size: 22), gapW(8), Text('سبب الزيارة', style: t(14))]),
              gap(8),
              Text(p.reason, style: t(13.5, w: FontWeight.w600, c: kSub, h: 1.6)),
            ]),
            if (p.allergies.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: kTint, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF7C5C9))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.warning_amber_rounded, color: kRed, size: 26),
                  gapW(10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('تنبيه حساسية', style: t(13.5, c: kRed)),
                      const SizedBox(height: 2),
                      Text(p.allergies.join('، '), style: t(13, w: FontWeight.w600, h: 1.5)),
                    ]),
                  ),
                ]),
              ),
            if (p.status == 2 && p.diagnosis.isNotEmpty) ...[
              secRow('كشف الليلة'),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: kGreenBg, borderRadius: BorderRadius.circular(20)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  textBlock('التشخيص', p.diagnosis),
                  if (p.plan.isNotEmpty) ...[gap(12), textBlock('الخطة والعلاج', p.plan)],
                  if (p.followUp.isNotEmpty && p.followUp != 'بدون') ...[gap(12), textBlock('موعد المراجعة', 'بعد ${p.followUp}')],
                ]),
              ),
            ],
            secRow('التاريخ المرضي'),
            panel([
              chipsBlock('الأمراض المزمنة', p.conditions),
              linesBlock('الأدوية الحالية', p.meds),
              chipsBlock('عمليات سابقة', p.surgeries),
              textBlock('التاريخ العائلي', p.family),
            ]),
            secRow('الفحوصات'),
            labsCard(),
            secRow('آخر مقابلة'),
            lastVisit(),
          ]),
        ),
      );
}

/// ورقة إنهاء الكشف: تشخيص + خطة + موعد مراجعة.
class FinishSheet extends StatefulWidget {
  const FinishSheet(this.p, {super.key});
  final Patient p;
  @override
  State<FinishSheet> createState() => _FinishState();
}

class _FinishState extends State<FinishSheet> {
  static const follow = ['بدون', 'أسبوع', 'أسبوعين', 'شهر', '3 أشهر'];
  late final dx = TextEditingController(text: widget.p.diagnosis);
  late final plan = TextEditingController(text: widget.p.plan);
  late int f = follow.contains(widget.p.followUp) ? follow.indexOf(widget.p.followUp) : 0;
  String? err;

  @override
  void dispose() {
    dx.dispose();
    plan.dispose();
    super.dispose();
  }

  void save() {
    if (dx.text.trim().isEmpty) {
      setState(() => err = 'أدخل التشخيص');
      return;
    }
    Navigator.pop(context, (dx.text.trim(), plan.text.trim(), follow[f]));
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Text('إنهاء الكشف', style: t(17))),
          Center(child: Text(widget.p.name, style: t(12.5, w: FontWeight.w500, c: kGrey))),
          AppField('التشخيص', controller: dx, hint: 'مثال: التهاب الجيوب الأنفية الحاد', error: err, onChanged: (_) {
            if (err != null) setState(() => err = null);
          }),
          AppField('الخطة والعلاج / الوصفة', controller: plan, hint: 'الأدوية، الفحوصات المطلوبة، النصائح...', lines: 4),
          sec('موعد المراجعة'),
          ChipWrap(follow, sel: {f}, onChanged: (s) => f = s.first),
          gap(20),
          RedButton('حفظ وإنهاء الكشف', icon: Icons.check_rounded, onTap: save),
        ]),
      );
}

// ═════════════════════════════════════════════════════════════════════════
//  8. أماكن عملي
// ═════════════════════════════════════════════════════════════════════════
String wpDesc(WpStatus s) => switch (s) {
      WpStatus.active => 'يستطيع المرضى حجز موعدك هنا مباشرة من التطبيق.',
      WpStatus.pending => 'أرسلنا طلب انضمامك إلى المركز. يظهر الحجز المباشر فور تأكيدهم.',
      WpStatus.offApp => 'يظهر للمرضى كمكان عمل فقط، ولا يمكنهم الحجز عبر طبيبك قبل أن يفعّل المركز حسابه.',
    };

/// نص رسالة واتساب التي تُرسل للمركز لتفعيل حسابه في «طبيبك للمراكز».
String inviteMessage(Workplace w) {
  final sp = me.specialty.isEmpty ? '' : ' - ${me.specialty}';
  final b = StringBuffer()
    ..writeln('السلام عليكم ورحمة الله وبركاته،')
    ..writeln()
    ..writeln('معكم ${me.dn}$sp، رقم المجلس الطبي ${me.council}.')
    ..writeln('أعمل لديكم في ${w.name} وأرغب أن يتمكّن المرضى من حجز مواعيدي مباشرةً عبر تطبيق «طبيبك».')
    ..writeln()
    ..writeln('نرجو منكم تفعيل حسابكم في تطبيق «طبيبك للمراكز» وإضافتي ضمن أخصائيي المركز، ليظهر الحجز المباشر للمرضى.');
  if (kCenterAppUrl.isNotEmpty) {
    b
      ..writeln()
      ..writeln('رابط التطبيق: $kCenterAppUrl');
  }
  b
    ..writeln()
    ..write(me.gender == 1 ? 'شاكرةً لكم تعاونكم.' : 'شاكراً لكم تعاونكم.');
  return b.toString();
}

Future<void> inviteSheet(BuildContext c, Workplace w) => sheet<void>(c, InviteBody(w));

/// ورقة دعوة المركز عبر واتساب: رقم المركز + نص الرسالة (قابل للتعديل).
class InviteBody extends StatefulWidget {
  const InviteBody(this.w, {super.key});
  final Workplace w;
  @override
  State<InviteBody> createState() => _InviteState();
}

class _InviteState extends State<InviteBody> {
  late final ph = TextEditingController(text: widget.w.phone);
  late final msg = TextEditingController(text: inviteMessage(widget.w));
  String? err;

  @override
  void dispose() {
    ph.dispose();
    msg.dispose();
    super.dispose();
  }

  bool get phoneOk => waNumber(ph.text).length >= 11;

  Future<void> send() async {
    if (!phoneOk) {
      setState(() => err = 'أدخل رقم واتساب صحيح للمركز');
      return;
    }
    final w = widget.w;
    w.phone = ph.text.trim();
    final ok = await openWhatsApp(context, w.phone, msg.text);
    if (!ok || !mounted) return;
    w.invitedAt = DateTime.now();
    w.invites++;
    me.ping();
    Navigator.pop(context);
  }

  Future<void> copyLink() async {
    if (!phoneOk) {
      setState(() => err = 'أدخل رقم واتساب صحيح للمركز');
      return;
    }
    await Clipboard.setData(ClipboardData(text: waLink(ph.text, msg.text)));
    if (mounted) snack(context, 'تم نسخ رابط واتساب المباشر', ok: true);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: tileIcon(Icons.chat_rounded, size: 60, color: kGreenDk, bg: kGreenBg)),
          gap(12),
          Center(child: Text('دعوة ${widget.w.name} لتفعيل حسابه', textAlign: TextAlign.center, style: t(16))),
          gap(6),
          Center(child: Text('المركز غير مسجّل في طبيبك. أرسل له رسالة واتساب ليفعّل حسابه فيتمكّن المرضى من الحجز معك مباشرة.', textAlign: TextAlign.center, style: t(12.5, w: FontWeight.w500, c: kGrey, h: 1.7))),
          AppField('رقم واتساب المركز', controller: ph, hint: '+249 9XX XXX XXX', icon: Icons.chat_outlined, type: TextInputType.phone, ltr: true, error: err, onChanged: (_) {
            if (err != null) setState(() => err = null);
          }),
          AppField('نص الرسالة (يمكنك تعديله)', controller: msg, lines: 8),
          gap(18),
          RedButton('إرسال عبر واتساب', icon: Icons.chat_rounded, onTap: send),
          gap(10),
          OutBtn('نسخ رابط واتساب المباشر', icon: Icons.link_rounded, onTap: copyLink),
          gap(6),
          Center(child: Tap(onTap: () => Navigator.pop(context), child: Padding(padding: const EdgeInsets.all(8), child: Text('لاحقاً', style: t(13.5, w: FontWeight.w600, c: kGrey))))),
        ]),
      );
}

class WorkplacesScreen extends StatelessWidget {
  const WorkplacesScreen({super.key});

  Widget legendRow(Color fg, String title, String sub) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(margin: const EdgeInsets.only(top: 6), width: 10, height: 10, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
          gapW(10),
          Expanded(child: Text.rich(TextSpan(text: '$title: ', style: t(12, c: fg, h: 1.6), children: [TextSpan(text: sub, style: t(12, w: FontWeight.w500, c: kSub, h: 1.6))]))),
        ]),
      );

  Widget legend(BuildContext c) => panel([
        Row(children: [const Icon(Icons.info_outline_rounded, color: kRed, size: 20), gapW(8), Text('كيف يرى المرضى أماكن عملك؟', style: t(14))]),
        gap(8),
        legendRow(kGreenDk, 'مفعّل', 'يحجزون معك مباشرة'),
        legendRow(kAmber, 'بانتظار التأكيد', 'المركز لم يؤكد إضافتك بعد'),
        legendRow(kRed, 'غير مفعّل', 'يرون المكان فقط بلا حجز حتى يفعّل المركز حسابه'),
        gap(4),
        Tap(onTap: () => go(c, const PreviewScreen()), child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text('معاينة ملفي كما يراه المرضى', style: t(12.5, c: kRed)))),
      ]);

  Widget card(BuildContext c, Workplace w) {
    final b = wpBadge(w.status);
    final col = w.status == WpStatus.active ? kTeal : (w.status == WpStatus.pending ? kOrange : kGrey);
    final since = w.invitedAt == null ? null : DateTime.now().difference(w.invitedAt!).inDays;
    return Tap(
      onTap: () => go(c, WorkplaceFormScreen(w: w)),
      scale: .985,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: cardBox(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            gTile(kKindIcons[w.kind], size: 52, color: col),
            gapW(12),
            Expanded(child: two(w.name, '${kKinds[w.kind]} · ${w.area}')),
            chev(kGrey, 22),
          ]),
          gap(12),
          Row(children: [const Icon(Icons.schedule_rounded, color: kGrey, size: 17), gapW(6), Expanded(child: Text(w.schedule, style: t(12.5, w: FontWeight.w600, c: kSub)))]),
          const SizedBox(height: 6),
          Row(children: [const Icon(Icons.payments_outlined, color: kGrey, size: 17), gapW(6), Text('سعر الكشف ${money(w.fee)} ج.س', style: t(12.5, w: FontWeight.w600, c: kSub))]),
          gap(10),
          pill(b.$1, b.$2, b.$3),
          gap(6),
          Text(wpDesc(w.status), style: t(11.5, w: FontWeight.w500, c: kSub, h: 1.6)),
          if (w.status == WpStatus.offApp) ...[
            gap(12),
            RedButton(w.invitedAt == null ? 'إرسال دعوة عبر واتساب' : 'إعادة إرسال الدعوة', icon: Icons.chat_rounded, height: 46, onTap: () => inviteSheet(c, w)),
            if (since != null) Padding(padding: const EdgeInsets.only(top: 8), child: Center(child: Text('آخر دعوة: ${agoLabel(since)} · أُرسلت ${w.invites} ${w.invites > 2 ? 'مرات' : (w.invites == 2 ? 'مرتين' : 'مرة')}', style: t(11, w: FontWeight.w500, c: kGrey)))),
          ],
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: me,
        builder: (c, _) => RedPage(
          title: 'أماكن عملي',
          back: false,
          nav: const DocNav(active: 1),
          action: glass(const Icon(Icons.add_rounded, color: Colors.white, size: 26), () => go(c, const AddWorkplaceScreen())),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            legend(c),
            if (me.workplaces.isEmpty)
              panel([
                Center(child: tileIcon(Icons.apartment_rounded, size: 64)),
                gap(12),
                Center(child: Text('لم تضف أي مكان عمل بعد', style: t(15))),
                gap(4),
                Center(child: Text('أضف المراكز والمستشفيات والعيادات التي تعمل بها ليراك المرضى ويحجزوا معك.', textAlign: TextAlign.center, style: t(12.5, w: FontWeight.w500, c: kGrey, h: 1.7))),
                gap(14),
                RedButton('إضافة مكان عمل', icon: Icons.add_rounded, onTap: () => go(c, const AddWorkplaceScreen())),
              ])
            else
              for (final w in me.workplaces) card(c, w),
            if (me.workplaces.isNotEmpty)
              Tap(
                onTap: () => go(c, const AddWorkplaceScreen()),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: kRed.withAlpha(90), width: 1.4)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.add_rounded, color: kRed), gapW(6), Text('إضافة مكان عمل', style: t(14.5, c: kRed))]),
                ),
              ),
          ]),
        ),
      );
}

// ───────────────────────── إضافة مكان عمل: اختيار مركز مسجّل أو إضافة يدوية ─────────────────────────
class AddWorkplaceScreen extends StatefulWidget {
  const AddWorkplaceScreen({super.key});
  @override
  State<AddWorkplaceScreen> createState() => _AddWpState();
}

class _AddWpState extends State<AddWorkplaceScreen> {
  final ctl = TextEditingController();

  @override
  void dispose() {
    ctl.dispose();
    super.dispose();
  }

  List<RegCenter> get list {
    final q = ctl.text.trim();
    return kRegCenters.where((r) => q.isEmpty || r.name.contains(q) || r.area.contains(q) || kKinds[r.kind].contains(q)).toList();
  }

  bool added(RegCenter r) => me.workplaces.any((w) => w.name == r.name);

  Future<void> open({RegCenter? r}) async {
    final ok = await go<bool>(context, WorkplaceFormScreen(reg: r));
    if (ok == true && mounted) Navigator.pop(context);
  }

  Widget tile(RegCenter r) {
    final a = added(r);
    return Tap(
      onTap: a ? () => snack(context, 'هذا المكان مضاف إلى أماكن عملك') : () => open(r: r),
      scale: .985,
      child: Opacity(
        opacity: a ? .6 : 1,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: cardBox(20),
          child: Row(children: [
            gTile(kKindIcons[r.kind], size: 50, color: kTeal),
            gapW(12),
            Expanded(child: two(r.name, '${kKinds[r.kind]} · ${r.area}')),
            a ? pill('مضاف', kChip, kGrey) : pillOk('على طبيبك'),
          ]),
        ),
      ),
    );
  }

  Widget manual() => Tap(
        onTap: () => open(),
        scale: .985,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kTint, borderRadius: BorderRadius.circular(22)),
          child: Row(children: [
            tileIcon(Icons.add_business_rounded, size: 48, color: Colors.white, bg: kRed),
            gapW(12),
            Expanded(child: two('مكان عملي غير موجود؟', 'أضفه يدوياً وادعُه لتفعيل حسابه عبر واتساب')),
            chev(kRed, 22),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = list;
    return RedPage(
      title: 'إضافة مكان عمل',
      body: ListView(padding: const EdgeInsets.all(16), children: [
        AppSearch('ابحث عن مركز أو مستشفى...', controller: ctl, fill: Colors.white, onChanged: (_) => setState(() {})),
        gap(14),
        Text('مراكز ومستشفيات مسجّلة في طبيبك', style: t(13.5)),
        const SizedBox(height: 2),
        Text('اختر مكانك ليصل المركز طلب انضمامك، ويفعَّل الحجز المباشر بعد تأكيده.', style: t(11.5, w: FontWeight.w500, c: kGrey, h: 1.6)),
        gap(12),
        if (l.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 18), child: Center(child: Text('لا توجد نتائج مطابقة', style: t(13, w: FontWeight.w500, c: kGrey))))
        else
          for (final r in l) tile(r),
        gap(4),
        manual(),
      ]),
    );
  }
}

// ───────────────────────── نموذج مكان العمل (إضافة / تعديل) ─────────────────────────
class WorkplaceFormScreen extends StatefulWidget {
  const WorkplaceFormScreen({super.key, this.w, this.reg});
  final Workplace? w;
  final RegCenter? reg;
  @override
  State<WorkplaceFormScreen> createState() => _WpFormState();
}

class _WpFormState extends State<WorkplaceFormScreen> {
  late final nm = TextEditingController(text: widget.w?.name ?? widget.reg?.name ?? '');
  late final ad = TextEditingController(text: widget.w?.address ?? widget.reg?.address ?? '');
  late final ph = TextEditingController(text: widget.w?.phone ?? widget.reg?.phone ?? '');
  late final fee = TextEditingController(text: (widget.w?.fee ?? 0) > 0 ? '${widget.w!.fee}' : '');
  late int kind = widget.w?.kind ?? widget.reg?.kind ?? 0;
  late int area = _areaIdx(widget.w?.area ?? widget.reg?.area);
  late Set<int> days = {...(widget.w?.days ?? <int>{0, 1, 2, 3, 4})};
  late int from = widget.w?.from ?? 1020, to = widget.w?.to ?? 1260;
  late final fromC = TextEditingController(text: fmtTime(from));
  late final toC = TextEditingController(text: fmtTime(to));
  String? eName, ePhone, eDays, eTime, eFee;

  int _areaIdx(String? a) {
    final i = kAreas.indexOf(a ?? '');
    return i < 0 ? 0 : i;
  }

  @override
  void dispose() {
    for (final c in [nm, ad, ph, fee, fromC, toC]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get editing => widget.w != null;
  bool get locked => widget.reg != null || (widget.w != null && widget.w!.status != WpStatus.offApp);
  WpStatus get status => editing ? widget.w!.status : (widget.reg != null ? WpStatus.pending : WpStatus.offApp);

  Future<void> pickFrom() async {
    final v = await pickTime(context, from, 'وقت بداية الدوام');
    if (v == null || !mounted) return;
    setState(() {
      from = v;
      fromC.text = fmtTime(v);
      eTime = null;
    });
  }

  Future<void> pickTo() async {
    final v = await pickTime(context, to, 'وقت نهاية الدوام');
    if (v == null || !mounted) return;
    setState(() {
      to = v;
      toC.text = fmtTime(v);
      eTime = null;
    });
  }

  /// يبحث عن تعارض بين دوامك هنا ودوامك في مكان آخر.
  String? conflict() {
    for (final o in me.workplaces) {
      if (o == widget.w) continue;
      final common = days.intersection(o.days);
      if (common.isNotEmpty && from < o.to && o.from < to) {
        final d = common.toList()..sort();
        return 'دوامك هنا يتداخل مع دوامك في ${o.name} يوم ${kDays[d.first]} (${fmtTime(o.from)} - ${fmtTime(o.to)}).';
      }
    }
    return null;
  }

  Future<void> save() async {
    final n = nm.text.trim();
    final feeV = int.tryParse(fee.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
    setState(() {
      eName = n.length < 3 ? 'أدخل اسم المكان' : null;
      ePhone = (!locked && waNumber(ph.text).length < 11) ? 'أدخل رقم واتساب صحيح للمركز' : null;
      eDays = days.isEmpty ? 'اختر يوماً واحداً على الأقل' : null;
      eTime = to <= from ? 'وقت النهاية يجب أن يكون بعد وقت البداية' : null;
      eFee = feeV <= 0 ? 'أدخل سعر الكشف' : null;
    });
    if (eName != null || ePhone != null || eDays != null || eTime != null || eFee != null) return;
    final cf = conflict();
    if (cf != null) {
      final ok = await confirm(context, 'تعارض في الدوام', cf, yes: 'حفظ على أي حال', no: 'تعديل', danger: false);
      if (!ok || !mounted) return;
    }
    final w = widget.w;
    if (w != null) {
      if (!locked) {
        w.name = n;
        w.kind = kind;
        w.area = kAreas[area];
        w.address = ad.text.trim();
        w.phone = ph.text.trim();
      }
      w.days = {...days};
      w.from = from;
      w.to = to;
      w.fee = feeV;
      me.ping();
      snack(context, 'تم حفظ التغييرات', ok: true);
      Navigator.pop(context, true);
    } else if (widget.reg != null) {
      final r = widget.reg!;
      me.workplaces.add(Workplace(r.name, r.kind, r.area, address: r.address, phone: r.phone, status: WpStatus.pending, days: {...days}, from: from, to: to, fee: feeV));
      me.note(Icons.send_rounded, 'تم إرسال طلب الانضمام', 'أرسلنا طلبك إلى ${r.name}. سنُعلمك فور تأكيدهم.', dest: 2);
      snack(context, 'تم إرسال طلب الانضمام إلى ${r.name}', ok: true);
      Navigator.pop(context, true);
    } else {
      final nw = Workplace(n, kind, kAreas[area], address: ad.text.trim(), phone: ph.text.trim(), status: WpStatus.offApp, days: {...days}, from: from, to: to, fee: feeV);
      me.workplaces.add(nw);
      me.ping();
      await inviteSheet(context, nw);
      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<void> remove() async {
    final w = widget.w!;
    if (me.patients.any((p) => p.place == w.name && p.status < 2)) {
      snack(context, 'لا يمكن الحذف: لديك مرضى بانتظارك في ${w.name} الليلة');
      return;
    }
    final ok = await confirm(context, 'حذف مكان العمل؟', 'سيختفي ${w.name} من ملفك لدى المرضى.', yes: 'حذف');
    if (!ok || !mounted) return;
    me.workplaces.remove(w);
    me.ping();
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final b = wpBadge(status);
    return RedPage(
      title: editing ? 'تعديل مكان العمل' : (widget.reg != null ? 'طلب انضمام' : 'مكان عمل جديد'),
      bottomBar: btnBar(
        context,
        editing ? 'حفظ التغييرات' : (widget.reg != null ? 'إرسال طلب الانضمام' : 'حفظ مكان العمل'),
        save,
        alt: editing ? 'حذف مكان العمل' : null,
        onAlt: remove,
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
        gap(8),
        if (locked)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: cardBox(22),
            child: Row(children: [
              gTile(kKindIcons[kind], size: 52, color: kTeal),
              gapW(12),
              Expanded(child: two(nm.text, '${kKinds[kind]} · ${kAreas[area]}')),
              pillOk('على طبيبك'),
            ]),
          )
        else ...[
          AppField('اسم المكان', controller: nm, hint: 'مثال: عيادة الأمل', icon: Icons.apartment_rounded, error: eName, onChanged: (_) {
            if (eName != null) setState(() => eName = null);
          }),
          sec('النوع'),
          ChipWrap(kKinds, sel: {kind}, onChanged: (s) => setState(() => kind = s.first)),
          sec('المنطقة'),
          ChipWrap(kAreas, sel: {area}, onChanged: (s) => setState(() => area = s.first)),
          AppField('العنوان (اختياري)', controller: ad, hint: 'مثال: بحري - الدروشاب، شارع 5', icon: Icons.location_on_outlined),
          AppField('رقم واتساب المركز', controller: ph, hint: '+249 9XX XXX XXX', icon: Icons.chat_outlined, type: TextInputType.phone, ltr: true, error: ePhone, onChanged: (_) {
            if (ePhone != null) setState(() => ePhone = null);
          }),
        ],
        gap(14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: b.$2, borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.$1, style: t(13, c: b.$3)),
            const SizedBox(height: 4),
            Text(wpDesc(status), style: t(12, w: FontWeight.w500, c: b.$3, h: 1.6)),
          ]),
        ),
        if (editing && status == WpStatus.offApp) ...[
          gap(12),
          OutBtn(widget.w!.invitedAt == null ? 'إرسال دعوة عبر واتساب' : 'إعادة إرسال الدعوة', icon: Icons.chat_rounded, onTap: () {
            widget.w!.phone = ph.text.trim();
            inviteSheet(context, widget.w!);
          }),
        ],
        sec('أيام العمل'),
        ChipWrap(kDays, sel: days, multi: true, onChanged: (s) => setState(() {
              days = s;
              eDays = null;
            })),
        errText(eDays),
        Row(children: [
          Expanded(child: AppField('من', controller: fromC, icon: Icons.schedule_rounded, readOnly: true, onTap: pickFrom)),
          gapW(12),
          Expanded(child: AppField('إلى', controller: toC, icon: Icons.schedule_rounded, readOnly: true, onTap: pickTo)),
        ]),
        errText(eTime),
        AppField('سعر الكشف (ج.س)', controller: fee, hint: 'مثال: 10000', icon: Icons.payments_outlined, type: TextInputType.number, error: eFee, onChanged: (_) {
          if (eFee != null) setState(() => eFee = null);
        }),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  9. الإشعارات
// ═════════════════════════════════════════════════════════════════════════
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  void open(BuildContext c, Notif n) {
    n.unread = false;
    me.ping();
    switch (n.dest) {
      case 1:
        go(c, const TonightScreen());
      case 2:
        tab(c, 1);
      case 3:
        tab(c, 3);
      default:
        break;
    }
  }

  Widget tile(BuildContext c, Notif n) => Dismissible(
        key: ObjectKey(n),
        direction: DismissDirection.horizontal,
        background: Container(margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: kTint, borderRadius: BorderRadius.circular(20)), alignment: Alignment.center, child: const Icon(Icons.delete_outline_rounded, color: kRed)),
        onDismissed: (_) {
          me.notifs.remove(n);
          me.ping();
        },
        child: Tap(
          onTap: () => open(c, n),
          scale: .98,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: n.unread ? const Color(0xFFFFF7F8) : Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: kShadow, border: Border.all(color: n.unread ? const Color(0xFFFAD3D6) : const Color(0xFFF1F3F7))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              tileIcon(n.icon, size: 44),
              gapW(12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Expanded(child: Text(n.title, style: t(14))), if (n.unread) Container(width: 9, height: 9, decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle))]),
                  const SizedBox(height: 2),
                  Text(n.body, style: t(12, w: FontWeight.w500, c: kSub, h: 1.5)),
                  const SizedBox(height: 4),
                  Text(n.time, style: t(11, w: FontWeight.w500, c: kGrey)),
                ]),
              ),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: me,
        builder: (c, _) {
          final today = me.notifs.where((n) => n.today).toList();
          final older = me.notifs.where((n) => !n.today).toList();
          return RedPage(
            title: 'الإشعارات',
            back: false,
            nav: const DocNav(active: 2),
            action: me.unread > 0
                ? glass(const Icon(Icons.done_all_rounded, color: Colors.white, size: 22), () {
                    me.markAllRead();
                    snack(c, 'تم تحديد الكل كمقروء', ok: true);
                  })
                : null,
            body: me.notifs.isEmpty
                ? const EmptyState(Icons.notifications_off_rounded, 'لا توجد إشعارات', 'ستظهر هنا تنبيهات الحجوزات وحالة مراكزك.')
                : ListView(padding: const EdgeInsets.all(16), children: [
                    if (today.isNotEmpty) ...[Text('اليوم', style: t(14, c: kGrey)), gap(10), for (final n in today) tile(c, n)],
                    if (older.isNotEmpty) ...[gap(6), Text('أمس', style: t(14, c: kGrey)), gap(10), for (final n in older) tile(c, n)],
                  ]),
          );
        },
      );
}

// ═════════════════════════════════════════════════════════════════════════
//  10. حسابي
// ═════════════════════════════════════════════════════════════════════════
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> logout(BuildContext c) async {
    final ok = await confirm(c, 'تسجيل الخروج؟', 'يمكنك تسجيل الدخول مجدداً برقم المجلس ورقم هاتفك.', yes: 'تسجيل الخروج', no: 'بقاء', danger: false);
    if (!ok || !c.mounted) return;
    Navigator.pushAndRemoveUntil(c, MaterialPageRoute(builder: (_) => const AuthScreen()), (r) => false);
  }

  Future<void> deleteAccount(BuildContext c) async {
    final ok = await confirm(c, 'حذف الحساب نهائياً؟', 'سيُحذف ملفك المهني وأماكن عملك وكل بياناتك، ولا يمكن التراجع عن ذلك.', yes: 'حذف الحساب', no: 'تراجع');
    if (!ok || !c.mounted) return;
    me.reset();
    Navigator.pushAndRemoveUntil(c, MaterialPageRoute(builder: (_) => const AuthScreen()), (r) => false);
  }

  Widget stat(String v, String l, IconData i) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: cardBox(18),
          child: Column(children: [Icon(i, color: kRed, size: 20), const SizedBox(height: 4), Text(v, style: t(17)), Text(l, style: t(11, w: FontWeight.w500, c: kGrey))]),
        ),
      );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: me,
        builder: (c, _) => RedPage(
          title: 'حسابي',
          back: false,
          nav: const DocNav(active: 3),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: cardBox(24),
              child: Column(children: [
                Row(children: [
                  DocAvatar(size: 66, light: false),
                  gapW(14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(me.dn, maxLines: 1, overflow: TextOverflow.ellipsis, style: t(17)),
                      const SizedBox(height: 2),
                      Text([me.gradeName, me.specialty].where((s) => s.isNotEmpty).join(' · '), style: t(12.5, w: FontWeight.w500, c: kGrey)),
                      if (me.sub.isNotEmpty) Text('تخصص فرعي: ${me.sub}', style: t(11.5, w: FontWeight.w500, c: kGrey)),
                    ]),
                  ),
                  Tap(onTap: () => go(c, const ProfileFormScreen()), child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: kTint, borderRadius: BorderRadius.circular(14)), child: Text('تعديل', style: t(12.5, c: kRed)))),
                ]),
                gap(12),
                Row(children: [
                  Expanded(child: Text('رقم المجلس: ${me.council}', style: t(12, w: FontWeight.w600, c: kSub))),
                  me.verified ? pillOk('موثّق') : pillWarn('قيد التوثيق'),
                ]),
              ]),
            ),
            gap(12),
            Row(children: [
              stat('${me.workplaces.length}', 'أماكن عمل', Icons.apartment_rounded),
              stat('${me.activeCount}', 'حجز مباشر', Icons.event_available_rounded),
              stat('${me.patients.length}', 'مرضى الليلة', Icons.nights_stay_rounded),
            ]),
            secRow('ملفي المهني'),
            group([
              menuRow(Icons.badge_rounded, 'تعديل الملف المهني', onTap: () => go(c, const ProfileFormScreen())),
              menuRow(Icons.visibility_rounded, 'معاينة ملفي كما يراه المرضى', onTap: () => go(c, const PreviewScreen())),
              menuRow(Icons.apartment_rounded, 'أماكن عملي', trailing: cnt('${me.workplaces.length}'), onTap: () => tab(c, 1)),
            ]),
            secRow('الإعدادات'),
            group([
              menuRow(Icons.event_available_rounded, 'استقبال الحجوزات الجديدة', trailing: Switch(value: me.accepting, onChanged: (v) {
                me.accepting = v;
                me.ping();
                snack(c, v ? 'تم تفعيل استقبال الحجوزات' : 'تم إيقاف استقبال الحجوزات مؤقتاً', ok: v);
              })),
              menuRow(Icons.notifications_active_rounded, 'تنبيهات الحجوزات', trailing: Switch(value: me.notifOn, onChanged: (v) {
                me.notifOn = v;
                me.ping();
              })),
            ]),
            secRow('الدعم'),
            group([
              menuRow(Icons.support_agent_rounded, 'المساعدة والدعم الفني', onTap: () => contactSheet(c, 'الدعم الفني', kSupportPhone)),
              menuRow(Icons.policy_rounded, 'الشروط والخصوصية', onTap: () => go(c, const TermsScreen())),
            ]),
            gap(14),
            OutBtn('تسجيل الخروج', icon: Icons.logout_rounded, danger: true, onTap: () => logout(c)),
            gap(6),
            Center(child: Tap(onTap: () => deleteAccount(c), child: Padding(padding: const EdgeInsets.all(10), child: Text('حذف الحساب', style: t(12.5, w: FontWeight.w600, c: kGrey))))),
          ]),
        ),
      );
}

// ═════════════════════════════════════════════════════════════════════════
//  11. معاينة ملفي كما يراه المرضى
// ═════════════════════════════════════════════════════════════════════════
class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key});

  Widget fakeButton(String s, bool on) => Container(
        height: 44,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(gradient: on ? kGradient : null, color: on ? null : const Color(0xFFE3E7EE), borderRadius: BorderRadius.circular(14)),
        child: Text(s, style: t(13.5, c: on ? Colors.white : kGrey)),
      );

  Widget place(Workplace w) {
    final canBook = w.status == WpStatus.active && me.accepting;
    final label = !me.accepting ? 'الحجز متوقف مؤقتاً' : (w.status == WpStatus.active ? 'احجز موعدك' : (w.status == WpStatus.pending ? 'الحجز قريباً' : 'الحجز غير متاح حالياً'));
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: cardBox(22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          gTile(kKindIcons[w.kind], size: 48, color: kTeal),
          gapW(12),
          Expanded(child: two(w.name, '${kKinds[w.kind]} · ${w.area}')),
        ]),
        gap(10),
        Row(children: [const Icon(Icons.schedule_rounded, color: kGrey, size: 17), gapW(6), Expanded(child: Text(w.schedule, style: t(12.5, w: FontWeight.w600, c: kSub)))]),
        const SizedBox(height: 4),
        Row(children: [const Icon(Icons.payments_outlined, color: kGrey, size: 17), gapW(6), Text('${money(w.fee)} ج.س', style: t(12.5, w: FontWeight.w700, c: kRed))]),
        gap(12),
        fakeButton(label, canBook),
        if (w.status == WpStatus.offApp) Padding(padding: const EdgeInsets.only(top: 6), child: Text('هذا المركز غير مفعّل على طبيبك بعد.', style: t(11, w: FontWeight.w500, c: kGrey))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: me,
        builder: (c, _) => RedPage(
          title: 'معاينة ملفي',
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kBlueBg, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [const Icon(Icons.visibility_rounded, color: kBlue, size: 20), gapW(8), Expanded(child: Text('هكذا يظهر ملفك للمرضى. الأزرار هنا للعرض فقط.', style: t(12, w: FontWeight.w600, c: kBlue)))]),
            ),
            gap(12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: cardBox(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  DocAvatar(size: 72),
                  gapW(14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(me.dn, style: t(17)),
                      const SizedBox(height: 4),
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        if (me.grade >= 0) pill(me.gradeFull, kTint, kRed),
                        if (me.specialty.isNotEmpty) pill(me.specialty, kChip, kSub),
                      ]),
                    ]),
                  ),
                ]),
                if (me.sub.isNotEmpty) ...[gap(12), Text('التخصص الفرعي: ${me.sub}', style: t(12.5, w: FontWeight.w600, c: kSub))],
                if (me.exp >= 0) ...[gap(8), Text('خبرة ${ageLabel(me.exp)}', style: t(12.5, w: FontWeight.w600, c: kSub))],
                if (me.bio.isNotEmpty) ...[gap(10), Text(me.bio, style: t(12.5, w: FontWeight.w500, c: kSub, h: 1.7))],
                if (me.quals.isNotEmpty) ...[
                  gap(12),
                  Text('المؤهلات', style: t(12.5, w: FontWeight.w600, c: kGrey)),
                  gap(6),
                  for (final q in me.quals) Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [const Icon(Icons.school_rounded, size: 16, color: kRed), gapW(8), Expanded(child: Text(q, style: t(12.5, w: FontWeight.w600, c: kSub)))])),
                ],
              ]),
            ),
            secRow('أماكن العمل'),
            if (me.workplaces.isEmpty) panel([Text('لم تضف أماكن عمل بعد.', style: t(13, w: FontWeight.w500, c: kGrey))]) else for (final w in me.workplaces) place(w),
          ]),
        ),
      );
}
