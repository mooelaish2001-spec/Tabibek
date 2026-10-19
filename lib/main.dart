import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color primary = Color(0xFFFF3B30);
const Color darkRed = Color(0xFFB91C1C);
const Color background = Color(0xFFF5F5F7);
const Color ink = Color(0xFF171717);
const Color muted = Color(0xFF858585);
const Color green = Color(0xFF22C55E);
const Color blue = Color(0xFF3B82F6);
const Color purple = Color(0xFF8B5CF6);
const Color orange = Color(0xFFF59E0B);

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic v) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0;
}

String _asStr(dynamic v) => v?.toString() ?? '';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TabibekApp());
}

class Doctor {
  String name,
      qualifications,
      registration,
      phone,
      avatar,
      specialty,
      center,
      email;
  Doctor({
    this.name = 'د. أحمد محمد',
    this.qualifications = 'MBBS, MD',
    this.registration = 'SM-12458',
    this.phone = '0912345678',
    this.avatar = '',
    this.specialty = 'أخصائي أطفال',
    this.center = 'مركز النور - أمبدة',
    this.email = '',
  });
  Map<String, dynamic> toMap() => {
        'name': name,
        'qualifications': qualifications,
        'registration': registration,
        'phone': phone,
        'avatar': avatar,
        'specialty': specialty,
        'center': center,
        'email': email,
      };
  factory Doctor.fromMap(Map<String, dynamic> m) => Doctor(
        name: _asStr(m['name']).isEmpty ? 'د. أحمد محمد' : _asStr(m['name']),
        qualifications: _asStr(m['qualifications']),
        registration: _asStr(m['registration']),
        phone: _asStr(m['phone']),
        avatar: _asStr(m['avatar']),
        specialty: _asStr(m['specialty']),
        center: _asStr(m['center']),
        email: _asStr(m['email']),
      );
}

class Patient {
  String id, name, gender, phone, complaint, bloodPressure, notes;
  String appointmentDate, appointmentTime, status, createdAt;
  int age, heartRate;
  double temperature;
  List<String> prescriptions;
  Patient({
    required this.id,
    required this.name,
    required this.age,
    this.gender = 'ذكر',
    this.phone = '',
    this.complaint = '',
    this.bloodPressure = '',
    this.heartRate = 0,
    this.temperature = 0,
    this.notes = '',
    this.appointmentDate = '',
    this.appointmentTime = '',
    this.status = 'قادم',
    this.createdAt = '',
    List<String>? prescriptions,
  }) : prescriptions = prescriptions ?? [];
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'age': age,
        'gender': gender,
        'phone': phone,
        'complaint': complaint,
        'bloodPressure': bloodPressure,
        'heartRate': heartRate,
        'temperature': temperature,
        'notes': notes,
        'appointmentDate': appointmentDate,
        'appointmentTime': appointmentTime,
        'status': status,
        'createdAt': createdAt,
        'prescriptions': prescriptions,
      };
  factory Patient.fromMap(Map<String, dynamic> m) => Patient(
        id: _asStr(m['id']),
        name: _asStr(m['name']),
        age: _asInt(m['age']),
        gender: _asStr(m['gender']).isEmpty ? 'ذكر' : _asStr(m['gender']),
        phone: _asStr(m['phone']),
        complaint: _asStr(m['complaint']),
        bloodPressure: _asStr(m['bloodPressure']),
        heartRate: _asInt(m['heartRate']),
        temperature: _asDouble(m['temperature']),
        notes: _asStr(m['notes']),
        appointmentDate: _asStr(m['appointmentDate']),
        appointmentTime: _asStr(m['appointmentTime']),
        status: _asStr(m['status']).isEmpty ? 'قادم' : _asStr(m['status']),
        createdAt: _asStr(m['createdAt']),
        prescriptions: (m['prescriptions'] is List)
            ? List<String>.from((m['prescriptions'] as List).map((e) => _asStr(e)))
            : <String>[],
      );
}

class MedicalCenter {
  String id, name, address, phone, specialty, doctorRegistration;
  bool active;
  MedicalCenter({
    required this.id,
    required this.name,
    this.address = '',
    this.phone = '',
    this.specialty = '',
    this.doctorRegistration = '',
    this.active = true,
  });
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'address': address,
        'phone': phone,
        'specialty': specialty,
        'doctorRegistration': doctorRegistration,
        'active': active,
      };
  factory MedicalCenter.fromMap(Map<String, dynamic> m) => MedicalCenter(
        id: _asStr(m['id']),
        name: _asStr(m['name']),
        address: _asStr(m['address']),
        phone: _asStr(m['phone']),
        specialty: _asStr(m['specialty']),
        doctorRegistration: _asStr(m['doctorRegistration']),
        active: m['active'] == true,
      );
}

class Appointment {
  String id, patientId, patientName, date, time, reason, status;
  Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.date,
    required this.time,
    required this.reason,
    this.status = 'قادم',
  });
  Map<String, dynamic> toMap() => {
        'id': id,
        'patientId': patientId,
        'patientName': patientName,
        'date': date,
        'time': time,
        'reason': reason,
        'status': status,
      };
  factory Appointment.fromMap(Map<String, dynamic> m) => Appointment(
        id: _asStr(m['id']),
        patientId: _asStr(m['patientId']),
        patientName: _asStr(m['patientName']),
        date: _asStr(m['date']),
        time: _asStr(m['time']),
        reason: _asStr(m['reason']),
        status: _asStr(m['status']).isEmpty ? 'قادم' : _asStr(m['status']),
      );
}

class TabibekStore extends ChangeNotifier {
  static final instance = TabibekStore._();
  TabibekStore._();
  Doctor doctor = Doctor();
  List<Patient> patients = [];
  List<MedicalCenter> centers = [];
  List<Appointment> appointments = [];
  bool initialized = false, loggedIn = false;

  static const _kDoctor = 'tabibek.doctor',
      _kPatients = 'tabibek.patients',
      _kCenters = 'tabibek.centers',
      _kAppointments = 'tabibek.appointments',
      _kLoggedIn = 'tabibek.loggedIn';

