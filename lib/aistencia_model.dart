class Asistencia {
  int? id;
  String cedulaEmpleado;
  DateTime horaEntrada;
  DateTime? horaSalida;

  Asistencia({
    this.id,
    required this.cedulaEmpleado,
    required this.horaEntrada,
    this.horaSalida,
  });

  // Convertir una Asistencia a un Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cedulaEmpleado': cedulaEmpleado,
      'horaEntrada': horaEntrada.toIso8601String(),
      'horaSalida': horaSalida?.toIso8601String(),
    };
  }

  // Convertir un Map a una Asistencia
  factory Asistencia.fromMap(Map<String, dynamic> map) {
    return Asistencia(
      id: map['id'],
      cedulaEmpleado: map['cedulaEmpleado'],
      horaEntrada: DateTime.parse(map['horaEntrada']),
      horaSalida:
          map['horaSalida'] != null ? DateTime.parse(map['horaSalida']) : null,
    );
  }
}
