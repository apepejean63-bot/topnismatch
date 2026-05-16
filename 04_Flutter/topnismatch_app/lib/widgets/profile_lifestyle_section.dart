import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProfileLifestyleSection extends StatelessWidget {
  final Map<String, dynamic> perfil;
  final Function(String, List<String>) mostrarSelectorOpciones;

  const ProfileLifestyleSection({
    super.key,
    required this.perfil,
    required this.mostrarSelectorOpciones,
  });

  static const Color primary = Color(0xFFFF4458);

  Widget _lifestyleRow(
    IconData icon,
    String label,
    Color iconColor,
    List<String> opciones,
    String? valorActual,
  ) {
    return Builder(
      builder: (context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => mostrarSelectorOpciones(label, opciones),
          borderRadius: BorderRadius.circular(12),
          splashColor: primary.withOpacity(0.1),
          highlightColor: primary.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
                Text(
                  valorActual != null && valorActual.isNotEmpty
                      ? valorActual
                      : 'Agregar',
                  style: TextStyle(
                    fontSize: 13,
                    color: valorActual != null && valorActual.isNotEmpty
                        ? Colors.black87
                        : Colors.grey,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialRow(
    BuildContext context,
    IconData icon,
    Color iconColor,
    String label,
    String action,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conectar $label pr\u00F3ximamente'),
            backgroundColor: primary,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                FaIcon(icon, color: iconColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
            Text(
              action,
              style: const TextStyle(
                fontSize: 13,
                color: primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _lifestyleRow(Icons.pets, 'Mascotas', Colors.blue, [
          'Perro', 'Gato', 'Ninguna', 'Varios',
        ], perfil['mascotas']),
        _lifestyleRow(Icons.local_bar, 'Alcohol', Colors.red, [
          'Nunca', 'Socialmente', 'Frecuentemente',
        ], perfil['alcohol']),
        _lifestyleRow(Icons.smoking_rooms, 'Tabaco', Colors.grey, [
          'No fumo', 'Ocasionalmente', 'Frecuentemente',
        ], perfil['tabaco']),
        _lifestyleRow(Icons.fitness_center, 'Ejercicio', Colors.orange, [
          'Nunca', 'A veces', 'Frecuentemente', 'Todos los d\u00EDas',
        ], perfil['ejercicio']),
        _lifestyleRow(Icons.child_care, '\u00BFTienes hijos?', Colors.pink, [
          'S\u00ED', 'No',
        ], perfil['tieneHijos']),
        _lifestyleRow(Icons.baby_changing_station, '\u00BFQuieres hijos?', Colors.blue, [
          'S\u00ED', 'No', 'Quiz\u00E1s',
        ], perfil['quiereHijos']),
        _lifestyleRow(Icons.church, 'Religi\u00F3n', Colors.amber, [
          'Cristiano', 'Cat\u00F3lico', 'Muslim', 'Jud\u00EDo', 'Budista', 'Otro', 'Ninguna',
        ], perfil['religion']),
        const SizedBox(height: 8),
        _socialRow(context, FontAwesomeIcons.instagram, const Color(0xFFE1306C), 'Instagram', 'Conectar'),
        _socialRow(context, FontAwesomeIcons.spotify, const Color(0xFF1DB954), 'Spotify', 'Conectar'),
        _socialRow(context, FontAwesomeIcons.tiktok, Colors.black, 'TikTok', 'Conectar'),
      ],
    );
  }
}
