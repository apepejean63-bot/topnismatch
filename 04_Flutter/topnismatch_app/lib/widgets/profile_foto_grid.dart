import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';

class ProfileFotoGrid extends StatelessWidget {
  final Map<String, dynamic> perfil;
  final bool isLoading;
  final VoidCallback onFotoActualizada;
  final Function(bool) setLoading;

  const ProfileFotoGrid({
    super.key,
    required this.perfil,
    required this.isLoading,
    required this.onFotoActualizada,
    required this.setLoading,
  });

  static const Color primary = Color(0xFFFF4458);
  static final ApiService _api = ApiService();
  static final ImagePicker _picker = ImagePicker();

  Future<void> _abrirGaleriaSlot(BuildContext context, int orden) async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image == null) return;
      setLoading(true);
      final archivo = File(image.path);
      final usuarioId = perfil['usuarioId'] ?? 0;
      final url = await StorageService.subirFoto(archivo, usuarioId);
      if (orden == 1) {
        await _api.editarPerfil({'fotoPrincipalUrl': url});
      } else {
        await _api.agregarFoto(url, orden);
      }
      onFotoActualizada();
    } catch (e) {
      if (context.mounted)
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
      setLoading(false);
    }
  }

  void _eliminarFoto(BuildContext context, int orden) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Eliminar foto'),
        content: const Text('\u00BFQuieres eliminar esta foto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                setLoading(true);
                await _api.eliminarFoto(orden);
                onFotoActualizada();
              } catch (e) {
                if (context.mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
              } finally {
                setLoading(false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: List.generate(6, (index) {
            final orden = index + 1;
            String? fotoUrl;
            if (orden == 1) {
              fotoUrl = perfil['fotoPrincipalUrl'];
            } else {
              final fotos = perfil['fotos'] as List? ?? [];
              final fotoEnSlot = fotos.firstWhere(
                (f) => f['orden'] == orden,
                orElse: () => null,
              );
              fotoUrl = fotoEnSlot?['url'];
            }
            if (fotoUrl != null) {
              return GestureDetector(
                onTap: () => _abrirGaleriaSlot(context, orden),
                onLongPress: () => _eliminarFoto(context, orden),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        fotoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _addPhotoCell(),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return GestureDetector(
              onTap: () => _abrirGaleriaSlot(context, orden),
              child: _addPhotoCell(),
            );
          }),
        ),
        const SizedBox(height: 8),
        const Text(
          'Toca para cambiar \u2022 Mant\u00E9n presionado para eliminar',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}
