import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  String _generoSeleccionado = 'MASCULINO';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fechaNacimientoController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.register({
      'nombre': _nombreController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text.trim(),
      'fechaNacimiento': _fechaNacimientoController.text.trim(),
      'genero': _generoSeleccionado,
    });

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFF4458),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Crear Cuenta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              // Nombre
              _buildTextField(
                _nombreController,
                'Nombre completo',
                Icons.person,
              ),
              const SizedBox(height: 16),

              // Email
              _buildTextField(
                _emailController,
                'Email',
                Icons.email,
                type: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Password
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Contraseña',
                  hintStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: const Icon(Icons.lock, color: Colors.white60),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.white60,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Fecha nacimiento
              _buildTextField(
                _fechaNacimientoController,
                'Fecha de nacimiento (YYYY-MM-DD)',
                Icons.calendar_today,
              ),
              const SizedBox(height: 16),

              // Género
              DropdownButtonFormField<String>(
                value: _generoSeleccionado,
                dropdownColor: const Color(0xFFFF4458),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.people, color: Colors.white60),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'MASCULINO',
                    child: Text('Masculino'),
                  ),
                  DropdownMenuItem(value: 'FEMENINO', child: Text('Femenino')),
                  DropdownMenuItem(
                    value: 'NO_BINARIO',
                    child: Text('No binario'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _generoSeleccionado = value!),
              ),
              const SizedBox(height: 8),

              // Error
              if (auth.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    auth.errorMessage!,
                    style: const TextStyle(color: Colors.yellow),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 24),

              // Register button
              ElevatedButton(
                onPressed: auth.isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFFF4458),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: auth.isLoading
                    ? const CircularProgressIndicator(color: Color(0xFFFF4458))
                    : const Text(
                        'Registrarse',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.white60),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white30),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}
