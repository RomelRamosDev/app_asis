import 'package:flutter/material.dart';
import 'lista_empleados.dart';
import 'lista_asistencia.dart';
import 'buscar_empleado.dart';
import 'generar_reporte.dart';
import 'pin_auth_screen.dart';
import 'auth_provider.dart';
import 'package:provider/provider.dart';

class HomeNavigation extends StatefulWidget {
  @override
  _HomeNavigationState createState() => _HomeNavigationState();
}

class _HomeNavigationState extends State<HomeNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    BuscarEmpleado(),
    PinAuthScreen(
      moduleName: 'Empleados',
      destination: ListaEmpleados(),
    ),
    PinAuthScreen(
      moduleName: 'Asistencia',
      destination: ListaAsistencia(),
    ),
    PinAuthScreen(
      moduleName: 'Reportes',
      destination: GenerarReporte(),
    ),
  ];

  final List<BottomNavigationBarItem> _items = [
    const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
    const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Empleados'),
    const BottomNavigationBarItem(
        icon: Icon(Icons.assignment), label: 'Asistencia'),
    const BottomNavigationBarItem(
        icon: Icon(Icons.description), label: 'Reportes'), // Nueva opción
  ];

  void _onItemTapped(int index) {
    // No permitir navegación si no está autenticado (excepto la pantalla de búsqueda)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (index != 0 && !authProvider.isAuthenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _screens[index],
        ),
      );
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: _selectedIndex == 0
          ? _screens[0] // Pantalla de búsqueda siempre accesible
          : authProvider.isAuthenticated
              ? _screens[_selectedIndex]
              : _screens[_selectedIndex], // Mostrará el PinAuthScreen
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: _items,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
}
