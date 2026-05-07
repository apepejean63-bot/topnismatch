import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_service.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _bioController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _interesesController = TextEditingController();
  final ApiService _api = ApiService();
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  String _generoBuscado = 'FEMENINO';
  double _edadMin = 18;
  double _edadMax = 40;
  double _distancia = 30;
  File? _selectedImage;
  final _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _bioController.dispose();
    _ciudadController.dispose();
    _interesesController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFoto() async {
    final picker = ImagePicker();
    try {
      final XFile? img = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (img != null) setState(() => _selectedImage = File(img.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<String?> _subirFoto() async {
    if (_selectedImage == null) return null;
    setState(() => _isUploadingPhoto = true);
    try {
      final fileName = 'foto_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await _selectedImage!.readAsBytes();
      await _supabase.storage.from('fotos').uploadBinary(
        fileName, bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );
      final url = _supabase.storage.from('fotos').getPublicUrl(fileName);
      setState(() => _isUploadingPhoto = false);
      return url;
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      return null;
    }
  }

  Future<void> _crearPerfil() async {
    setState(() => _isLoading = true);
    try {
      String? fotoUrl;
      if (_selectedImage != null) fotoUrl = await _subirFoto();
      await _api.crearPerfil({
        'bio': _bioController.text.trim(),
        'ciudad': _ciudadController.text.trim(),
        'intereses': _interesesController.text.trim(),
        'edadMinBuscada': _edadMin.toInt(),
        'edadMaxBuscada': _edadMax.toInt(),
        'distanciaMaxKm': _distancia.toInt(),
        'generoBuscado': _generoBuscado,
        if (fotoUrl != null) 'fotoPrincipalUrl': fotoUrl,
      });
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al crear perfil')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF4458),
        title: const Text('Crear Perfil',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFFFF4458),
                    backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
                    child: _selectedImage == null ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _seleccionarFoto,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4458)),
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text('Agregar foto', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _bioController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Bio',
                hintText: 'Cuentanos sobre ti...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF4458)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ciudadController,
              decoration: InputDecoration(
                labelText: 'Ciudad',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF4458)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _interesesController,
              decoration: InputDecoration(
                labelText: 'Intereses',
                hintText: 'musica, viajes, deporte...',
                prefixIcon: const Icon(Icons.favorite),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF4458)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Busco:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _generoBuscado,
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: const [
                DropdownMenuItem(value: 'MASCULINO', child: Text('Hombres')),
                DropdownMenuItem(value: 'FEMENINO', child: Text('Mujeres')),
                DropdownMenuItem(value: 'NO_BINARIO', child: Text('No binario')),
              ],
              onChanged: (value) => setState(() => _generoBuscado = value!),
            ),
            const SizedBox(height: 24),
            Text('Rango de edad: ${_edadMin.toInt()} - ${_edadMax.toInt()} anos',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            RangeSlider(
              values: RangeValues(_edadMin, _edadMax),
              min: 18, max: 99, divisions: 81,
              activeColor: const Color(0xFFFF4458),
              labels: RangeLabels(_edadMin.toInt().toString(), _edadMax.toInt().toString()),
              onChanged: (values) => setState(() { _edadMin = values.start; _edadMax = values.end; }),
            ),
            const SizedBox(height: 16),
            Text('Distancia maxima: ${_distancia.toInt()} km',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Slider(
              value: _distancia, min: 1, max: 500, divisions: 499,
              activeColor: const Color(0xFFFF4458),
              label: '${_distancia.toInt()} km',
              onChanged: (value) => setState(() => _distancia = value),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _crearPerfil,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4458),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading || _isUploadingPhoto
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Crear Perfil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
