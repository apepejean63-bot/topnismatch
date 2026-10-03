import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

enum _EstadoUbicacion {
  pendiente,
  solicitando,
  lista,
  rechazada,
  rechazadaSiempre,
  servicioApagado,
  error,
}

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _interesesController = TextEditingController();
  final ApiService _api = ApiService();
  bool _isLoading = false;
  String _generoBuscado = 'FEMENINO';
  double _edadMin = 18;
  double _edadMax = 40;
  double _distancia = 30;
  File? _selectedImage;

  _EstadoUbicacion _estadoUbicacion = _EstadoUbicacion.pendiente;
  Position? _posicion;
  String? _ciudadDetectada;

  static const List<String> _palabrasProhibidas = [
    'telegram', 'whatsapp', 'onlyfans', 'sexo', 'dinero',
    'instagram.com', 't.me', 'http://', 'https://', 'www.',
    'signal', 'snapchat',
  ];

  @override
  void dispose() {
    _bioController.dispose();
    _interesesController.dispose();
    super.dispose();
  }

  String? _validarBio(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.trim().length > 300) return 'M\u00E1ximo 300 caracteres';
    final bioLower = value.toLowerCase();
    for (final palabra in _palabrasProhibidas) {
      if (bioLower.contains(palabra)) return 'La bio contiene contenido no permitido';
    }
    return null;
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

  // Arma un nombre de ubicacion legible a partir de un Placemark, ignorando
  // componentes nulos, vacios o repetidos. No asume que 'locality' siempre
  // sea una comuna: usa los valores tal como los devuelve el geocoder.
  String? _construirNombreUbicacion(Placemark placemark) {
    final candidatos = <String?>[
      placemark.locality,
      placemark.subAdministrativeArea,
      placemark.administrativeArea,
    ];

    String? principal;
    for (final candidato in candidatos) {
      if (candidato != null && candidato.trim().isNotEmpty) {
        principal = candidato.trim();
        break;
      }
    }

    final pais = placemark.country?.trim();

    final partes = <String>[];
    if (principal != null && principal.isNotEmpty) partes.add(principal);
    if (pais != null && pais.isNotEmpty && pais != principal) partes.add(pais);

    if (partes.isEmpty) return null;
    return partes.join(', ');
  }

  // Siempre vuelve a comprobar servicio -> permiso -> posicion -> geocoding
  // desde cero. No asume que un "Reintentar" tras volver de Configuracion
  // ya solucionÃ³ nada.
  Future<void> _solicitarUbicacion() async {
    if (_estadoUbicacion == _EstadoUbicacion.solicitando) return;

    setState(() {
      _estadoUbicacion = _EstadoUbicacion.solicitando;
      _posicion = null;
      _ciudadDetectada = null;
    });

    try {
      final servicioActivado = await Geolocator.isLocationServiceEnabled();
      if (!servicioActivado) {
        if (mounted) setState(() => _estadoUbicacion = _EstadoUbicacion.servicioApagado);
        return;
      }

      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }

      if (permiso == LocationPermission.deniedForever) {
        if (mounted) setState(() => _estadoUbicacion = _EstadoUbicacion.rechazadaSiempre);
        return;
      }

      if (permiso == LocationPermission.denied) {
        if (mounted) setState(() => _estadoUbicacion = _EstadoUbicacion.rechazada);
        return;
      }

      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 10));

      // La Position es el dato critico. Si el reverse geocoding falla,
      // igualmente consideramos la ubicacion "lista" y no bloqueamos
      // la creacion del perfil; _ciudadDetectada simplemente queda null.
      String? nombreUbicacion;
      try {
        final geocoder = Geocoding();
        final placemarks = await geocoder.placemarkFromCoordinates(
          posicion.latitude,
          posicion.longitude,
        ).timeout(const Duration(seconds: 10));
        if (placemarks.isNotEmpty) {
          nombreUbicacion = _construirNombreUbicacion(placemarks.first);
        }
      } catch (_) {
        nombreUbicacion = null;
      }

      if (!mounted) return;
      setState(() {
        _posicion = posicion;
        _ciudadDetectada = nombreUbicacion;
        _estadoUbicacion = _EstadoUbicacion.lista;
      });
    } on TimeoutException {
      if (mounted) setState(() => _estadoUbicacion = _EstadoUbicacion.error);
    } catch (e) {
      if (mounted) setState(() => _estadoUbicacion = _EstadoUbicacion.error);
    }
  }

  Future<void> _crearPerfil() async {
    if (!_formKey.currentState!.validate()) return;

    if (_posicion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Necesitamos tu ubicaci\u00F3n para crear tu perfil'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? fotoUrl;
      if (_selectedImage != null) {
        final perfil = await _api.getMiPerfil().catchError((_) => <String, dynamic>{});
        final usuarioId = perfil['usuarioId'] ?? 0;
        fotoUrl = await StorageService.subirFoto(_selectedImage!, usuarioId);
      }

      await _api.crearPerfil({
        'bio': _bioController.text.trim(),
        'ciudad': _ciudadDetectada,
        'intereses': _interesesController.text.trim(),
        'edadMinBuscada': _edadMin.toInt(),
        'edadMaxBuscada': _edadMax.toInt(),
        'distanciaMaxKm': _distancia.toInt(),
        'generoBuscado': _generoBuscado,
        'latitud': _posicion!.latitude,
        'longitud': _posicion!.longitude,
        if (fotoUrl != null) 'fotoPrincipalUrl': fotoUrl,
      });

      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Widget _buildBannerUbicacion() {
    IconData icono;
    Color color;
    String titulo;
    String? textoBoton;
    VoidCallback? accionBoton;

    switch (_estadoUbicacion) {
      case _EstadoUbicacion.pendiente:
        icono = Icons.location_on_outlined;
        color = Colors.blueGrey;
        titulo = 'Necesitamos tu ubicaci\u00F3n para mostrarte personas cercanas';
        textoBoton = 'Permitir ubicaci\u00F3n';
        accionBoton = _solicitarUbicacion;
        break;
      case _EstadoUbicacion.solicitando:
        icono = Icons.location_searching;
        color = Colors.blueGrey;
        titulo = 'Obteniendo tu ubicaci\u00F3n...';
        textoBoton = null;
        accionBoton = null;
        break;
      case _EstadoUbicacion.lista:
        icono = Icons.check_circle;
        color = Colors.green;
        titulo = _ciudadDetectada != null
            ? '\u{1F4CD} $_ciudadDetectada'
            : 'Ubicaci\u00F3n lista \u2713';
        textoBoton = null;
        accionBoton = null;
        break;
      case _EstadoUbicacion.rechazada:
        icono = Icons.location_off;
        color = Colors.orange;
        titulo = 'Sin ubicaci\u00F3n no podr\u00E1s usar Descubrir';
        textoBoton = 'Reintentar';
        accionBoton = _solicitarUbicacion;
        break;
      case _EstadoUbicacion.rechazadaSiempre:
        icono = Icons.location_off;
        color = Colors.red;
        titulo = 'Habilita el permiso de ubicaci\u00F3n en Configuraci\u00F3n';
        textoBoton = 'Abrir configuraci\u00F3n';
        accionBoton = () async {
          await Geolocator.openAppSettings();
        };
        break;
      case _EstadoUbicacion.servicioApagado:
        icono = Icons.location_disabled;
        color = Colors.red;
        titulo = 'Activa la ubicaci\u00F3n de tu tel\u00E9fono';
        textoBoton = 'Activar ubicaci\u00F3n';
        accionBoton = () async {
          await Geolocator.openLocationSettings();
        };
        break;
      case _EstadoUbicacion.error:
        icono = Icons.error_outline;
        color = Colors.red;
        titulo = 'No pudimos obtener tu ubicaci\u00F3n';
        textoBoton = 'Reintentar';
        accionBoton = _solicitarUbicacion;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icono, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              titulo,
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          if (textoBoton != null)
            TextButton(
              onPressed: accionBoton,
              child: Text(textoBoton, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ),
          if (_estadoUbicacion == _EstadoUbicacion.solicitando)
            SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            ),
        ],
      ),
    );
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
        child: Form(
          key: _formKey,
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
                      child: _selectedImage == null
                          ? const Icon(Icons.person, size: 60, color: Colors.white)
                          : null,
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

              _buildBannerUbicacion(),

              // Bio
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                maxLength: 300,
                validator: _validarBio,
                decoration: _inputDecoration('Bio', null).copyWith(
                  hintText: 'Cu\u00E9ntanos sobre ti...',
                  labelText: 'Bio',
                ),
              ),
              const SizedBox(height: 16),

              // Intereses
              TextFormField(
                controller: _interesesController,
                decoration: _inputDecoration('Intereses (ej: m\u00FAsica, viajes)', Icons.favorite),
              ),
              const SizedBox(height: 24),

              const Text('Busco:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _generoBuscado,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'MASCULINO', child: Text('Hombres')),
                  DropdownMenuItem(value: 'FEMENINO', child: Text('Mujeres')),
                  DropdownMenuItem(value: 'NO_BINARIO', child: Text('No binario')),
                ],
                onChanged: (value) => setState(() => _generoBuscado = value!),
              ),
              const SizedBox(height: 24),

              Text(
                'Rango de edad: ${_edadMin.toInt()} - ${_edadMax.toInt()} a\u00F1os',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              RangeSlider(
                values: RangeValues(_edadMin, _edadMax),
                min: 18, max: 99, divisions: 81,
                activeColor: const Color(0xFFFF4458),
                labels: RangeLabels(_edadMin.toInt().toString(), _edadMax.toInt().toString()),
                onChanged: (values) => setState(() {
                  _edadMin = values.start;
                  _edadMax = values.end;
                }),
              ),
              const SizedBox(height: 16),

              Text(
                'Distancia m\u00E1xima: ${_distancia.toInt()} km',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
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
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Crear Perfil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF4458)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}