  Future<void> initialize() async {
    if (initialized) return;
    try {
      final p = await SharedPreferences.getInstance();
      final docJson = p.getString(_kDoctor);
      if (docJson != null) {
        doctor = Doctor.fromMap(Map<String, dynamic>.from(jsonDecode(docJson)));
        final pj = p.getString(_kPatients);
        if (pj != null) {
          patients = (jsonDecode(pj) as List)
              .map((e) => Patient.fromMap(Map<String, dynamic>.from(e)))
              .toList();
        }
        final cj = p.getString(_kCenters);
        if (cj != null) {
          centers = (jsonDecode(cj) as List)
              .map((e) => MedicalCenter.fromMap(Map<String, dynamic>.from(e)))
              .toList();
        }
        final aj = p.getString(_kAppointments);
        if (aj != null) {
          appointments = (jsonDecode(aj) as List)
              .map((e) => Appointment.fromMap(Map<String, dynamic>.from(e)))
              .toList();
        }
        loggedIn = p.getBool(_kLoggedIn) ?? false;
      } else {
        _loadDemoData();
        try {
          await _persist();
        } catch (_) {}
      }
    } catch (_) {
      _loadDemoData();
      loggedIn = false;
    }
    initialized = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kDoctor, jsonEncode(doctor.toMap()));
      await p.setString(
          _kPatients, jsonEncode(patients.map((e) => e.toMap()).toList()));
      await p.setString(
          _kCenters, jsonEncode(centers.map((e) => e.toMap()).toList()));
      await p.setString(_kAppointments,
          jsonEncode(appointments.map((e) => e.toMap()).toList()));
      await p.setBool(_kLoggedIn, loggedIn);
    } catch (_) {}
  }

  void _loadDemoData() {
    patients = [
      Patient(
        id: 'P001',
        name: 'Ahmed Hassan',
        age: 32,
        gender: 'ذكر',
        phone: '0912345678',
        complaint: 'ضيق تنفس وكحة',
        bloodPressure: '130/85',
        heartRate: 98,
        temperature: 37.2,
        appointmentDate: todayString(),
        appointmentTime: '07:30 ص',
        createdAt: DateTime.now().toIso8601String(),
      ),
      Patient(
        id: 'P002',
        name: 'Sara Ali',
        age: 25,
        gender: 'أنثى',
        phone: '0912345679',
        complaint: 'صداع مستمر',
        bloodPressure: '120/80',
        heartRate: 82,
        temperature: 36.8,
        appointmentDate: todayString(),
        appointmentTime: '07:45 ص',
        createdAt: DateTime.now().toIso8601String(),
      ),
    ];
    centers = [
      MedicalCenter(
          id: 'C001',
          name: 'مركز النور - أمبدة',
          address: 'أمبدة، السودان',
          phone: '0912345678',
          specialty: 'مركز طبي عام',
          doctorRegistration: doctor.registration)
    ];
    appointments = patients
        .map((p) => Appointment(
            id: 'A${p.id}',
            patientId: p.id,
            patientName: p.name,
            date: p.appointmentDate,
            time: p.appointmentTime,
            reason: p.complaint,
            status: p.status))
        .toList();
  }

  String todayString() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  String newId(String pre) => '$pre${DateTime.now().microsecondsSinceEpoch}';

  Future<void> setLoggedIn(bool v) async {
    loggedIn = v;
    await _persist();
    notifyListeners();
  }

  Future<void> saveDoctor(Doctor v) async {
    doctor = v;
    for (final c in centers) {
      c.doctorRegistration = v.registration;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> addPatient(Patient p) async {
    patients.insert(0, p);
    appointments.add(Appointment(
        id: newId('A'),
        patientId: p.id,
        patientName: p.name,
        date: p.appointmentDate,
        time: p.appointmentTime,
        reason: p.complaint,
        status: p.status));
    await _persist();
    notifyListeners();
  }

  Future<void> updatePatient(Patient p) async {
    final i = patients.indexWhere((x) => x.id == p.id);
    if (i >= 0) {
      patients[i] = p;
      final ai = appointments.indexWhere((a) => a.patientId == p.id);
      if (ai >= 0) {
        appointments[ai] = Appointment(
            id: appointments[ai].id,
            patientId: p.id,
            patientName: p.name,
            date: p.appointmentDate,
            time: p.appointmentTime,
            reason: p.complaint,
            status: p.status);
      }
      await _persist();
      notifyListeners();
    }
  }

  Future<void> deletePatient(Patient p) async {
    patients.removeWhere((x) => x.id == p.id);
    appointments.removeWhere((a) => a.patientId == p.id);
    await _persist();
    notifyListeners();
  }

  Future<void> addCenter(MedicalCenter c) async {
    centers.insert(0, c);
    await _persist();
    notifyListeners();
  }

  Future<void> updateCenter(MedicalCenter c) async {
    final i = centers.indexWhere((x) => x.id == c.id);
    if (i >= 0) {
      centers[i] = c;
      await _persist();
      notifyListeners();
    }
  }

  Future<void> deleteCenter(MedicalCenter c) async {
    centers.removeWhere((x) => x.id == c.id);
    await _persist();
    notifyListeners();
  }

  Future<void> updateAppointmentStatus(Appointment a, String s) async {
    final i = appointments.indexWhere((x) => x.id == a.id);
    if (i >= 0) {
      appointments[i].status = s;
      final pi = patients.indexWhere((p) => p.id == a.patientId);
      if (pi >= 0) patients[pi].status = s;
      await _persist();
      notifyListeners();
    }
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert({
        'doctor': doctor.toMap(),
        'patients': patients.map((e) => e.toMap()).toList(),
        'centers': centers.map((e) => e.toMap()).toList(),
        'appointments': appointments.map((e) => e.toMap()).toList(),
      });
}

class TabibekApp extends StatelessWidget {
  const TabibekApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TABIBEK',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
                seedColor: primary, brightness: Brightness.light)
            .copyWith(primary: primary, surface: Colors.white),
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8F8F8),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: primary, width: 1.4)),
        ),
      ),
      builder: (c, ch) => Directionality(
          textDirection: TextDirection.rtl, child: ch ?? const SizedBox.shrink()),
      home: const SplashPage(),
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1300), () async {
      if (!mounted) return;
      try {
        await TabibekStore.instance.initialize();
      } catch (_) {}
      if (!mounted) return;
      Widget next;
      try {
        next = TabibekStore.instance.loggedIn
            ? const MainTabs()
            : const LoginPage();
      } catch (_) {
        next = const LoginPage();
      }
      try {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => next));
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primary, darkRed]),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services_rounded, size: 75, color: Colors.white),
            SizedBox(height: 18),
            Text('TABIBEK',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 35,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2)),
            SizedBox(height: 9),
            Text('رعايتك الطبية تبدأ هنا',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            SizedBox(height: 30),
            SizedBox(
                width: 25,
                height: 25,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2)),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final phone = TextEditingController(), pass = TextEditingController();
  bool hide = true;

  @override
  void dispose() {
    phone.dispose();
    pass.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;
    await TabibekStore.instance.setLoggedIn(true);
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const MainTabs()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(23),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                      child: Icon(Icons.medical_services_rounded,
                          size: 68, color: primary)),
                  const SizedBox(height: 18),
                  const Center(
                      child: Text('TABIBEK',
                          style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              color: primary))),
                  const SizedBox(height: 32),
                  const Text('مرحباً بعودتك',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: ink)),
                  const SizedBox(height: 8),
                  const Text('سجل الدخول لإدارة ملفك الطبي',
                      style: TextStyle(color: muted)),
                  const SizedBox(height: 27),
                  const FieldLabel('رقم الهاتف'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        hintText: 'أدخل رقم الهاتف',
                        prefixIcon:
                            Icon(Icons.phone_outlined, color: primary)),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'أدخل رقم الهاتف'
                        : null,
                  ),
                  const SizedBox(height: 17),
                  const FieldLabel('كلمة المرور'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: pass,
                    obscureText: hide,
                    decoration: InputDecoration(
                      hintText: 'أدخل كلمة المرور',
                      prefixIcon:
                          const Icon(Icons.lock_outline_rounded, color: primary),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => hide = !hide),
                        icon: Icon(hide
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'أدخل كلمة المرور' : null,
                  ),
                  const SizedBox(height: 25),
                  primaryButton(
                      title: 'تسجيل الدخول',
                      icon: Icons.login_rounded,
                      height: 53,
                      onPressed: login),
                  const SizedBox(height: 13),
                  primaryButton(
                    title: 'إنشاء حساب طبيب جديد',
                    icon: Icons.person_add_alt_1_rounded,
                    color: ink,
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegistrationPage())),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});
  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name, qual, reg, phone, spec, center, email;

  @override
  void initState() {
    super.initState();
    final d = TabibekStore.instance.doctor;
    name = TextEditingController(text: d.name);
    qual = TextEditingController(text: d.qualifications);
    reg = TextEditingController(text: d.registration);
    phone = TextEditingController(text: d.phone);
    spec = TextEditingController(text: d.specialty);
    center = TextEditingController(text: d.center);
    email = TextEditingController(text: d.email);
  }

  @override
  void dispose() {
    name.dispose();
    qual.dispose();
    reg.dispose();
    phone.dispose();
    spec.dispose();
    center.dispose();
    email.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    await TabibekStore.instance.saveDoctor(Doctor(
        name: name.text.trim(),
        qualifications: qual.text.trim(),
        registration: reg.text.trim(),
        phone: phone.text.trim(),
        specialty: spec.text.trim(),
        center: center.text.trim(),
        email: email.text.trim()));
    await TabibekStore.instance.setLoggedIn(true);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (_) => const MainTabs()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('تسجيل الطبيب')),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('أنشئ ملفك الطبي',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w900, color: ink)),
              const SizedBox(height: 8),
              const Text('أدخل بياناتك المهنية للمتابعة',
                  style: TextStyle(color: muted)),
              const SizedBox(height: 23),
              _f('الاسم الكامل', name, Icons.person_outline),
              _f('المؤهلات العلمية', qual, Icons.school_outlined),
              _f('رقم التسجيل الطبي', reg, Icons.verified_outlined),
              _f('رقم الهاتف', phone, Icons.phone_outlined,
                  keyboard: TextInputType.phone),
              _f('التخصص الطبي', spec, Icons.medical_services_outlined),
              _f('اسم المركز', center, Icons.local_hospital_outlined),
              _f('البريد الإلكتروني (اختياري)', email, Icons.email_outlined,
                  req: false, keyboard: TextInputType.emailAddress),
              const SizedBox(height: 16),
              primaryButton(
                  title: 'حفظ ومتابعة',
                  icon: Icons.check_circle_outline_rounded,
                  height: 53,
                  onPressed: save),
            ],
          ),
        ),
      ),
    );
  }

  Widget _f(String l, TextEditingController c, IconData i,
      {bool req = true, TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FieldLabel(l),
        const SizedBox(height: 8),
        TextFormField(
          controller: c,
          keyboardType: keyboard,
          validator: (v) {
            if (req && (v == null || v.trim().isEmpty)) return 'هذا الحقل مطلوب';
            if (l.contains('البريد') &&
                v != null &&
                v.trim().isNotEmpty &&
                !v.contains('@')) return 'البريد غير صحيح';
            return null;
          },
          decoration: InputDecoration(
              prefixIcon: Icon(i, color: primary), hintText: l),
        ),
      ]),
    );
  }
}

