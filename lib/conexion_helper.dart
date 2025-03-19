// import 'package:flutter/material.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';

// class ConexionHelper {
//   // Verificar si hay conexión a Internet
//   static Future<bool> tieneConexionInternet() async {
//     final connectivityResult = await Connectivity().checkConnectivity();

//     // Verificar si hay conexión Wi-Fi o datos móviles
//     if (connectivityResult == ConnectivityResult.wifi ||
//         connectivityResult == ConnectivityResult.mobile) {
//       return true; // Hay conexión a Internet
//     } else {
//       return false; // No hay conexión a Internet
//     }
//   }

//   // Mostrar un SnackBar si no hay conexión
//   static void mostrarMensajeSinConexion(BuildContext context) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//             'Conéctate a una red Wi-Fi o usa datos móviles para continuar.'),
//         duration: Duration(seconds: 5),
//         action: SnackBarAction(
//           label: 'Aceptar',
//           onPressed: () {
//             // Cerrar el SnackBar
//             ScaffoldMessenger.of(context).hideCurrentSnackBar();
//           },
//         ),
//       ),
//     );
//   }

//   // Verificar la conexión y mostrar un SnackBar si no hay conexión
//   static Future<void> verificarConexionYMostrarMensaje(
//       BuildContext context) async {
//     final tieneConexion = await tieneConexionInternet();

//     if (!tieneConexion) {
//       mostrarMensajeSinConexion(context);
//     }
//   }
// }
