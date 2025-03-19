class Asistencia {
  String? id; // Cambiar de int? a String?
  String cedulaEmpleado;
  DateTime horaEntrada;
  DateTime? horaSalida;
  bool atrasoEntrada; // Nuevo campo para registrar atrasos en la entrada
  bool atrasoSalida; // Nuevo campo para registrar atrasos en la salida
  bool llevaTarjetas; // Nuevo campo para registrar si lleva tarjetas

  Asistencia({
    this.id,
    required this.cedulaEmpleado,
    required this.horaEntrada,
    this.horaSalida,
    this.atrasoEntrada = false, // Valor por defecto: false
    this.atrasoSalida = false, // Valor por defecto: false
    this.llevaTarjetas = false, // Valor por defecto: false
  });

  // Convertir una Asistencia a un Map
  Map<String, dynamic> toMap() {
    return {
      'id': id, // Incluir el id en el Map
      'cedulaEmpleado': cedulaEmpleado,
      'horaEntrada': horaEntrada.toIso8601String(),
      'horaSalida': horaSalida?.toIso8601String(),
      'atrasoEntrada': atrasoEntrada, // Incluir el campo atrasoEntrada
      'atrasoSalida': atrasoSalida, // Incluir el campo atrasoSalida
      'llevaTarjetas': llevaTarjetas, // Incluir el campo llevaTarjetas
    };
  }

  // Convertir un Map a una Asistencia
  factory Asistencia.fromMap(Map<String, dynamic> map, String id) {
    return Asistencia(
      id: id,
      cedulaEmpleado: map['cedulaEmpleado'],
      horaEntrada: DateTime.parse(map['horaEntrada']),
      horaSalida:
          map['horaSalida'] != null ? DateTime.parse(map['horaSalida']) : null,
      atrasoEntrada:
          map['atrasoEntrada'] ?? false, // Leer el campo atrasoEntrada
      atrasoSalida: map['atrasoSalida'] ?? false, // Leer el campo atrasoSalida
      llevaTarjetas:
          map['llevaTarjetas'] ?? false, // Leer el campo llevaTarjetas
    );
  }
}