class MainTabs extends StatefulWidget {
  const MainTabs({super.key});
  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  int idx = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onNavigate: (i) => setState(() => idx = i)),
      const PatientsPage(),
      const AppointmentsPage(),
      const CentersPage(),
      const ProfilePage()
    ];
    return Scaffold(
      body: IndexedStack(index: idx, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => setState(() => idx = i),
        indicatorColor: const Color(0xFFFFE5E3),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'الرئيسية'),
          NavigationDestination(
              icon: Icon(Icons.people_outline_rounded),
              selectedIcon: Icon(Icons.people_rounded),
              label: 'المرضى'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded),
              label: 'المواعيد'),
          NavigationDestination(
              icon: Icon(Icons.local_hospital_outlined),
              selectedIcon: Icon(Icons.local_hospital_rounded),
              label: 'المراكز'),
          NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'حسابي'),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const HomePage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final s = TabibekStore.instance;
    return AnimatedBuilder(
      animation: s,
      builder: (c, _) {
        final t = s.todayString();
        final todayCount =
            s.appointments.where((a) => a.date == t && a.status != 'ملغي').length;
        return Scaffold(
          backgroundColor: background,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    decoration: const BoxDecoration(
                        color: ink,
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(28),
                            bottomRight: Radius.circular(28))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.medical_services_rounded,
                              color: primary, size: 30),
                          const SizedBox(width: 10),
                          const Expanded(
                              child: Text('TABIBEK',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 21,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1))),
                          IconButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const SettingsPage())),
                              icon: const Icon(Icons.settings_outlined,
                                  color: Colors.white)),
                        ]),
                        const SizedBox(height: 27),
                        Text('مرحباً، ${s.doctor.name}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Text(s.doctor.specialty,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 23),
                        Row(children: [
                          Expanded(
                              child: _stat('مرضى مسجلون', '${s.patients.length}',
                                  Icons.people_alt_outlined, primary)),
                          const SizedBox(width: 11),
                          Expanded(
                              child: _stat('مواعيد اليوم', '$todayCount',
                                  Icons.calendar_month_outlined, blue)),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  sectionTitle('لوحة التحكم', subtitle: 'إدارة عيادتك بسهولة'),
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.12,
                      children: [
                        DashboardCard(
                            icon: Icons.person_add_alt_1_rounded,
                            title: 'إضافة مريض',
                            subtitle: 'تسجيل بيانات مريض جديد',
                            color: primary,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const PatientFormPage()))),
                        DashboardCard(
                            icon: Icons.people_alt_rounded,
                            title: 'قائمة المرضى',
                            subtitle: '${s.patients.length} مريض',
                            color: blue,
                            onTap: () => onNavigate(1)),
                        DashboardCard(
                            icon: Icons.calendar_month_rounded,
                            title: 'المواعيد',
                            subtitle: 'تنظيم الزيارات',
                            color: purple,
                            onTap: () => onNavigate(2)),
                        DashboardCard(
                            icon: Icons.local_hospital_rounded,
                            title: 'المراكز الطبية',
                            subtitle: '${s.centers.length} مركز',
                            color: green,
                            onTap: () => onNavigate(3)),
                        DashboardCard(
                            icon: Icons.card_giftcard_rounded,
                            title: 'دعوة مركز',
                            subtitle: 'برنامج الإحالات',
                            color: orange,
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const InvitePage()))),
                        DashboardCard(
                            icon: Icons.person_outline_rounded,
                            title: 'ملفي الشخصي',
                            subtitle: 'بيانات الطبيب',
                            color: purple,
                            onTap: () => onNavigate(4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _stat(String l, String v, IconData i, Color c) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Icon(i, color: c, size: 25),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900)),
                Text(l,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const DashboardCard(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        borderRadius: BorderRadius.circular(19),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: const Color(0xFFF0F0F0))),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  width: 49,
                  height: 49,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.11),
                      borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: color, size: 26)),
              const SizedBox(height: 12),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w900, color: ink)),
              const SizedBox(height: 5),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: muted)),
            ],
          ),
        ),
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w800, color: ink));
}

