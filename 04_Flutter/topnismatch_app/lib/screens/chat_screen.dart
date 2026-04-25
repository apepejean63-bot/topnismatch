import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final int matchId;
  final String otroUsuarioNombre;

  const ChatScreen({
    super.key,
    required this.matchId,
    required this.otroUsuarioNombre,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _mensajeController = TextEditingController();
  final _scrollController = ScrollController();
  final ApiService _api = ApiService();
  List<dynamic> _mensajes = [];
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _cargarMensajes();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _cargarMensajes();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mensajeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _cargarMensajes() async {
    try {
      final mensajes = await _api.getMensajes(widget.matchId);
      setState(() {
        _mensajes = mensajes;
        _isLoading = false;
      });
      _scrollToBottom();
      await _api.marcarComoLeido(widget.matchId);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _enviarMensaje() async {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty) return;
    _mensajeController.clear();
    try {
      await _api.enviarMensaje(widget.matchId, texto);
      final mensajes = await _api.getMensajes(widget.matchId);
      setState(() {
        _mensajes = mensajes;
      });
      _scrollToBottom();
    } catch (e) {
      // ignore
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF4458),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 18,
              child: Text(
                widget.otroUsuarioNombre[0].toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFFF4458),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.otroUsuarioNombre,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF4458)),
                  )
                : _mensajes.isEmpty
                ? const Center(
                    child: Text(
                      'Se el primero en enviar un mensaje',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _mensajes.length,
                    itemBuilder: (context, index) {
                      final mensaje = _mensajes[index];
                      final esPropio =
                          mensaje['emisorNombre'] != widget.otroUsuarioNombre;
                      return _buildMensaje(mensaje, esPropio);
                    },
                  ),
          ),
          _buildInputMensaje(),
        ],
      ),
    );
  }

  Widget _buildMensaje(Map<String, dynamic> mensaje, bool esPropio) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: esPropio
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: esPropio ? const Color(0xFFFF4458) : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  mensaje['contenido'],
                  style: TextStyle(
                    color: esPropio ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mensaje['estado'] == 'LEIDO' ? 'visto' : 'enviado',
                  style: TextStyle(
                    color: esPropio ? Colors.white70 : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputMensaje() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _mensajeController,
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => _enviarMensaje(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: _enviarMensaje,
            backgroundColor: const Color(0xFFFF4458),
            mini: true,
            child: const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
