import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vodomont Pantic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB71C1C)),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) return const HomeScreen();
        return const LoginScreen();
      },
    );
  }
}

Widget _buildLogo() {
  return Container(
    width: 130,
    height: 130,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4))],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.asset('assets/logo.png', fit: BoxFit.cover),
    ),
  );
}

Widget _buildCard({required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: const Color(0xFFEDE7F6),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 4))],
    ),
    child: child,
  );
}

Widget _buildTextField({required TextEditingController controller, required String label, bool obscure = false, List<String>? autofillHints}) {
  return TextField(
    controller: controller,
    obscureText: obscure,
    autofillHints: autofillHints,
    decoration: InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFB71C1C))),
    ),
  );
}

Widget _buildButton({required String label, required VoidCallback? onPressed, bool loading = false}) {
  return SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFD4A017), width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: loading
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    ),
  );
}

Widget _buildKomentar(Map k, String trenutniUid, bool isAdmin) {
  final bool jeAdmin = k['isAdmin'] == true;
  final bool jaMSaDesne = (!isAdmin && !jeAdmin);
  final alignment = jeAdmin ? CrossAxisAlignment.start : CrossAxisAlignment.end;
  final bubbleColor = jeAdmin ? const Color(0xFFFFF9E6) : const Color(0xFFEDE7F6);
  final borderColor = jeAdmin ? const Color(0xFFD4A017) : const Color(0xFF9E9E9E);

  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Column(
      crossAxisAlignment: alignment,
      children: [
        Row(
          mainAxisAlignment: jeAdmin ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: [
            if (!jeAdmin) const Spacer(),
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(k['ime'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB71C1C), fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(k['tekst'] ?? '', style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      k['vreme'] != null ? _formatVreme(k['vreme']) : '',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            if (jeAdmin) const Spacer(),
          ],
        ),
      ],
    ),
  );
}

String _formatVreme(String iso) {
  try {
    final d = DateTime.parse(iso).toLocal();
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return '';
  }
}

// ===================== LOGIN =====================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _loading = false;
  String _error = '';

  Future<void> _login() async {
    setState(() { _loading = true; _error = ''; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() { _error = e.message ?? 'Greška pri prijavi'; });
    }
    setState(() { _loading = false; });
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() { _error = 'Unesite email za resetovanje lozinke'; });
      return;
    }
    await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());
    setState(() { _error = 'Email za resetovanje je poslat!'; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                _buildLogo(),
                const SizedBox(height: 32),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Prijava', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      _buildTextField(controller: _emailController, label: 'Email', autofillHints: [AutofillHints.email]),
                      const SizedBox(height: 14),
                      _buildTextField(controller: _passwordController, label: 'Lozinka', obscure: !_showPassword),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => setState(() { _showPassword = !_showPassword; }),
                        child: const Text('Prikaži lozinku', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      if (_error.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(_error, style: const TextStyle(color: Colors.red)),
                      ],
                      const SizedBox(height: 20),
                      _buildButton(label: 'Prijavi se', onPressed: _loading ? null : _login, loading: _loading),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                        child: const Text('Nemaš nalog? Registruj se', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _resetPassword,
                        child: const Text('Zaboravljena lozinka', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===================== REGISTRACIJA =====================
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _imeController = TextEditingController();
  final _prezimeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _showPassword = false;
  bool _loading = false;
  String _error = '';

  Future<void> _register() async {
    if (_passwordController.text != _confirmController.text) {
      setState(() { _error = 'Lozinke se ne poklapaju'; });
      return;
    }
    setState(() { _loading = true; _error = ''; });
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await FirebaseFirestore.instance.collection('korisnici').doc(cred.user!.uid).set({
        'ime': _imeController.text.trim(),
        'prezime': _prezimeController.text.trim(),
        'email': _emailController.text.trim(),
        'isAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() { _error = e.message ?? 'Greška pri registraciji'; });
    }
    setState(() { _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                _buildLogo(),
                const SizedBox(height: 32),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Registracija', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      _buildTextField(controller: _imeController, label: 'Ime'),
                      const SizedBox(height: 14),
                      _buildTextField(controller: _prezimeController, label: 'Prezime'),
                      const SizedBox(height: 14),
                      _buildTextField(controller: _emailController, label: 'Email'),
                      const SizedBox(height: 14),
                      _buildTextField(controller: _passwordController, label: 'Lozinka', obscure: !_showPassword),
                      const SizedBox(height: 14),
                      _buildTextField(controller: _confirmController, label: 'Potvrda lozinke', obscure: !_showPassword),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => setState(() { _showPassword = !_showPassword; }),
                        child: const Text('Prikaži lozinku', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      if (_error.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(_error, style: const TextStyle(color: Colors.red)),
                      ],
                      const SizedBox(height: 20),
                      _buildButton(label: 'Kreiraj nalog', onPressed: _loading ? null : _register, loading: _loading),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===================== HOME =====================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  Map<String, dynamic>? _userData;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final doc = await FirebaseFirestore.instance.collection('korisnici').doc(user.uid).get();
    setState(() {
      _userData = doc.data();
      _isAdmin = _userData?['isAdmin'] ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_userData == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return _isAdmin ? AdminScreen(userData: _userData!) : WorkerScreen(userData: _userData!);
  }
}

// ===================== RADNIK =====================
class WorkerScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const WorkerScreen({super.key, required this.userData});
  @override
  State<WorkerScreen> createState() => _WorkerScreenState();
}

class _WorkerScreenState extends State<WorkerScreen> {
  final _lokacijaController = TextEditingController();
  final _opisController = TextEditingController();
  final _komentarControllers = <String, TextEditingController>{};
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;

  String get _ime => '${widget.userData['ime']} ${widget.userData['prezime']}';

  TextEditingController _getKomentarController(String id) {
    _komentarControllers.putIfAbsent(id, () => TextEditingController());
    return _komentarControllers[id]!;
  }

  Future<void> _posaljiIzvestaj() async {
    if (_lokacijaController.text.trim().isEmpty || _opisController.text.trim().isEmpty) return;
    setState(() { _loading = true; });
    final user = FirebaseAuth.instance.currentUser!;
    await FirebaseFirestore.instance.collection('izvestaji').add({
      'uid': user.uid,
      'ime': _ime,
      'lokacija': _lokacijaController.text.trim(),
      'opis': _opisController.text.trim(),
      'datum': Timestamp.fromDate(DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)),
      'createdAt': FieldValue.serverTimestamp(),
      'komentari': [],
    });
    _lokacijaController.clear();
    _opisController.clear();
    setState(() { _loading = false; });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Izveštaj poslat')));
  }

  Future<void> _posaljiOdgovor(String izvestajId) async {
    final controller = _getKomentarController(izvestajId);
    if (controller.text.trim().isEmpty) return;
    final user = FirebaseAuth.instance.currentUser!;
    final doc = await FirebaseFirestore.instance.collection('korisnici').doc(user.uid).get();
    final ime = '${doc['ime']} ${doc['prezime']}';
    await FirebaseFirestore.instance.collection('izvestaji').doc(izvestajId).update({
      'komentari': FieldValue.arrayUnion([{
        'ime': ime,
        'tekst': controller.text.trim(),
        'vreme': DateTime.now().toIso8601String(),
        'isAdmin': false,
      }])
    });
    controller.clear();
  }

  String _formatDatum(Timestamp t) {
    final d = t.toDate();
    const meseci = ['jan', 'feb', 'mar', 'apr', 'maj', 'jun', 'jul', 'avg', 'sep', 'okt', 'nov', 'dec'];
    return '${d.day}. ${meseci[d.month - 1]} ${d.year}';
  }

  void _showChangePassword(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Promeni lozinku'),
        content: TextField(controller: controller, obscureText: true, decoration: const InputDecoration(labelText: 'Nova lozinka')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Otkaži')),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.currentUser!.updatePassword(controller.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Sačuvaj'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text('Dobrodošao, $_ime', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFB71C1C))),
                const SizedBox(height: 16),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Novi izveštaj', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Datum',
                                filled: true,
                                fillColor: Colors.white,
                                hintText: '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) setState(() { _selectedDate = picked; });
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFD4A017)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Icon(Icons.calendar_today),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(controller: _lokacijaController, label: 'Lokacija'),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _opisController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Opis izveštaja',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildButton(label: 'Pošalji izveštaj', onPressed: _loading ? null : _posaljiIzvestaj, loading: _loading),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => _showChangePassword(context),
                            child: const Text('Promeni lozinku', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                          ),
                          TextButton(
                            onPressed: () => FirebaseAuth.instance.signOut(),
                            child: const Text('Odjavi se', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Text('Moji izveštaji', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('izvestaji')
                      .where('uid', isEqualTo: uid)
                      .orderBy('datum', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) return const Text('Nema izveštaja');
                    return Column(
                      children: docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final komentari = (data['komentari'] as List?) ?? [];
                        final controller = _getKomentarController(doc.id);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(data['ime'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB71C1C))),
                                  Text(data['datum'] != null ? _formatDatum(data['datum']) : ''),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(children: [
                                const Text('Lokacija  ', style: TextStyle(fontWeight: FontWeight.bold)),
                                Expanded(child: Text(data['lokacija'] ?? '')),
                              ]),
                              const SizedBox(height: 8),
                              const Text('Opis', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(data['opis'] ?? ''),
                              if (komentari.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Text('Komentari', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB71C1C))),
                                ...komentari.map((k) => _buildKomentar(k, uid, false)),
                              ],
                              const SizedBox(height: 12),
                              TextField(
                                controller: controller,
                                decoration: InputDecoration(
                                  hintText: 'Odgovori na komentar',
                                  filled: true,
                                  fillColor: const Color(0xFFF5F5F5),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                onPressed: () => _posaljiOdgovor(doc.id),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFD4A017)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                child: const Text('Pošalji odgovor'),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===================== ADMIN =====================
class AdminScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const AdminScreen({super.key, required this.userData});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String? _selectedUid;
  DateTime? _selectedDate;
  final _komentarControllers = <String, TextEditingController>{};

  String get _ime => '${widget.userData['ime']} ${widget.userData['prezime']}';

  TextEditingController _getKomentarController(String id) {
    _komentarControllers.putIfAbsent(id, () => TextEditingController());
    return _komentarControllers[id]!;
  }

  String _formatDatum(Timestamp t) {
    final d = t.toDate();
    const meseci = ['jan', 'feb', 'mar', 'apr', 'maj', 'jun', 'jul', 'avg', 'sep', 'okt', 'nov', 'dec'];
    return '${d.day}. ${meseci[d.month - 1]} ${d.year}';
  }

  Future<void> _posaljiKomentar(String izvestajId) async {
    final controller = _getKomentarController(izvestajId);
    if (controller.text.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('izvestaji').doc(izvestajId).update({
      'komentari': FieldValue.arrayUnion([{
        'ime': _ime,
        'tekst': controller.text.trim(),
        'vreme': DateTime.now().toIso8601String(),
        'isAdmin': true,
      }])
    });
    controller.clear();
  }

  Stream<QuerySnapshot> _buildQuery() {
    Query query = FirebaseFirestore.instance.collection('izvestaji');
    if (_selectedUid != null) {
      query = query.where('uid', isEqualTo: _selectedUid);
    }
    if (_selectedDate != null) {
      final start = Timestamp.fromDate(DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 0, 0, 0));
      final end = Timestamp.fromDate(DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 23, 59, 59));
      query = query.where('datum', isGreaterThanOrEqualTo: start).where('datum', isLessThanOrEqualTo: end);
    }
    query = query.orderBy('datum', descending: true);
    return query.snapshots();
  }

  void _showChangePassword(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Promeni lozinku'),
        content: TextField(controller: controller, obscureText: true, decoration: const InputDecoration(labelText: 'Nova lozinka')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Otkaži')),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.currentUser!.updatePassword(controller.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Sačuvaj'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(_ime, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFB71C1C))),
                const SizedBox(height: 16),
                _buildCard(
                  child: Column(
                    children: [
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('korisnici').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const CircularProgressIndicator();
                          final korisnici = snapshot.data!.docs.where((d) => !(d.data() as Map)['isAdmin']).toList();
                          return Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedUid,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  hint: const Text('Izaberi radnika'),
                                  items: korisnici.map((d) {
                                    final data = d.data() as Map<String, dynamic>;
                                    return DropdownMenuItem(
                                      value: d.id,
                                      child: Text('${data['ime']} ${data['prezime']}'),
                                    );
                                  }).toList(),
                                  onChanged: (v) => setState(() { _selectedUid = v; }),
                                ),
                              ),
                              if (_selectedUid != null) ...[
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () => setState(() { _selectedUid = null; }),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFD4A017)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Icon(Icons.close),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              readOnly: true,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                hintText: _selectedDate == null
                                    ? 'Datum'
                                    : '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) setState(() { _selectedDate = picked; });
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFD4A017)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Icon(Icons.calendar_today),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => setState(() { _selectedDate = null; }),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFD4A017)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => _showChangePassword(context),
                            child: const Text('Promeni lozinku', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                          ),
                          TextButton(
                            onPressed: () => FirebaseAuth.instance.signOut(),
                            child: const Text('Odjavi se', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                StreamBuilder<QuerySnapshot>(
                  stream: _buildQuery(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) return const Text('Nema izveštaja');
                    return Column(
                      children: docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final komentari = (data['komentari'] as List?) ?? [];
                        final controller = _getKomentarController(doc.id);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(data['ime'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB71C1C))),
                                  Text(data['datum'] != null ? _formatDatum(data['datum']) : ''),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(children: [
                                const Text('Lokacija  ', style: TextStyle(fontWeight: FontWeight.bold)),
                                Expanded(child: Text(data['lokacija'] ?? '')),
                              ]),
                              const SizedBox(height: 8),
                              const Text('Opis', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(data['opis'] ?? ''),
                              if (komentari.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Text('Komentari', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB71C1C))),
                                ...komentari.map((k) => _buildKomentar(k, uid, true)),
                              ],
                              const SizedBox(height: 12),
                              TextField(
                                controller: controller,
                                decoration: InputDecoration(
                                  hintText: 'Dodaj novi komentar',
                                  filled: true,
                                  fillColor: const Color(0xFFF5F5F5),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                onPressed: () => _posaljiKomentar(doc.id),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFD4A017)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                child: const Text('Sačuvaj komentar'),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}