class InfoTile extends StatelessWidget {
  final IconData icon;
  final String title, value;
  const InfoTile(
      {super.key, required this.icon, required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
                color: const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: primary, size: 21)),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: muted)),
            const SizedBox(height: 5),
            Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: ink)),
          ],
        )),
      ]),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});
  @override
  Widget build(BuildContext context) {
    Color c = green;
    if (status == 'ملغي') c = primary;
    if (status == 'حضر') c = blue;
    if (status == 'مكتمل') c = purple;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
      child: Text(status,
          style: TextStyle(
              color: c, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: Column(children: [
          Icon(icon, size: 48, color: muted),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(color: muted, fontSize: 12),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

Widget primaryButton(
    {required String title,
    required VoidCallback onPressed,
    IconData? icon,
    Color color = primary,
    double height = 48}) {
  return SizedBox(
    width: double.infinity,
    height: height,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (icon != null) ...[Icon(icon, size: 19), const SizedBox(width: 8)],
        Text(title,
            style:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
      ]),
    ),
  );
}

Widget sectionTitle(String title, {String? subtitle}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w900, color: ink)),
      if (subtitle != null) ...[
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: muted, fontSize: 11)),
      ],
    ]),
  );
}

void showMessage(BuildContext c, String m) {
  if (!c.mounted) return;
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
        content: Text(m),
        backgroundColor: ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
}

Future<void> copyText(BuildContext c, String v, String m) async {
  await Clipboard.setData(ClipboardData(text: v));
  if (!c.mounted) return;
  showMessage(c, m);
}

// ✅ بديل واتساب — نسخ الرابط والرسالة للحافظة
Future<void> copyWhatsAppMessage(
    BuildContext context, String phone, String message) async {
  if (phone.trim().isEmpty) {
    showMessage(context, 'رقم الهاتف غير مسجل');
    return;
  }
  String clean = phone.trim().replaceAll(RegExp(r'[^0-9]'), '');
  if (clean.startsWith('0')) clean = '249${clean.substring(1)}';
  if (!clean.startsWith('249')) clean = '249$clean';
  final text =
      'wa.me/$clean\n\n$message';
  await copyText(context, text, 'تم نسخ الرابط والرسالة — افتح واتساب والصق ✅');
}

String formatTemp(double t) {
  if (t == 0) return 'غير مسجلة';
  return '${t.truncateToDouble() == t ? t.toInt() : t}°C';
}

class PrescriptionPage extends StatefulWidget {
  final Patient patient;
  const PrescriptionPage({super.key, required this.patient});
  @override
  State<PrescriptionPage> createState() => _PrescriptionPageState();
}

class _PrescriptionPageState extends State<PrescriptionPage> {
  late Patient patient;
  final controller = TextEditingController();
  @override
  void initState() {
    super.initState();
    patient = widget.patient;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = TabibekStore.instance;
    return Scaffold(
      appBar: AppBar(title: Text('روشتة - ${patient.name}')),
      body: Column(children: [
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('المريض: ${patient.name} - ${patient.age} سنة',
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                      Text('التشخيص: ${patient.complaint}',
                          style: const TextStyle(color: muted, fontSize: 12)),
                      const Divider(height: 25),
                      if (patient.prescriptions.isEmpty)
                        const Text('لا توجد أدوية بعد',
                            style: TextStyle(color: muted))
                      else
                        ...patient.prescriptions.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(children: [
                              const Icon(Icons.medication_outlined,
                                  size: 18, color: primary),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(e,
                                      style: const TextStyle(fontSize: 13))),
                              IconButton(
                                  onPressed: () async {
                                    patient.prescriptions.remove(e);
                                    await s.updatePatient(patient);
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.delete_outline,
                                      size: 18, color: muted))
                            ]))),
                    ])),
            const SizedBox(height: 16),
            TextField(
                controller: controller,
                decoration: const InputDecoration(
                    hintText:
                        'مثال: Amoxicillin 500mg - حبة كل 8 ساعات - 5 أيام',
                    prefixIcon: Icon(Icons.add)),
                minLines: 2,
                maxLines: 4),
            const SizedBox(height: 10),
            primaryButton(
                title: 'إضافة دواء للروشتة',
                icon: Icons.add,
                onPressed: () async {
                  if (controller.text.trim().isEmpty) return;
                  patient.prescriptions.add(controller.text.trim());
                  controller.clear();
                  await s.updatePatient(patient);
                  setState(() {});
                }),
          ]),
        ),
        Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              primaryButton(
                  title: 'نسخ الروشتة لإرسالها بواتساب',
                  icon: Icons.copy_rounded,
                  color: green,
                  onPressed: () {
                    final text =
                        '*روشتة طبية - TABIBEK*\n*الدكتور:* ${s.doctor.name} - ${s.doctor.specialty}\n*المريض:* ${patient.name} - ${patient.age} سنة\n*التاريخ:* ${DateTime.now().toString().split(' ')[0]}\n\n*الأدوية:*\n${patient.prescriptions.map((e) => '- $e').join('\n')}\n\n*ملاحظات:* ${patient.notes.isEmpty ? 'لا يوجد' : patient.notes}';
                    copyWhatsAppMessage(context, patient.phone, text);
                  }),
              const SizedBox(height: 8),
              primaryButton(
                  title: 'نسخ الأدوية فقط',
                  icon: Icons.copy,
                  color: ink,
                  onPressed: () {
                    final text = patient.prescriptions.join('\n');
                    copyText(context, text, 'تم نسخ الروشتة ✅');
                  }),
            ]))
      ]),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = TabibekStore.instance;
    return AnimatedBuilder(
      animation: s,
      builder: (c, _) {
        final d = s.doctor;
        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(title: const Text('ملفي الشخصي')),
          body: ListView(padding: const EdgeInsets.all(18), children: [
            Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(23)),
                child: Column(children: [
                  const CircleAvatar(
                      radius: 48,
                      backgroundColor: Color(0xFFFFEEEE),
                      child:
                          Icon(Icons.person_rounded, size: 55, color: primary)),
                  const SizedBox(height: 15),
                  Text(d.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: ink)),
                  const SizedBox(height: 7),
                  Text(d.specialty, style: const TextStyle(color: muted)),
                  const SizedBox(height: 8),
                  Text(d.registration,
                      style: const TextStyle(
                          color: primary, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 20),
                  primaryButton(
                      title: 'تعديل بيانات الطبيب',
                      icon: Icons.edit_outlined,
                      onPressed: () => Navigator.push(
                          c,
                          MaterialPageRoute(
                              builder: (_) => const EditDoctorPage()))),
                ])),
            const SizedBox(height: 17),
            InfoTile(
                icon: Icons.school_outlined,
                title: 'المؤهلات',
                value: d.qualifications),
            InfoTile(
                icon: Icons.phone_outlined, title: 'الهاتف', value: d.phone),
            InfoTile(
                icon: Icons.email_outlined,
                title: 'البريد',
                value: d.email.isEmpty ? 'غير محدد' : d.email),
            InfoTile(
                icon: Icons.local_hospital_outlined,
                title: 'المركز',
                value: d.center),
            const SizedBox(height: 20),
            primaryButton(
                title: 'تصدير نسخة احتياطية',
                icon: Icons.backup_outlined,
                color: ink,
                onPressed: () =>
                    copyText(c, s.exportJson(), 'تم نسخ النسخة الاحتياطية ✅')),
          ]),
        );
      },
    );
  }
}

