import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final ApiService _api = ApiService();
  List<dynamic> _perfiles = [];
  bool _isLoading = true;

  double _dragX = 0;
  double _dragY = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _cargarPerfiles();
  }

  Future<void> _cargarPerfiles() async {
    try {
      final perfiles = await _api.discover();
      setState(() {
        _perfiles = perfiles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _darLike(int usuarioId) async {
    try {
      final response = await _api.darLike(usuarioId);
      if (response['esMatch'] == true) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('\u{1F389} \u00A1Es un Match!'),
              content: const Text('\u00A1Felicidades! Ahora pueden chatear.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('\u00A1Genial!'),
                ),
              ],
            ),
          );
        }
      }
      setState(() {
        _perfiles.removeAt(0);
        _dragX = 0;
        _dragY = 0;
      });
    } catch (e) {
      setState(() {
        _perfiles.removeAt(0);
        _dragX = 0;
        _dragY = 0;
      });
    }
  }

  Future<void> _darDislike(int usuarioId) async {
    try {
      await _api.darDislike(usuarioId);
    } catch (e) {
      // ignore
    }
    setState(() {
      _perfiles.removeAt(0);
      _dragX = 0;
      _dragY = 0;
    });
  }

  void _confirmarEliminarMatch(BuildContext context, int matchId, String nombre) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Eliminar match'),
        content: Text('\u00BFQuieres eliminar el match con $nombre?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _api.eliminarMatch(matchId);
                setState(() {});
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Match eliminado'),
                      backgroundColor: Colors.green,
                    ),
                  );
              } catch (e) {
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF4458),
        title: const Text(
          'TopnisMatch',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium, color: Colors.white),
            tooltip: 'Premium',
            onPressed: () => Navigator.pushNamed(context, '/premium'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFFF4458),
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Matches'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildDiscover();
      case 1:
        return _buildMatches();
      case 2:
        return _buildPerfil();
      default:
        return _buildDiscover();
    }
  }

  Widget _buildDiscover() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF4458)),
      );
    }

    if (_perfiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No hay m\u00E1s perfiles por ahora',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarPerfiles,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4458)),
              child: const Text('Recargar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final perfil = _perfiles[0];
    final screenWidth = MediaQuery.of(context).size.width;
    final angle = _dragX / screenWidth * 0.4;
    final isLiking = _dragX > 50;
    final isDisliking = _dragX < -50;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onPanStart: (_) => setState(() => _isDragging = true),
              onPanUpdate: (details) {
                setState(() {
                  _dragX += details.delta.dx;
                  _dragY += details.delta.dy;
                });
              },
              onPanEnd: (_) {
                if (_dragX > 100) {
                  _darLike(perfil['usuarioId']);
                } else if (_dragX < -100) {
                  _darDislike(perfil['usuarioId']);
                } else {
                  setState(() {
                    _dragX = 0;
                    _dragY = 0;
                    _isDragging = false;
                  });
                }
              },
              child: Transform(
                transform: Matrix4.identity()
                  ..translate(_dragX, _dragY)
                  ..rotateZ(angle),
                alignment: Alignment.bottomCenter,
                child: Stack(
                  children: [
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.grey[300],
                            ),
                            child: perfil['fotoPrincipalUrl'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.network(
                                      perfil['fotoPrincipalUrl'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Center(
                                        child: Icon(Icons.person, size: 100, color: Colors.grey),
                                      ),
                                    ),
                                  )
                                : const Center(
                                    child: Icon(Icons.person, size: 100, color: Colors.grey),
                                  ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${perfil['nombre']}, ${perfil['edad']}',
                                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                  if (perfil['ciudad'] != null)
                                    Text('\u{1F4CD} ${perfil['ciudad']}', style: const TextStyle(color: Colors.white70)),
                                  if (perfil['bio'] != null)
                                    Text(perfil['bio'], style: const TextStyle(color: Colors.white70), maxLines: 2, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ),
                          if (isLiking)
                            Positioned(
                              top: 30, left: 20,
                              child: Transform.rotate(
                                angle: -0.3,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(border: Border.all(color: Colors.green, width: 4), borderRadius: BorderRadius.circular(8)),
                                  child: const Text('LIKE', style: TextStyle(color: Colors.green, fontSize: 32, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          if (isDisliking)
                            Positioned(
                              top: 30, right: 20,
                              child: Transform.rotate(
                                angle: 0.3,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(border: Border.all(color: Colors.red, width: 4), borderRadius: BorderRadius.circular(8)),
                                  child: const Text('NOPE', style: TextStyle(color: Colors.red, fontSize: 32, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                heroTag: 'dislike',
                onPressed: () => _darDislike(perfil['usuarioId']),
                backgroundColor: Colors.white,
                child: const Icon(Icons.close, color: Colors.red, size: 36),
              ),
              FloatingActionButton.large(
                heroTag: 'like',
                onPressed: () => _darLike(perfil['usuarioId']),
                backgroundColor: const Color(0xFFFF4458),
                child: const Icon(Icons.favorite, color: Colors.white, size: 48),
              ),
              FloatingActionButton(
                heroTag: 'superlike',
                onPressed: () async {
                  await _api.darDislike(perfil['usuarioId']);
                  setState(() {
                    _perfiles.removeAt(0);
                    _dragX = 0;
                    _dragY = 0;
                  });
                },
                backgroundColor: Colors.white,
                child: const Icon(Icons.star, color: Colors.blue, size: 36),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMatches() {
    return FutureBuilder<List<dynamic>>(
      future: _api.getMisMatches(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFF4458)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('A\u00FAn no tienes matches', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final match = snapshot.data![index];
            return Dismissible(
              key: Key(match['matchId'].toString()),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete, color: Colors.white, size: 30),
              ),
              confirmDismiss: (_) async {
                bool confirmed = false;
                await showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: Colors.white,
                    title: const Text('Eliminar match'),
                    content: Text('\u00BFQuieres eliminar el match con ${match['otroUsuarioNombre']}?'),
                    actions: [
                      TextButton(
                        onPressed: () { confirmed = false; Navigator.pop(context); },
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () { confirmed = true; Navigator.pop(context); },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                return confirmed;
              },
              onDismissed: (_) async {
                try {
                  await _api.eliminarMatch(match['matchId']);
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Match eliminado'), backgroundColor: Colors.green),
                    );
                } catch (e) {
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                }
              },
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFFF4458),
                    child: Text(
                      match['otroUsuarioNombre'][0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(match['otroUsuarioNombre']),
                  subtitle: Text('Compatibilidad: ${match['compatibilidad'].toStringAsFixed(0)}%'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmarEliminarMatch(context, match['matchId'], match['otroUsuarioNombre']),
                      ),
                      const Icon(Icons.chat, color: Color(0xFFFF4458)),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          matchId: match['matchId'],
                          otroUsuarioNombre: match['otroUsuarioNombre'],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPerfil() {
    return const ProfileScreen();
  }

  Widget _buildInfoCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }
}
