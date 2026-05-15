import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EditarBioScreen extends StatefulWidget {
  final String bioActual;
  const EditarBioScreen({super.key, required this.bioActual});

  @override
  State<EditarBioScreen> createState() => _EditarBioScreenState();
}

class _EditarBioScreenState extends State<EditarBioScreen> {
  final ApiService _api = ApiService();
  late TextEditingController _controller;
  bool _guardando = false;
  static const Color primary = Color(0xFFFF4458);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.bioActual);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await _api.editarPerfil({'bio': _controller.text.trim()});
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar'),
            backgroundColor: Colors.red,
          ),
        );
    }
    setState(() => _guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Sobre m\u00ED',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _guardando ? null : _guardar,
            child: _guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primary,
                    ),
                  )
                : const Text(
                    'Guardar',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cu\u00E9ntanos sobre ti',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLength: 300,
              maxLines: null,
              minLines: 3,
              decoration: InputDecoration(
                hintText: 'Cu\u00E9ntale al mundo qui\u00E9n eres...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