class EditDoctorPage extends StatefulWidget {
  const EditDoctorPage({super.key});
  @override
  State<EditDoctorPage> createState() => _EditDoctorPageState();
}

class _EditDoctorPageState extends State<EditDoctorPage> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController name, qual, reg, phone, spec, center, email;
  @override
  void initState() {
    super.initState();
    final d = TabibekStore.instance.doctor;
    name = TextEditingController(text: d.name);
    qual = TextEditingController(text: d.qualifications);
    reg = TextEditingController(text: d.registration);
    phone = TextEditingController(text: d.phone);
    spec = TextEditingController(text: d.specialty);
    center = TextEditingController(text: d.center);
    email = TextEditingController(text: d.email);
  }

  @override
  void dispose() {
    name.dispose();
    qual.dispose();
    reg.dispose();
    phone.dispose();
    spec.dispose();
    center.dispose();
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل بيانات الطبيب')),
      body: Form(
        key: formKey,
        child: ListView(padding: const EdgeInsets.all(18), children: [
          _i('الاسم الكامل', name),
          _i('المؤهلات', qual),
          _i('رقم التسجيل', reg),
          _i('رقم الهاتف', phone, keyboard: TextInputType.phone),
          _i('التخصص', spec),
          _i('المركز', center),
          _i('البريد الإلكتروني', email, req: false),
          const SizedBox(height: 15),
          primaryButton(
              title: 'حفظ التعديلات',
              icon: Icons.save_outlined,
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final old = TabibekStore.instance.doctor;
                await TabibekStore.instance.saveDoctor(Doctor(
                    name: name.text.trim(),
                    qualifications: qual.text.trim(),
                    registration: reg.text.trim(),
                    phone: phone.text.trim(),
                    specialty: spec.text.trim(),
                    center: center.text.trim(),
                    email: email.text.trim(),
                    avatar: old.avatar));
                if (!mounted) return;
                showMessage(context, 'تم تحديث البيانات');
                Navigator.pop(context);
              }),
        ]),
      ),
    );
  }

  Widget _i(String l, TextEditingController c,
      {bool req = true, TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        validator: (v) =>
            req && (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
        decoration: InputDecoration(labelText: l),
      ),
    );
  }
}

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});
  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  final search = TextEditingController();
  String q = '';
  String selectedDate = '';
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = TabibekStore.instance;
    return AnimatedBuilder(
      animation: s,
      builder: (c, _) {
        var f = s.patients.where((p) {
          final matchText = p.name.toLowerCase().contains(q.toLowerCase()) ||
              p.phone.contains(q) ||
              p.complaint.contains(q);
          final matchDate =
              selectedDate.isEmpty || p.appointmentDate == selectedDate;
          return matchText && matchDate;
        }).toList();
        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
              title: Text('المرضى (${f.length}/${s.patients.length})'),
              actions: [
                IconButton(
                    onPressed: () => Navigator.push(
                        c,
                        MaterialPageRoute(
                            builder: (_) => const PatientFormPage())),
                    icon: const Icon(Icons.person_add_alt_1_rounded))
              ]),
          body: Column(children: [
            Padding(
                padding: const EdgeInsets.all(15),
                child: Column(children: [
                  TextField(
                      controller: search,
                      onChanged: (v) => setState(() => q = v),
                      decoration: const InputDecoration(
                          hintText: 'ابحث بالاسم أو الهاتف أو الشكوى',
                          prefixIcon:
                              Icon(Icons.search_rounded, color: primary))),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                        child: Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                    color: const Color(0xFFEEEEEE))),
                            child: Row(children: [
                              const Icon(Icons.calendar_month,
                                  color: primary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(
                                      selectedDate.isEmpty
                                          ? 'كل التواريخ'
                                          : selectedDate,
                                      style: const TextStyle(fontSize: 12))),
                              if (selectedDate.isNotEmpty)
                                IconButton(
                                    onPressed: () =>
                                        setState(() => selectedDate = ''),
                                    icon: const Icon(Icons.clear, size: 18))
                              else
                                IconButton(
                                    onPressed: () async {
                                      final init = DateTime.tryParse(selectedDate) ??
                                          DateTime.now();
                                      final r = await showDatePicker(
                                          context: context,
                                          initialDate: init,
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2100));
                                      if (r != null) {
                                        setState(() => selectedDate =
                                            '${r.year}-${r.month.toString().padLeft(2, '0')}-${r.day.toString().padLeft(2, '0')}');
                                      }
                                    },
                                    icon:
                                        const Icon(Icons.date_range, size: 18))
                            ]))),
                    const SizedBox(width: 8),
                    ElevatedButton(
                        onPressed: () async {
                          final init = DateTime.now();
                          final r = await showDatePicker(
                              context: context,
                              initialDate: init,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100));
                          if (r != null) {
                            setState(() => selectedDate =
                                '${r.year}-${r.month.toString().padLeft(2, '0')}-${r.day.toString().padLeft(2, '0')}');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: ink,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13))),
                        child: const Text('تاريخ',
                            style: TextStyle(fontSize: 12)))
                  ])
                ])),
            Expanded(
                child: f.isEmpty
                    ? const EmptyState(
                        icon: Icons.person_search_outlined,
                        title: 'لا توجد نتائج',
                        subtitle: 'جرب البحث بكلمة أخرى أو غير التاريخ')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                        itemCount: f.length,
                        itemBuilder: (context, i) =>
                            PatientCard(patient: f[i]))),
          ]),
        );
      },
    );
  }
}

