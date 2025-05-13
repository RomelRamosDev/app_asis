import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_asis/auth_provider.dart';
import 'package:app_asis/themes.dart';

class PinAuthScreen extends StatefulWidget {
  final String moduleName;
  final Widget destination;
  final String? areaId;
  final bool keepNavigation;

  // Área específica para restricción

  const PinAuthScreen({
    Key? key,
    required this.moduleName,
    required this.destination,
    this.areaId,
    this.keepNavigation = false,
  }) : super(key: key);

  @override
  _PinAuthScreenState createState() => _PinAuthScreenState();
}

class _PinAuthScreenState extends State<PinAuthScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verifyPin() async {
    if (_pinController.text.length != 6) {
      setState(() => _errorMessage = 'El PIN debe tener 6 dígitos');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyPin(
      _pinController.text.trim(),
      widget.moduleName,
    );

    setState(() => _isLoading = false);

    if (success) {
      // Verificar restricción de área si se especificó
      if (widget.areaId != null &&
          authProvider.currentAreaId != widget.areaId) {
        setState(
            () => _errorMessage = 'No tiene acceso a esta área específica');
        await authProvider.logout();
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => widget.destination),
      );
    } else {
      setState(() => _errorMessage = 'PIN incorrecto o sin permisos');
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Acceso ${widget.moduleName}',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: greenPalette[800],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: greenPalette[500],
                ),
                const SizedBox(height: 24),
                Text(
                  'Acceso Restringido',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: greenPalette[900],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ingrese el PIN de supervisor para acceder\nal módulo de ${widget.moduleName}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                if (widget.areaId != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '(Acceso restringido a esta área)',
                    style: TextStyle(
                      fontSize: 14,
                      color: greenPalette[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Container(
                  width: 200,
                  child: TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      letterSpacing: 4,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: greenPalette[500]!,
                          width: 2,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      hintText: '••••••',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        letterSpacing: 4,
                      ),
                    ),
                    onChanged: (_) => setState(() => _errorMessage = ''),
                  ),
                ),
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyPin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: greenPalette[500],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 3,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'VERIFICAR PIN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Contacte al administrador para obtener el PIN',
                          textAlign: TextAlign.center,
                        ),
                        backgroundColor: greenPalette[500],
                      ),
                    );
                  },
                  child: Text(
                    '¿Olvidó el PIN?',
                    style: TextStyle(
                      color: greenPalette[700],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: widget.keepNavigation
          ? BottomNavigationBar(
              items: [
                const BottomNavigationBarItem(
                    icon: Icon(Icons.search), label: 'Buscar'),
                const BottomNavigationBarItem(
                    icon: Icon(Icons.people), label: 'Empleados'),
                const BottomNavigationBarItem(
                    icon: Icon(Icons.assignment), label: 'Asistencia'),
                const BottomNavigationBarItem(
                    icon: Icon(Icons.description), label: 'Reportes'),
              ],
              currentIndex: 0,
              onTap: (index) {
                // Lógica de navegación
              },
            )
          : null,
    );
  }
}
