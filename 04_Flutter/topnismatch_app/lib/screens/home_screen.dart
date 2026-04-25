import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final ApiService _api = ApiService();
  List<dynamic> _perfiles = [];
  bool _isLoading = true;

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
              title: const Text('🎉 ¡Es un Match!'),
              content: const Text('¡Felicidades! Ahora pueden chatear.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('¡Genial!'),
                ),
              ],
            ),
          );
        }
      }
      setState(() => _perfiles.removeAt(0));
    } catch (e) {
      setState(() => _perfiles.removeAt(0));
    }
  }

  Future<void> _darDislike(int usuarioId) async {
    try {
      await _api.darDislike(usuarioId);
    } catch (e) {
      // ignore
    }
    setState(() => _perfiles.removeAt(0));
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay más perfiles por ahora',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final perfil = _perfiles[0];
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Container(
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
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(
                                  Icons.person,
                                  size: 100,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.person,
                              size: 100,
                              color: Colors.grey,
                            ),
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
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${perfil['nombre']}, ${perfil['edad']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (perfil['ciudad'] != null)
                            Text(
                              '📍 ${perfil['ciudad']}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          if (perfil['bio'] != null)
                            Text(
                              perfil['bio'],
                              style: const TextStyle(color: Colors.white70),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              FloatingActionButton(
                heroTag: 'superlike',
                onPressed: () async {
                  await _api.darDislike(perfil['usuarioId']);
                  setState(() => _perfiles.removeAt(0));
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
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF4458)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aún no tienes matches',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final match = snapshot.data![index];
            return Card(
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
                subtitle: Text(
                  'Compatibilidad: ${match['compatibilidad'].toStringAsFixed(0)}%',
                ),
                trailing: const Icon(Icons.chat, color: Color(0xFFFF4458)),
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
            );
          },
        );
      },
    );
  }

  Widget _buildPerfil() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _api.getMiPerfil(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF4458)),
          );
        }
        if (!snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No tienes perfil aún'),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/create-profile'),
                  child: const Text('Crear Perfil'),
                ),
              ],
            ),
          );
        }
        final perfil = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFFFF4458),
                child: Text(
                  perfil['nombre'][0].toUpperCase(),
                  style: const TextStyle(fontSize: 48, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                perfil['nombre'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(perfil['email'] ?? ''),
              const SizedBox(height: 24),
              _buildInfoCard('Bio', perfil['bio'] ?? 'Sin bio'),
              _buildInfoCard('Ciudad', perfil['ciudad'] ?? 'Sin ciudad'),
              _buildInfoCard(
                'Intereses',
                perfil['intereses'] ?? 'Sin intereses',
              ),
            ],
          ),
        );
      },
    );
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