class PatientCard extends StatelessWidget {
  final Patient patient;
  const PatientCard({super.key, required this.patient});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF0F0F0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 47,
              height: 47,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: const Color(0xFFFFEEEE),
                  borderRadius: BorderRadius.circular(14)),
              child: Text(
                  patient.name.isEmpty ? '?' : patient.name[0].toUpperCase(),
                  style: const TextStyle(
                      color: primary,
                      fontSize: 19,
                      fontWeight: FontWeight.w900))),
          const SizedBox(width: 11),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(patient.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 14)),
              const SizedBox(height: 5),
              Text(
                  '${patient.age} سنة • ${patient.gender} • ${patient.appointmentDate}',
                  style: const TextStyle(color: muted, fontSize: 11)),
            ],
          )),
          StatusChip(status: patient.status),
        ]),
        const SizedBox(height: 15),
        Row(children: [
          const Icon(Icons.medical_information_outlined, color: muted, size: 17),
          const SizedBox(width: 8),
          Expanded(
              child: Text(
                  patient.complaint.isEmpty ? 'غير مسجل' : patient.complaint,
                  style: const TextStyle(fontSize: 12))),
        ]),
        const SizedBox(height: 13),
        Row(children: [
          Expanded(
              child: primaryButton(
                  title: 'التفاصيل',
                  icon: Icons.visibility_outlined,
                  color: ink,
                  height: 42,
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => PatientDetailPage(patient: patient))))),
          const SizedBox(width: 9),
          Expanded(
              child: primaryButton(
                  title: 'روشتة',
                  icon: Icons.medication_rounded,
                  color: orange,
                  height: 42,
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => PrescriptionPage(patient: patient))))),
        ]),
      ]),
    );
  }
}

class PatientFormPage extends StatefulWidget {
  final Patient? patient;
  const PatientFormPage({super.key, this.patient});
  @override
  State<PatientFormPage> createState() => _PatientFormPageState();
}

class _PatientFormPageState extends State<PatientFormPage> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController name,
      age,
      phone,
      complaint,
      bp,
      hr,
      temp,
      notes,
      date,
      time;
  String gender = 'ذكر', status = 'قادم';

  @override
  void initState() {
    super.initState();
    final p = widget.patient;
    final s = TabibekStore.instance;
    name = TextEditingController(text: p?.name ?? '');
    age = TextEditingController(text: p?.age.toString() ?? '');
    phone = TextEditingController(text: p?.phone ?? '');
    complaint = TextEditingController(text: p?.complaint ?? '');
    bp = TextEditingController(text: p?.bloodPressure ?? '');
    hr = TextEditingController(
        text: (p == null || p.heartRate == 0) ? '' : p.heartRate.toString());
    temp = TextEditingController(
        text: (p == null || p.temperature == 0)
            ? ''
            : p.temperature.toString());
    notes = TextEditingController(text: p?.notes ?? '');
    date = TextEditingController(text: p?.appointmentDate ?? s.todayString());
    time = TextEditingController(text: p?.appointmentTime ?? '09:00 ص');
    gender = p?.gender ?? 'ذكر';
    status = p?.status ?? 'قادم';
  }

  @override
  void dispose() {
    name.dispose();
    age.dispose();
    phone.dispose();
    complaint.dispose();
    bp.dispose();
    hr.dispose();
    temp.dispose();
    notes.dispose();
    date.dispose();
    time.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    TimeOfDay initial = TimeOfDay.now();
    final m = RegExp(r'(\d{1,2}):(\d{2})\s*(ص|م|AM|PM)?', caseSensitive: false)
        .firstMatch(time.text);
    if (m != null) {
      int h = int.parse(m.group(1)!);
      final min = int.parse(m.group(2)!);
      final per = m.group(3);
      if (per != null) {
        final isPM = per == 'م' || per.toUpperCase() == 'PM';
        if (isPM && h < 12) h += 12;
        if (!isPM && h == 12) h = 0;
      }
      initial = TimeOfDay(hour: h, minute: min);
    }
    final t = await showTimePicker(context: context, initialTime: initial);
    if (t != null) {
      final per = t.period == DayPeriod.am ? 'ص' : 'م';
      final h12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
      time.text =
          '${h12.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} $per';
    }
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    final p = Patient(
        id: widget.patient?.id ?? TabibekStore.instance.newId('P'),
        name: name.text.trim(),
        age: int.parse(age.text.trim()),
        gender: gender,
        phone: phone.text.trim(),
        complaint: complaint.text.trim(),
        bloodPressure: bp.text.trim(),
        heartRate: int.tryParse(hr.text.trim()) ?? 0,
        temperature: double.tryParse(temp.text.trim()) ?? 0,
        notes: notes.text.trim(),
        appointmentDate: date.text.trim(),
        appointmentTime: time.text.trim(),
        status: status,
        createdAt: widget.patient?.createdAt ?? DateTime.now().toIso8601String(),
        prescriptions: widget.patient?.prescriptions ?? []);
    if (widget.patient == null) {
      await TabibekStore.instance.addPatient(p);
    } else {
      await TabibekStore.instance.updatePatient(p);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.patient == null
              ? 'إضافة مريض جديد'
              : 'تعديل بيانات المريض')),
      body: Form(
        key: formKey,
        child: ListView(padding: const EdgeInsets.all(18), children: [
          _i('اسم المريض الكامل', name),
          _i('العمر', age, keyboard: TextInputType.number, validator: (v) {
            final val = int.tryParse(v ?? '');
            if (val == null || val < 0 || val > 130) return 'أدخل عمراً صحيحاً';
            return null;
          }),
          const FieldLabel('الجنس'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
              value: gender,
              decoration: const InputDecoration(),
              items: const [
                DropdownMenuItem(value: 'ذكر', child: Text('ذكر')),
                DropdownMenuItem(value: 'أنثى', child: Text('أنثى'))
              ],
              onChanged: (v) => setState(() => gender = v ?? 'ذكر')),
          const SizedBox(height: 15),
          _i('رقم الهاتف', phone, keyboard: TextInputType.phone, req: false),
          _i('الشكوى الرئيسية', complaint),
          _i('ضغط الدم مثال 120/80', bp, req: false),
          _i('معدل النبض', hr, keyboard: TextInputType.number, req: false,
              validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            return int.tryParse(v.trim()) == null ? 'أدخل رقماً صحيحاً' : null;
          }),
          _i('درجة الحرارة', temp,
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              req: false, validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            return double.tryParse(v.trim()) == null
                ? 'أدخل رقماً صحيحاً'
                : null;
          }),
          const SizedBox(height: 5),
          const FieldLabel('تاريخ الموعد'),
          const SizedBox(height: 8),
          TextFormField(
              controller: date,
              readOnly: true,
              onTap: () async {
                final init = DateTime.tryParse(date.text) ?? DateTime.now();
                final r = await showDatePicker(
                    context: context,
                    initialDate: init,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100));
                if (r != null) {
                  date.text =
                      '${r.year}-${r.month.toString().padLeft(2, '0')}-${r.day.toString().padLeft(2, '0')}';
                }
              },
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_month, color: primary))),
          const SizedBox(height: 15),
          const FieldLabel('وقت الموعد'),
          const SizedBox(height: 8),
          TextFormField(
              controller: time,
              readOnly: true,
              onTap: _pickTime,
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.access_time, color: primary))),
          const SizedBox(height: 15),
          const FieldLabel('ملاحظات'),
          const SizedBox(height: 8),
          TextFormField(
              controller: notes,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: 'ملاحظات إضافية (اختياري)')),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
              value: status,
              items: const [
                DropdownMenuItem(value: 'قادم', child: Text('قادم')),
                DropdownMenuItem(value: 'حضر', child: Text('حضر')),
                DropdownMenuItem(value: 'مكتمل', child: Text('مكتمل')),
                DropdownMenuItem(value: 'ملغي', child: Text('ملغي')),
              ],
              onChanged: (v) => setState(() => status = v ?? 'قادم'),
              decoration: const InputDecoration(labelText: 'حالة الموعد')),
          const SizedBox(height: 20),
          primaryButton(
              title: 'حفظ بيانات المريض',
              icon: Icons.save_outlined,
              height: 52,
              onPressed: save),
        ]),
      ),
    );
  }

  Widget _i(String l, TextEditingController c,
      {bool req = true,
      TextInputType keyboard = TextInputType.text,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FieldLabel(l),
        const SizedBox(height: 8),
        TextFormField(
          controller: c,
          keyboardType: keyboard,
          validator: validator ??
              (v) =>
                  req && (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
          decoration: InputDecoration(hintText: l),
        ),
      ]),
    );
  }
}

