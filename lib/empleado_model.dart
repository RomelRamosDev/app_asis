class Empleado {
  String? id;
  String nombre;
  String apellido;
  String cedula;
  String cargo;
  bool enVacaciones;
  bool enPermisoMedico;
  DateTime? fechaInicioEstado;
  DateTime? fechaFinEstado;

  Empleado({
    this.id,
    required this.nombre,
    required this.apellido,
    required this.cedula,
    required this.cargo,
    this.enVacaciones = false,
    this.enPermisoMedico = false,
    this.fechaInicioEstado,
    this.fechaFinEstado,
  });

  // Convertir un Empleado a un Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'cedula': cedula,
      'cargo': cargo,
      'enVacaciones': enVacaciones,
      'enPermisoMedico': enPermisoMedico,
      'fechaInicioEstado': fechaInicioEstado?.toIso8601String(),
      'fechaFinEstado': fechaFinEstado?.toIso8601String(),
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
      enVacaciones: map['enVacaciones'] ?? false,
      enPermisoMedico: map['enPermisoMedico'] ?? false,
      fechaInicioEstado: map['fechaInicioEstado'] != null
          ? DateTime.parse(map['fechaInicioEstado'])
          : null,
      fechaFinEstado: map['fechaFinEstado'] != null
          ? DateTime.parse(map['fechaFinEstado'])
          : null,
    );
  }
}
