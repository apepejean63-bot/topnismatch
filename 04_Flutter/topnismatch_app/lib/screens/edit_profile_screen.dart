import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'editar_bio_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _perfil;
  bool _isLoading = true;
  bool _subiendoFoto = false;
  final ImagePicker _picker = ImagePicker();

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
      setState(() {
        _perfil = perfil;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  double _calcularProgreso(Map<String, dynamic> perfil) {
    int campos = 0;
    if (perfil['bio'] != null && perfil['bio'].toString().isNotEmpty) campos++;
    if (perfil['ciudad'] != null && perfil['ciudad'].toString().isNotEmpty)
      campos++;
    if (perfil['intereses'] != null &&
        perfil['intereses'].toString().isNotEmpty)
      campos++;
    if (perfil['fotoPrincipalUrl'] != null) campos++;
    return campos / 4;
  }

  int _calcularEdad(String? fechaNacimiento) {
    if (fechaNacimiento == null) return 0;
    try {
      final nacimiento = DateTime.parse(fechaNacimiento);
      final hoy = DateTime.now();
      int edad = hoy.year - nacimiento.year;
      if (hoy.month < nacimiento.month ||
          (hoy.month == nacimiento.month && hoy.day < nacimiento.day))
        edad--;
      return edad;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _abrirGaleria() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image == null) return;
      setState(() => _isLoading = true);
      final archivo = File(image.path);
      final usuarioId = _perfil?['usuarioId'] ?? 0;
      final url = await StorageService.subirFoto(archivo, usuarioId);
      await _api.editarPerfil({'fotoPrincipalUrl': url});
      await _cargarPerfil();
    } catch (e) {
      if (mounted)
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Error al subir foto'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _abrirEditarBio() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditarBioScreen(bioActual: _perfil?['bio'] ?? ''),
      ),
    );
    if (result == true) await _cargarPerfil();
  }

  void _mostrarDialogoEdicion(String titulo, String valorActual) {
    final controller = TextEditingController(text: valorActual);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(titulo),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Ingresa $titulo',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                Map<String, dynamic> data = {};
                if (titulo == 'Sobre m\u00ED')
                  data['bio'] = controller.text.trim();
                if (titulo == 'Ciudad') data['ciudad'] = controller.text.trim();
                if (titulo == 'Profesi\u00F3n')
                  data['profesion'] = controller.text.trim();
                if (titulo == 'Educaci\u00F3n')
                  data['educacion'] = controller.text.trim();
                if (titulo == 'Idioma') data['idioma'] = controller.text.trim();
                if (data.isNotEmpty) await _api.editarPerfil(data);
                await _cargarPerfil();
              } catch (e) {
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error al guardar'),
                      backgroundColor: Colors.red,
                    ),
                  );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primary),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarSelectorOpciones(String titulo, List<String> opciones) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.only(bottom: 32),
                children: opciones
                    .map(
                      (op) => ListTile(
                        title: Text(op),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                        onTap: () async {
                          Navigator.pop(ctx);
                          try {
                            Map<String, dynamic> data = {};
                            if (titulo == 'Signo zodiacal')
                              data['signoZodiacal'] = op;
                            if (titulo == 'Mascotas') data['mascotas'] = op;
                            if (titulo == 'Alcohol') data['alcohol'] = op;
                            if (titulo == 'Tabaco') data['tabaco'] = op;
                            if (titulo == 'Ejercicio') data['ejercicio'] = op;
                            if (titulo == '\u00BFTienes hijos?')
                              data['tieneHijos'] = op;
                            if (titulo == '\u00BFQuieres hijos?')
                              data['quiereHijos'] = op;
                            if (titulo == 'Religi\u00F3n')
                              data['religion'] = op;
                            if (titulo == 'Educaci\u00F3n')
                              data['educacion'] = op;
                            if (titulo == 'Idioma') data['idioma'] = op;
                            if (titulo == '\u00BFQu\u00E9 busco?') {
                              final map = {
                                'Relaci\u00F3n seria': 'RELACION_SERIA',
                                'Amistad': 'AMISTAD',
                                'Algo casual': 'CASUAL',
                                'No s\u00E9 a\u00FAn': 'NO_SE',
                              };
                              data['objetivo'] = map[op] ?? op;
                              if (mounted)
                                setState(() {
                                  _perfil!['objetivo'] = data['objetivo'];
                                });
                            }
                            if (data.isNotEmpty) await _api.editarPerfil(data);
                            await _cargarPerfil();
                          } catch (e) {
                            if (mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Error al guardar'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                          }
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarIdiomasMultiples() {
    final idiomasDisponibles = [
      'Espa\u00F1ol',
      'Ingl\u00E9s',
      'Franc\u00E9s',
      'Portugu\u00E9s',
      'Alem\u00E1n',
      'Italiano',
      'Chino',
      'Otros',
    ];
    final seleccionados = (_perfil?['idioma'] as String? ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final temp = List<String>.from(seleccionados);
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Idiomas (m\u00E1x. 3)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...idiomasDisponibles.map(
                (idioma) => CheckboxListTile(
                  title: Text(idioma),
                  value: temp.contains(idioma),
                  activeColor: primary,
                  onChanged: (val) {
                    setModalState(() {
                      if (val == true && temp.length < 3)
                        temp.add(idioma);
                      else if (val == false)
                        temp.remove(idioma);
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await _api.editarPerfil({'idioma': temp.join(', ')});
                      await _cargarPerfil();
                    } catch (e) {
                      if (mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error al guardar'),
                            backgroundColor: Colors.red,
                          ),
                        );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text(
                    'Guardar',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarIntereses() {
    final interesesDisponibles = [
      '\u{1F3B5} M\u00FAsica',
      '\u{1F3AE} Gaming',
      '\u26BD F\u00FAtbol',
      '\u2708\uFE0F Viajes',
      '\u{1F355} Comida',
      '\u{1F4DA} Lectura',
      '\u{1F3A8} Arte',
      '\u{1F3CB}\uFE0F Gym',
      '\u{1F3AC} Cine',
      '\u{1F3A4} Karaoke',
      '\u{1F6B4} Ciclismo',
      '\u{1F9D8} Yoga',
    ];
    final seleccionados = (_perfil?['intereses'] as String? ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final temp = List<String>.from(seleccionados);
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, controller) => Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Mis intereses',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: interesesDisponibles.map((interes) {
                      final seleccionado = temp.contains(interes);
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            if (seleccionado)
                              temp.remove(interes);
                            else if (temp.length < 6)
                              temp.add(interes);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: seleccionado
                                ? primary.withOpacity(0.1)
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: seleccionado
                                  ? primary
                                  : Colors.grey.withOpacity(0.3),
                              width: seleccionado ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            interes,
                            style: TextStyle(
                              fontSize: 13,
                              color: seleccionado ? primary : Colors.grey,
                              fontWeight: seleccionado
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await _api.editarPerfil({'intereses': temp.join(', ')});
                      await _cargarPerfil();
                    } catch (e) {
                      if (mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error al guardar'),
                            backgroundColor: Colors.red,
                          ),
                        );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text(
                    'Guardar',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirDatePicker() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime(2010),
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: const ColorScheme.light(primary: primary)),
        child: child!,
      ),
    );
    if (fecha != null) {
      try {
        await _api.editarPerfil({'fechaNacimiento': fecha.toIso8601String()});
        await _cargarPerfil();
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al guardar'),
              backgroundColor: Colors.red,
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primary)),
      );

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
                onPressed: () =>
                    Navigator.pushNamed(context, '/create-profile'),
                style: ElevatedButton.styleFrom(backgroundColor: primary),
                child: const Text(
                  'Crear Perfil',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final perfil = _perfil!;
    final progreso = _calcularProgreso(perfil);
    final edad =
        perfil['edad'] ?? _calcularEdad(perfil['fechaNacimiento']?.toString());
    final intereses =
        (perfil['intereses'] as String?)
            ?.split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];

    String objetivoTexto = '';
    if (perfil['objetivo'] == 'RELACION_SERIA')
      objetivoTexto = 'Relaci\u00F3n seria';
    else if (perfil['objetivo'] == 'AMISTAD')
      objetivoTexto = 'Amistad';
    else if (perfil['objetivo'] == 'CASUAL')
      objetivoTexto = 'Algo casual';
    else if (perfil['objetivo'] == 'NO_SE')
      objetivoTexto = 'No s\u00E9 a\u00FAn';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primary, primaryOrange],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          onTap: _abrirGaleria,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: perfil['fotoPrincipalUrl'] != null
                                  ? Image.network(
                                      perfil['fotoPrincipalUrl'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _avatarPlaceholder(),
                                    )
                                  : _avatarPlaceholder(),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _abrirGaleria,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: primary,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      edad > 0
                          ? '${perfil['nombre']}, $edad'
                          : perfil['nombre'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Completado del perfil',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${(progreso * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progreso,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
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
                _buildCard(
                  icon: Icons.photo_library_outlined,
                  title: 'Fotos',
                  child: Column(
                    children: [
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        children: List.generate(6, (index) {
                          if (index == 0 &&
                              perfil['fotoPrincipalUrl'] != null) {
                            return GestureDetector(
                              onTap: _abrirGaleria,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  perfil['fotoPrincipalUrl'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _addPhotoCell(),
                                ),
                              ),
                            );
                          }
                          return GestureDetector(
                            onTap: _abrirGaleria,
                            child: _addPhotoCell(),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Agrega hasta 6 fotos para destacar tu perfil',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _abrirEditarBio,
                  child: _buildCard(
                    icon: Icons.person_outline,
                    title: 'Sobre m\u00ED',
                    trailing: GestureDetector(
                      onTap: _abrirEditarBio,
                      child: const Icon(Icons.edit, color: primary, size: 18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          perfil['bio'] ??
                              'Cu\u00E9ntale al mundo qui\u00E9n eres...',
                          style: TextStyle(
                            fontSize: 14,
                            color: perfil['bio'] != null
                                ? Colors.black87
                                : Colors.grey,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(perfil['bio'] ?? '').length}/300',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildCard(
                  icon: Icons.info_outline,
                  title: 'Datos b\u00E1sicos',
                  child: Column(
                    children: [
                      _basicRow(
                        Icons.cake,
                        'Edad',
                        edad > 0 ? '$edad a\u00F1os' : '-- a\u00F1os',
                        Colors.orange,
                        _abrirDatePicker,
                      ),
                      _basicRow(
                        Icons.work,
                        'Profesi\u00F3n',
                        perfil['profesion'] ?? '',
                        Colors.blue,
                        () => _mostrarDialogoEdicion(
                          'Profesi\u00F3n',
                          perfil['profesion'] ?? '',
                        ),
                      ),
                      _basicRow(
                        Icons.school,
                        'Educaci\u00F3n',
                        perfil['educacion'] ?? '',
                        Colors.purple,
                        () => _mostrarSelectorOpciones('Educaci\u00F3n', [
                          'Secundaria',
                          'T\u00E9cnico',
                          'Universidad',
                          'Posgrado',
                          'Doctorado',
                        ]),
                      ),
                      _basicRow(
                        Icons.language,
                        'Idioma',
                        perfil['idioma'] ?? '',
                        Colors.teal,
                        _mostrarIdiomasMultiples,
                      ),
                      _basicRow(
                        Icons.auto_awesome,
                        'Signo zodiacal',
                        perfil['signoZodiacal'] ?? '',
                        Colors.amber,
                        () => _mostrarSelectorOpciones('Signo zodiacal', [
                          'Aries',
                          'Tauro',
                          'G\u00E9minis',
                          'C\u00E1ncer',
                          'Leo',
                          'Virgo',
                          'Libra',
                          'Escorpio',
                          'Sagitario',
                          'Capricornio',
                          'Acuario',
                          'Piscis',
                        ]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildCard(
                  icon: Icons.search,
                  title: '\u00BFQu\u00E9 busco?',
                  child: _basicRow(
                    perfil['objetivo'] == 'RELACION_SERIA'
                        ? Icons.favorite
                        : perfil['objetivo'] == 'AMISTAD'
                        ? Icons.people
                        : perfil['objetivo'] == 'CASUAL'
                        ? Icons.local_fire_department
                        : Icons.help_outline,
                    '\u00BFQu\u00E9 busco?',
                    objetivoTexto,
                    Colors.red,
                    () => _mostrarSelectorOpciones('\u00BFQu\u00E9 busco?', [
                      'Relaci\u00F3n seria',
                      'Amistad',
                      'Algo casual',
                      'No s\u00E9 a\u00FAn',
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                _buildCard(
                  icon: Icons.favorite_outline,
                  title: 'Mis intereses',
                  child: intereses.isEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Agrega tus intereses',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _mostrarIntereses,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: primary,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add, size: 16, color: primary),
                                    SizedBox(width: 6),
                                    Text(
                                      'Agregar intereses',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ...intereses.map((i) => _interestChip(i)),
                                if (intereses.length < 6) _addChip(),
                              ],
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _mostrarIntereses,
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit, size: 16, color: primary),
                                  SizedBox(width: 4),
                                  Text(
                                    'Editar intereses',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 12),
                _buildCard(
                  icon: Icons.self_improvement,
                  title: 'Estilo de vida',
                  child: Column(
                    children: [
                      _lifestyleRow(Icons.pets, 'Mascotas', Colors.blue, [
                        'Perro',
                        'Gato',
                        'Ninguna',
                        'Varios',
                      ], perfil['mascotas']),
                      _lifestyleRow(Icons.local_bar, 'Alcohol', Colors.red, [
                        'Nunca',
                        'Socialmente',
                        'Frecuentemente',
                      ], perfil['alcohol']),
                      _lifestyleRow(
                        Icons.smoking_rooms,
                        'Tabaco',
                        Colors.grey,
                        ['No fumo', 'Ocasionalmente', 'Frecuentemente'],
                        perfil['tabaco'],
                      ),
                      _lifestyleRow(
                        Icons.fitness_center,
                        'Ejercicio',
                        Colors.orange,
                        [
                          'Nunca',
                          'A veces',
                          'Frecuentemente',
                          'Todos los d\u00EDas',
                        ],
                        perfil['ejercicio'],
                      ),
                      _lifestyleRow(
                        Icons.child_care,
                        '\u00BFTienes hijos?',
                        Colors.pink,
                        ['S\u00ED', 'No'],
                        perfil['tieneHijos'],
                      ),
                      _lifestyleRow(
                        Icons.baby_changing_station,
                        '\u00BFQuieres hijos?',
                        Colors.blue,
                        ['S\u00ED', 'No', 'Quiz\u00E1s'],
                        perfil['quiereHijos'],
                      ),
                      _lifestyleRow(
                        Icons.church,
                        'Religi\u00F3n',
                        Colors.amber,
                        [
                          'Cristiano',
                          'Cat\u00F3lico',
                          'Muslim',
                          'Jud\u00EDo',
                          'Budista',
                          'Otro',
                          'Ninguna',
                        ],
                        perfil['religion'],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildCard(
                  icon: Icons.link,
                  title: 'Redes sociales',
                  child: Column(
                    children: [
                      _socialRow(
                        FontAwesomeIcons.instagram,
                        const Color(0xFFE1306C),
                        'Instagram',
                        'Conectar',
                      ),
                      _socialRow(
                        FontAwesomeIcons.spotify,
                        const Color(0xFF1DB954),
                        'Spotify',
                        'Conectar',
                      ),
                      _socialRow(
                        FontAwesomeIcons.tiktok,
                        Colors.black,
                        'TikTok',
                        'Conectar',
                      ),
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
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.person, size: 50, color: Colors.grey),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _addPhotoCell() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: const Center(
        child: Icon(
          Icons.add_photo_alternate_outlined,
          color: Colors.grey,
          size: 28,
        ),
      ),
    );
  }

  Widget _basicRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: primary.withOpacity(0.1),
        highlightColor: primary.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Text(
                      value.isEmpty ? 'Agregar' : value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: value.isEmpty ? Colors.grey : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buscoChip(String label, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? primary.withOpacity(0.1) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? primary : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: selected ? primary : Colors.grey,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _interestChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _addChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add, size: 14, color: Colors.grey),
          SizedBox(width: 4),
          Text('Agregar', style: TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _lifestyleRow(
    IconData icon,
    String label,
    Color iconColor,
    List<String> opciones,
    String? valorActual,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _mostrarSelectorOpciones(label, opciones),
        borderRadius: BorderRadius.circular(12),
        splashColor: primary.withOpacity(0.1),
        highlightColor: primary.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
              Text(
                valorActual != null && valorActual.isNotEmpty
                    ? valorActual
                    : 'Agregar',
                style: TextStyle(
                  fontSize: 13,
                  color: valorActual != null && valorActual.isNotEmpty
                      ? Colors.black87
                      : Colors.grey,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialRow(
    IconData icon,
    Color iconColor,
    String label,
    String action,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conectar $label pr\u00F3ximamente'),
            backgroundColor: primary,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                FaIcon(icon, color: iconColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
            Text(
              action,
              style: const TextStyle(
                fontSize: 13,
                color: primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