class PatientDetailPage extends StatelessWidget {
  final Patient patient;
  const PatientDetailPage({super.key, required this.patient});
  @override
  Widget build(BuildContext context) {
    final hasPhone = patient.phone.trim().isNotEmpty;
    final s = TabibekStore.instance;
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(title: const Text('تفاصيل المريض'), actions: [
        IconButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => PatientFormPage(patient: patient))),
            icon: const Icon(Icons.edit_outlined)),
        IconButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                        title: const Text('حذف المريض'),
                        content: Text('هل تريد حذف ${patient.name}؟'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(d, false),
                              child: const Text('إلغاء')),
                          TextButton(
                              onPressed: () => Navigator.pop(d, true),
                              child: const Text('حذف',
                                  style: TextStyle(color: primary))),
                        ],
                      ));
              if (ok == true) {
                await TabibekStore.instance.deletePatient(patient);
                if (!context.mounted) return;
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.delete_outline_rounded)),
      ]),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(22)),
            child: Column(children: [
              CircleAvatar(
                  radius: 39,
                  backgroundColor: const Color(0xFFFFEEEE),
                  child: Text(
                      patient.name.isEmpty
                          ? '?'
                          : patient.name[0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: primary))),
              const SizedBox(height: 14),
              Text(patient.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 21, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('${patient.age} سنة • ${patient.gender}',
                  style: const TextStyle(color: muted)),
              const SizedBox(height: 10),
              StatusChip(status: patient.status),
            ])),
        const SizedBox(height: 15),
        InfoTile(
            icon: Icons.medical_information_outlined,
            title: 'الشكوى',
            value: patient.complaint.isEmpty ? 'غير مسجل' : patient.complaint),
        InfoTile(
            icon: Icons.phone_outlined,
            title: 'الهاتف',
            value: hasPhone ? patient.phone : 'غير مسجل'),
        InfoTile(
            icon: Icons.favorite_outline_rounded,
            title: 'ضغط الدم',
            value: patient.bloodPressure.isEmpty
                ? 'غير مسجل'
                : patient.bloodPressure),
        InfoTile(
            icon: Icons.monitor_heart_outlined,
            title: 'معدل النبض',
            value: patient.heartRate == 0
                ? 'غير مسجل'
                : '${patient.heartRate} bpm'),
        InfoTile(
            icon: Icons.thermostat_outlined,
            title: 'درجة الحرارة',
            value: formatTemp(patient.temperature)),
        InfoTile(
            icon: Icons.calendar_month_outlined,
            title: 'تاريخ الموعد',
            value: '${patient.appointmentDate} • ${patient.appointmentTime}'),
        if (patient.prescriptions.isNotEmpty)
          Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.medication_rounded, color: primary),
                      const SizedBox(width: 8),
                      const Text('الروشتة',
                          style: TextStyle(fontWeight: FontWeight.w900))
                    ]),
                    const SizedBox(height: 10),
                    ...patient.prescriptions.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $e',
                            style: const TextStyle(fontSize: 13))))
                  ])),
        if (patient.notes.isNotEmpty)
          InfoTile(
              icon: Icons.notes_rounded,
              title: 'ملاحظات',
              value: patient.notes),
        const SizedBox(height: 18),
        primaryButton(
            title: 'كتابة / تعديل روشتة',
            icon: Icons.edit_note_rounded,
            color: orange,
            height: 50,
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => PrescriptionPage(patient: patient)))),
        const SizedBox(height: 10),
        primaryButton(
            title: 'نسخ تفاصيل المريض لإرسالها بواتساب',
            icon: Icons.copy_rounded,
            color: hasPhone ? green : muted,
            height: 50,
            onPressed: () {
              final msg =
                  'مرحبا ${patient.name}، تفاصيل زيارتك:\nالشكوى: ${patient.complaint}\nالضغط: ${patient.bloodPressure}\nالحرارة: ${formatTemp(patient.temperature)}\nمن ${s.doctor.name}';
              copyWhatsAppMessage(context, patient.phone, msg);
            }),
      ]),
    );
  }
}

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});
  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  String selectedDate = '';
  @override
  Widget build(BuildContext context) {
    final s = TabibekStore.instance;
    return AnimatedBuilder(
      animation: s,
      builder: (c, _) {
        var list = s.appointments;
        if (selectedDate.isNotEmpty) {
          list = list.where((a) => a.date == selectedDate).toList();
        }
        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(title: Text('المواعيد (${list.length})'), actions: [
            IconButton(
                onPressed: () async {
                  final init =
                      DateTime.tryParse(selectedDate) ?? DateTime.now();
                  final r = await showDatePicker(
                      context: context,
                      initialDate: init,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100));
                  if (r != null) {
                    setState(() => selectedDate =
                        '${r.year}-${r.month.toString().padLeft(2, '0')}-${r.day.toString().padLeft(2, '0')}');
                  }
                },
                icon: const Icon(Icons.calendar_month)),
            if (selectedDate.isNotEmpty)
              IconButton(
                  onPressed: () => setState(() => selectedDate = ''),
                  icon: const Icon(Icons.clear)),
          ]),
          body: Column(children: [
            if (selectedDate.isNotEmpty)
              Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                          color: primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.filter_alt,
                            size: 18, color: primary),
                        const SizedBox(width: 8),
                        Text('مواعيد: $selectedDate',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 12)),
                        const Spacer(),
                        GestureDetector(
                            onTap: () => setState(() => selectedDate = ''),
                            child: const Text('إلغاء الفلتر',
                                style: TextStyle(
                                    color: primary, fontSize: 11)))
                      ]))),
            Expanded(
                child: list.isEmpty
                    ? const EmptyState(
                        icon: Icons.event_busy_outlined,
                        title: 'لا توجد مواعيد',
                        subtitle: 'أضف مرضى أو غير التاريخ')
                    : ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final a = list[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                final p = s.patients.firstWhere(
                                    (x) => x.id == a.patientId,
                                    orElse: () => Patient(
                                        id: '', name: a.patientName, age: 0));
                                if (p.id.isNotEmpty) {
                                  Navigator.push(
                                      c,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              PatientDetailPage(patient: p)));
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(children: [
                                  Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                          color: const Color(0xFFFFEEEE),
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: const Icon(
                                          Icons.calendar_month_rounded,
                                          color: primary,
                                          size: 20)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(a.patientName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13)),
                                      const SizedBox(height: 3),
                                      Text('${a.date} • ${a.time}',
                                          style: const TextStyle(
                                              color: muted, fontSize: 11)),
                                    ],
                                  )),
                                  StatusChip(status: a.status),
                                  PopupMenuButton<String>(
                                    onSelected: (v) async {
                                      if (v == 'details') {
                                        final p = s.patients.firstWhere(
                                            (x) => x.id == a.patientId,
                                            orElse: () => Patient(
                                                id: '',
                                                name: a.patientName,
                                                age: 0));
                                        if (p.id.isNotEmpty) {
                                          Navigator.push(
                                              c,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      PatientDetailPage(
                                                          patient: p)));
                                        }
                                      } else {
                                        await s.updateAppointmentStatus(a, v);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                          value: 'details',
                                          child: Text('التفاصيل')),
                                      const PopupMenuDivider(),
                                      for (final ss in const [
                                        'قادم',
                                        'حضر',
                                        'مكتمل',
                                        'ملغي'
                                      ])
                                        PopupMenuItem(
                                            value: ss,
                                            child:
                                                Text('تغيير إلى: $ss')),
                                    ],
                                  ),
                                ]),
                              ),
                            ),
                          );
                        })),
          ]),
        );
      },
    );
  }
}

