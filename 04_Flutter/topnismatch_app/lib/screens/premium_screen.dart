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
                        const Icon(Icons.workspace_premium,
                            color: Colors.white, size: 64),
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
                        // Estado actual
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _suscripcion?['esPremium'] == true
                                ? '✨ Plan: ${_suscripcion!['plan']} — ${_suscripcion!['diasRestantes']} días restantes'
                                : '🔓 Plan actual: GRATUITO',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Beneficios
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

                        // Planes
                        if (_suscripcion?['esPremium'] != true) ...[
                          const Text(
                            'Elige tu plan:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Plan mensual
                          _buildPlanCard(
                            'PREMIUM_MENSUAL',
                            'Premium Mensual',
                            '\$9.99/mes',
                            '30 días de acceso completo',
                            false,
                          ),
                          const SizedBox(height: 12),

                          // Plan anual
                          _buildPlanCard(
                            'PREMIUM_ANUAL',
                            'Premium Anual',
                            '\$59.99/año',
                            '365 días — Ahorra 50%',
                            true,
                          ),
                        ] else ...[
                          // Ya es premium
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.green, size: 32),
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
                                            color: Colors.grey),
                                      ),
                                      Text(
                                        'Vence en: ${_suscripcion!['diasRestantes']} días',
                                        style: const TextStyle(
                                            color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Renovar
                          OutlinedButton(
                            onPressed: _isUpgrading
                                ? null
                                : () => _activarPremium('PREMIUM_MENSUAL'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFF4458),
                              side: const BorderSide(color: Color(0xFFFF4458)),