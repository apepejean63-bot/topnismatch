import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  void _mostrarOpciones(BuildContext context, int orden, String fotoUrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
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
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit, color: primary),
              title: const Text('Cambiar foto'),
              onTap: () {
                Navigator.pop(context);
                _abrirGaleriaSlot(context, orden);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar foto', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmarEliminar(context, orden);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminar(BuildContext context, int orden) {
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

  void _verFotoCompleta(BuildContext context, int orden, String fotoUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: fotoUrl,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white, size: 80),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _abrirGaleriaSlot(context, orden);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Cambiar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmarEliminar(context, orden);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Eliminar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

  Widget _fotoCell(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF4458), strokeWidth: 2),
          ),
        ),
        errorWidget: (_, __, ___) => _addPhotoCell(),
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
              final url = fotoUrl;
              return GestureDetector(
                onTap: () => _verFotoCompleta(context, orden, url),
                onLongPress: () => _mostrarOpciones(context, orden, url),
                child: _fotoCell(url),
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
          'Toca para ver \u2022 Mant\u00E9n presionado para opciones',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}