class CentersPage extends StatelessWidget {
  const CentersPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = TabibekStore.instance;
    return AnimatedBuilder(
      animation: s,
      builder: (c, _) {
        return Scaffold(
          backgroundColor: background,
          appBar:
              AppBar(title: Text('المراكز (${s.centers.length})'), actions: [
            IconButton(
                onPressed: () => Navigator.push(c,
                    MaterialPageRoute(builder: (_) => const CenterFormPage())),
                icon: const Icon(Icons.add))
          ]),
          body: s.centers.isEmpty
              ? const EmptyState(
                  icon: Icons.local_hospital_outlined,
                  title: 'لا توجد مراكز',
                  subtitle: 'أضف مراكزك الطبية')
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: s.centers.length,
                  itemBuilder: (ctx, i) {
                    final cent = s.centers[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16)),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFFFEEEE),
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                  child: const Icon(
                                      Icons.local_hospital_rounded,
                                      color: primary)),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(cent.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900))),
                              PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'edit') {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                CenterFormPage(center: cent)));
                                  }
                                  if (v == 'del') s.deleteCenter(cent);
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                      value: 'edit', child: Text('تعديل')),
                                  const PopupMenuItem(
                                      value: 'del', child: Text('حذف'))
                                ],
                              )
                            ]),
                            const SizedBox(height: 8),
                            Text('${cent.address} • ${cent.specialty}',
                                style: const TextStyle(
                                    color: muted, fontSize: 12)),
                          ]),
                    );
                  }),
        );
      },
    );
  }
}

class CenterFormPage extends StatefulWidget {
  final MedicalCenter? center;
  const CenterFormPage({super.key, this.center});
  @override
  State<CenterFormPage> createState() => _CenterFormPageState();
}

class _CenterFormPageState extends State<CenterFormPage> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController name, address, phone, specialty;
  @override
  void initState() {
    super.initState();
    final c = widget.center;
    name = TextEditingController(text: c?.name ?? '');
    address = TextEditingController(text: c?.address ?? '');
    phone = TextEditingController(text: c?.phone ?? '');
    specialty = TextEditingController(text: c?.specialty ?? '');
  }

  @override
  void dispose() {
    name.dispose();
    address.dispose();
    phone.dispose();
    specialty.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    final s = TabibekStore.instance;
    if (widget.center == null) {
      await s.addCenter(MedicalCenter(
          id: s.newId('C'),
          name: name.text.trim(),
          address: address.text.trim(),
          phone: phone.text.trim(),
          specialty: specialty.text.trim(),
          doctorRegistration: s.doctor.registration));
    } else {
      await s.updateCenter(MedicalCenter(
          id: widget.center!.id,
          name: name.text.trim(),
          address: address.text.trim(),
          phone: phone.text.trim(),
          specialty: specialty.text.trim(),
          doctorRegistration: s.doctor.registration,
          active: widget.center!.active));
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.center == null ? 'إضافة مركز' : 'تعديل المركز')),
      body: Form(
        key: formKey,
        child: ListView(padding: const EdgeInsets.all(18), children: [
          _i('اسم المركز', name),
          _i('العنوان', address, req: false),
          _i('الهاتف', phone, keyboard: TextInputType.phone, req: false),
          _i('التخصص', specialty, req: false),
          const SizedBox(height: 15),
          primaryButton(
              title: 'حفظ', icon: Icons.save_outlined, onPressed: _save),
        ]),
      ),
    );
  }

  Widget _i(String l, TextEditingController c,
      {bool req = true, TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        validator: (v) =>
            req && (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
        decoration: InputDecoration(labelText: l),
      ),
    );
  }
}

class InvitePage extends StatelessWidget {
  const InvitePage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = TabibekStore.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('دعوة مركز')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                const Icon(Icons.card_giftcard_rounded,
                    size: 60, color: orange),
                const SizedBox(height: 12),
                const Text('ادع مركز طبي واحصل على شهر مجاني',
                    style: TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 8),
                Text('كود الدعوة الخاص بك: ${s.doctor.registration}',
                    style: const TextStyle(
                        color: primary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                primaryButton(
                    title: 'نسخ كود الدعوة',
                    icon: Icons.copy,
                    color: orange,
                    onPressed: () => copyText(
                        context, s.doctor.registration, 'تم نسخ كود الدعوة ✅'))
              ])),
        ]),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ListTile(
            leading: const Icon(Icons.logout, color: primary),
            title: const Text('تسجيل خروج'),
            onTap: () async {
              await TabibekStore.instance.setLoggedIn(false);
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (_) => false);
            }),
        ListTile(
            leading: const Icon(Icons.delete_forever, color: primary),
            title: const Text('مسح كل البيانات'),
            onTap: () async {
              await TabibekStore.instance.initialize();
              await TabibekStore.instance.setLoggedIn(false);
              if (!context.mounted) return;
              showMessage(context, 'تم مسح البيانات');
            })
      ]),
    );
  }
}