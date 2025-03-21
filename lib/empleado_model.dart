class Empleado {
  String? id;
  String nombre;
  String apellido;
  String cedula;
  String cargo;
  // String? facialDataPath; // Ruta de la imagen facial

  Empleado({
    this.id,
    required this.nombre,
    required this.apellido,
    required this.cedula,
    required this.cargo,
    // this.facialDataPath,
  });

  // Convertir un Empleado a un Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'cedula': cedula,
      'cargo': cargo,
      // 'facialDataPath': facialDataPath,
    };
  }

  // Convertir un Map a un Empleado
  factory Empleado.fromMap(Map<String, dynamic> map, String id) {
    return Empleado(
      id: id,
      nombre: map['nombre'],
      apellido: map['apellido'],
      cedula: map['cedula'],
      cargo: map['cargo'],
    );
  }
}
