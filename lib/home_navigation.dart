import 'package:flutter/material.dart';
import 'lista_empleados.dart';
import 'lista_asistencia.dart';
import 'buscar_empleado.dart';
import 'generar_reporte.dart';

class HomeNavigation extends StatefulWidget {
  @override
  _HomeNavigationState createState() => _HomeNavigationState();
}

class _HomeNavigationState extends State<HomeNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    BuscarEmpleado(),
    ListaEmpleados(),
    ListaAsistencia(),
    GenerarReporte(), // Nueva pantalla
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
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Fija los íconos y etiquetas
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: _items,
        selectedItemColor: Colors.blue, // Color del ícono seleccionado
        unselectedItemColor:
            Colors.grey, // Color de los íconos no seleccionados
        showUnselectedLabels: true, // Mostrar etiquetas no seleccionadas
      ),
    );
  }
}
