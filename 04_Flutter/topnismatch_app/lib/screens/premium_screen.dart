import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _suscripcion;
  bool _isLoading = true;
  bool _isUpgrading = false;

  @override
  void initState() {
    super.initState();
    _cargarSuscripcion();
  }

  Future<void> _cargarSuscripcion() async {
    try {
      final data = await _api.getSuscripcion();
      setState(() {
        _suscripcion = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _activarPremium(String plan) async {
    setState(() => _isUpgrading = true);
    try {
      await _api.upgradePremium(plan);
      await _cargarSuscripcion();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 ¡Premium activado exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al activar Premium'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _isUpgrading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF4458),
        title: const Text(
          'Premium',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF4458)),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFF4458), Color(0xFFFF8C00)],
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.workspace_premium,
                          color: Colors.white,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'TopnisMatch Premium',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _suscripcion?['esPremium'] == true
                                ? '✨ Plan: ${_suscripcion!['plan']} — ${_suscripcion!['diasRestantes']} días restantes'
                                : '🔓 Plan actual: GRATUITO',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Beneficios y planes
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '¿Qué incluye Premium?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildBeneficio(
                          Icons.favorite,
                          'Likes ilimitados',
                          'Sin límite diario de likes',
                          Colors.red,
                        ),
                        _buildBeneficio(
                          Icons.visibility,
                          'Ver quién te dio like',
                          'Conoce quién está interesado en ti',
                          Colors.purple,
                        ),
                        _buildBeneficio(
                          Icons.bolt,
                          'Boost semanal',
                          'Aparece primero en el discover',
                          Colors.orange,
                        ),
                        _buildBeneficio(
                          Icons.star,
                          'Superlikes ilimitados',
                          'Destácate entre los demás',
                          Colors.blue,
                        ),
                        _buildBeneficio(
                          Icons.replay,
                          'Deshacer swipe',
                          'Vuelve atrás si te equivocaste',
                          Colors.green,
                        ),
                        const SizedBox(height: 24),

                        if (_suscripcion?['esPremium'] != true) ...[
                          const Text(
                            'Elige tu plan:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildPlanCard(
                            'PREMIUM_MENSUAL',
                            'Premium Mensual',
                            '\$9.99/mes',
                            '30 días de acceso completo',
                            false,
                          ),
                          const SizedBox(height: 12),
                          _buildPlanCard(
                            'PREMIUM_ANUAL',
                            'Premium Anual',
                            '\$59.99/año',
                            '365 días — Ahorra 50%',
                            true,
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '¡Eres Premium!',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Text(
                                        'Plan: ${_suscripcion!['plan']}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        'Vence en: ${_suscripcion!['diasRestantes']} días',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _isUpgrading
                                ? null
                                : () => _activarPremium('PREMIUM_MENSUAL'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFF4458),
                              side: const BorderSide(color: Color(0xFFFF4458)),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text('Renovar plan'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBeneficio(
    IconData icon,
    String titulo,
    String descripcion,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  descripcion,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    String plan,
    String titulo,
    String precio,
    String descripcion,
    bool esPopular,
  ) {
    return GestureDetector(
      onTap: _isUpgrading ? null : () => _activarPremium(plan),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: esPopular
              ? const LinearGradient(
                  colors: [Color(0xFFFF4458), Color(0xFFFF8C00)],
                )
              : null,
          color: esPopular ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: esPopular ? Colors.transparent : const Color(0xFFFF4458),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (esPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '⭐ MÁS POPULAR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Text(
                    titulo,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: esPopular ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    descripcion,
                    style: TextStyle(
                      color: esPopular ? Colors.white70 : Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  precio,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: esPopular ? Colors.white : const Color(0xFFFF4458),
                  ),
                ),
                const SizedBox(height: 4),
                _isUpgrading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        Icons.arrow_forward_ios,
                        color: esPopular
                            ? Colors.white
                            : const Color(0xFFFF4458),
                        size: 16,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
