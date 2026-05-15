import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/api_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _perfil;
  bool _isLoading = true;

  static const Color primary = Color(0xFFFF4458);
  static const Color primaryOrange = Color(0xFFFF8C00);

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    try {
      final perfil = await _api.getMiPerfil();
      setState(() { _perfil = perfil; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  int _calcularEdad(String? fechaNacimiento) {
    if (fechaNacimiento == null) return 0;
    try {
      final nacimiento = DateTime.parse(fechaNacimiento);
      final hoy = DateTime.now();
      int edad = hoy.year - nacimiento.year;
      if (hoy.month < nacimiento.month || (hoy.month == nacimiento.month && hoy.day < nacimiento.day)) edad--;
      return edad;
    } catch (e) { return 0; }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: primary)));

    if (_perfil == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_outline, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No tienes perfil a\u00FAn'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/create-profile'),
                style: ElevatedButton.styleFrom(backgroundColor: primary),
                child: const Text('Crear Perfil', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final perfil = _perfil!;
    final edad = perfil['edad'] ?? _calcularEdad(perfil['fechaNacimiento']?.toString());
    final intereses = (perfil['intereses'] as String?)?.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ?? [];

    String objetivoTexto = '';
    if (perfil['objetivo'] == 'RELACION_SERIA') objetivoTexto = 'Relaci\u00F3n seria';
    else if (perfil['objetivo'] == 'AMISTAD') objetivoTexto = 'Amistad';
    else if (perfil['objetivo'] == 'CASUAL') objetivoTexto = 'Algo casual';
    else if (perfil['objetivo'] == 'NO_SE') objetivoTexto = 'No s\u00E9 a\u00FAn';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [primary, primaryOrange]),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                              _cargarPerfil();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                              child: const Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.white, size: 14),
                                  SizedBox(width: 6),
                                  Text('Editar perfil', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12)],
                          ),
                          child: ClipOval(
                            child: perfil['fotoPrincipalUrl'] != null
                                ? Image.network(perfil['fotoPrincipalUrl'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => _avatarPlaceholder())
                                : _avatarPlaceholder(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      edad > 0 ? '${perfil['nombre']}, $edad' : perfil['nombre'],
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (perfil['bio'] != null && perfil['bio'].toString().isNotEmpty) ...[
                  _buildCard(
                    icon: Icons.person_outline,
                    title: 'Sobre m\u00ED',
                    child: Text(perfil['bio'], style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5)),
                  ),
                  const SizedBox(height: 12),
                ],
                _buildCard(
                  icon: Icons.info_outline,
                  title: 'Informaci\u00F3n personal',
                  child: Column(
                    children: [
                      if (edad > 0) _infoRow(Icons.cake, 'Edad', '$edad a\u00F1os', Colors.orange),
                      if (perfil['profesion'] != null && perfil['profesion'].toString().isNotEmpty) _infoRow(Icons.work, 'Profesi\u00F3n', perfil['profesion'], Colors.blue),
                      if (perfil['educacion'] != null && perfil['educacion'].toString().isNotEmpty) _infoRow(Icons.school, 'Educaci\u00F3n', perfil['educacion'], Colors.purple),
                      if (perfil['idioma'] != null && perfil['idioma'].toString().isNotEmpty) _infoRow(Icons.language, 'Idioma', perfil['idioma'], Colors.teal),
                      if (perfil['signoZodiacal'] != null && perfil['signoZodiacal'].toString().isNotEmpty) _infoRow(Icons.auto_awesome, 'Signo zodiacal', perfil['signoZodiacal'], Colors.amber),
                      if (edad == 0 && perfil['profesion'] == null && perfil['educacion'] == null && perfil['idioma'] == null && perfil['signoZodiacal'] == null)
                        const Text('Completa tus datos b\u00E1sicos', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (intereses.isNotEmpty) ...[
                  _buildCard(
                    icon: Icons.favorite_outline,
                    title: 'Mis intereses',
                    child: Wrap(spacing: 8, runSpacing: 8, children: intereses.map((i) => _interestChip(i)).toList()),
                  ),
                  const SizedBox(height: 12),
                ],
                _buildCard(
                  icon: Icons.self_improvement,
                  title: 'Estilo de vida',
                  child: Column(
                    children: [
                      if (perfil['mascotas'] != null && perfil['mascotas'].toString().isNotEmpty) _infoRow(Icons.pets, 'Mascotas', perfil['mascotas'], Colors.blue),
                      if (perfil['alcohol'] != null && perfil['alcohol'].toString().isNotEmpty) _infoRow(Icons.local_bar, 'Alcohol', perfil['alcohol'], Colors.red),
                      if (perfil['tabaco'] != null && perfil['tabaco'].toString().isNotEmpty) _infoRow(Icons.smoking_rooms, 'Tabaco', perfil['tabaco'], Colors.grey),
                      if (perfil['ejercicio'] != null && perfil['ejercicio'].toString().isNotEmpty) _infoRow(Icons.fitness_center, 'Ejercicio', perfil['ejercicio'], Colors.orange),
                      if (perfil['tieneHijos'] != null && perfil['tieneHijos'].toString().isNotEmpty) _infoRow(Icons.child_care, '\u00BFTienes hijos?', perfil['tieneHijos'], Colors.pink),
                      if (perfil['quiereHijos'] != null && perfil['quiereHijos'].toString().isNotEmpty) _infoRow(Icons.baby_changing_station, '\u00BFQuieres hijos?', perfil['quiereHijos'], Colors.blue),
                      if (perfil['religion'] != null && perfil['religion'].toString().isNotEmpty) _infoRow(Icons.church, 'Religi\u00F3n', perfil['religion'], Colors.amber),
                      if (perfil['mascotas'] == null && perfil['alcohol'] == null && perfil['tabaco'] == null && perfil['ejercicio'] == null)
                        const Text('Completa tu estilo de vida', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarPlaceholder() {
    return Container(color: Colors.grey[300], child: const Center(child: Icon(Icons.person, size: 50, color: Colors.grey)));
  }

  Widget _buildCard({required IconData icon, required String title, required Widget child}) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: primary, size: 18), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))]),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _interestChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: primary.withOpacity(0.3))),
      child: Text(label, style: const TextStyle(fontSize: 13, color: primary, fontWeight: FontWeight.w500)),
    );
  }
}