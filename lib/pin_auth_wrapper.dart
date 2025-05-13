// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'auth_provider.dart';
// import 'pin_auth_screen.dart';
// import 'buscar_empleado.dart';
// import 'lista_empleados.dart';
// import 'lista_asistencia.dart';
// import 'generar_reporte.dart';

// class PinAuthWrapper extends StatefulWidget {
//   final int initialIndex;

//   const PinAuthWrapper({
//     Key? key,
//     required this.initialIndex,
//   }) : super(key: key);

//   @override
//   _PinAuthWrapperState createState() => _PinAuthWrapperState();
// }

// class _PinAuthWrapperState extends State<PinAuthWrapper> {
//   late int _currentIndex;
//   bool _authChecked = false;

//   final List<Widget> _screens = [
//     BuscarEmpleado(),
//     ListaEmpleados(),
//     ListaAsistencia(),
//     GenerarReporte(),
//   ];

//   final List<String> _moduleNames = const [
//     'Buscar',
//     'Empleados',
//     'Asistencia',
//     'Reportes'
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _currentIndex = widget.initialIndex;
//     _checkAuthStatus();
//   }

//   Future<void> _checkAuthStatus() async {
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//     await authProvider.autoLogin();
//     setState(() {
//       _authChecked = true;
//     });
//   }

//   void _onTabTapped(int index) {
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);

//     if (!authProvider.isAuthenticated && index != 0) {
//       // No hacer nada si no está autenticado y trata de acceder a módulos restringidos
//       return;
//     }

//     setState(() {
//       _currentIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = Provider.of<AuthProvider>(context);

//     if (!_authChecked) {
//       return Scaffold(
//         body: Center(
//           child: CircularProgressIndicator(),
//         ),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           _moduleNames[_currentIndex],
//           style: TextStyle(fontSize: 20),
//         ),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       body: _buildCurrentScreen(authProvider),
//       bottomNavigationBar: _buildBottomNavigationBar(authProvider),
//     );
//   }

//   Widget _buildCurrentScreen(AuthProvider authProvider) {
//     if (_currentIndex == 0) {
//       return _screens[0]; // Pantalla de búsqueda siempre accesible
//     }

//     return authProvider.isAuthenticated
//         ? _screens[_currentIndex]
//         : PinAuthScreen(
//             moduleName: _moduleNames[_currentIndex],
//             onSuccess: () {
//               setState(() {
//                 // Actualiza el estado después de autenticación exitosa
//               });
//             },
//           );
//   }

//   Widget _buildBottomNavigationBar(AuthProvider authProvider) {
//     return BottomNavigationBar(
//       currentIndex: _currentIndex,
//       onTap: _onTabTapped,
//       type: BottomNavigationBarType.fixed,
//       selectedItemColor: Colors.blue,
//       unselectedItemColor: Colors.grey,
//       showUnselectedLabels: true,
//       items: [
//         BottomNavigationBarItem(
//           icon: Icon(Icons.search),
//           label: _moduleNames[0],
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.people),
//           label: _moduleNames[1],
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.assignment),
//           label: _moduleNames[2],
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.description),
//           label: _moduleNames[3],
//         ),
//       ],
//     );
//   }
// }
