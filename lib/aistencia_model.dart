class Asistencia {
  String? id; // Cambiar de int? a String?
  String cedulaEmpleado;
  DateTime horaEntrada;
  DateTime? horaSalida;
  bool atrasoEntrada; // Nuevo campo para registrar atrasos en la entrada
  bool atrasoSalida; // Nuevo campo para registrar atrasos en la salida
  bool llevaTarjetas;
  String? observaciones; // Nuevo campo para registrar si lleva tarjetas
  bool entradaAutomatica; // Nuevo campo
  bool salidaAutomatica;
  String sedeId;

  Asistencia({
    this.id,
    required this.cedulaEmpleado,
    required this.horaEntrada,
    this.horaSalida,
    this.atrasoEntrada = false, // Valor por defecto: false
    this.atrasoSalida = false, // Valor por defecto: false
    this.llevaTarjetas = false, // Valor por defecto: false
    this.observaciones,
    this.entradaAutomatica = false, // Valor por defecto
    this.salidaAutomatica = false,
    required this.sedeId,
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
      'observaciones': observaciones,
      'entradaAutomatica': entradaAutomatica,
      'salidaAutomatica': salidaAutomatica,
      'sede_id': sedeId,
    };
  }

  // Convertir un Map a una Asistencia
  factory Asistencia.fromMap(Map<String, dynamic> map, String id) {
    return Asistencia(
      id: id,
      cedulaEmpleado: map['cedulaEmpleado'],
      horaEntrada: DateTime.parse(map['horaEntrada']), // Convertir a local
      horaSalida: map['horaSalida'] != null
          ? DateTime.parse(map['horaSalida']) // Convertir a local
          : null,
      atrasoEntrada: map['atrasoEntrada'] ?? false,
      atrasoSalida: map['atrasoSalida'] ?? false,
      llevaTarjetas: map['llevaTarjetas'] ?? false,
      observaciones: map['observaciones'],
      entradaAutomatica: map['entradaAutomatica'] ?? false,
      salidaAutomatica: map['salidaAutomatica'] ?? false,
      sedeId: map['sede_id'] as String? ?? map['sedeId'] as String? ?? '',
    );
  }
}
