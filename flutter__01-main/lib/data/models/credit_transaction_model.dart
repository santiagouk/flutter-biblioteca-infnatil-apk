import 'package:equatable/equatable.dart';

/// Representa una fila de `credit_transactions`: un movimiento
/// (positivo o negativo) del saldo de créditos de un usuario.
/// Es solo de lectura desde la app — el saldo y estas filas los
/// gestionan siempre triggers del lado del servidor (nunca se
/// insertan manualmente desde el cliente).
class CreditTransactionModel extends Equatable {
  final String id;
  final int cantidad;
  final String motivo;
  final DateTime creadoEn;

  const CreditTransactionModel({
    required this.id,
    required this.cantidad,
    required this.motivo,
    required this.creadoEn,
  });

  bool get esPositiva => cantidad > 0;

  factory CreditTransactionModel.fromJson(Map<String, dynamic> json) {
    return CreditTransactionModel(
      id: json['id'] as String,
      cantidad: json['cantidad'] as int,
      motivo: json['motivo'] as String,
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, cantidad, motivo, creadoEn];
}

/// Resultado de la función RPC `canjear_libro_vip`.
class VipRedeemResult {
  final bool exito;
  final String mensaje;
  final int creditosRestantes;

  const VipRedeemResult({
    required this.exito,
    required this.mensaje,
    required this.creditosRestantes,
  });

  factory VipRedeemResult.fromJson(Map<String, dynamic> json) {
    return VipRedeemResult(
      exito: json['exito'] as bool? ?? false,
      mensaje: json['mensaje'] as String? ?? 'No fue posible canjear el libro.',
      creditosRestantes: json['creditos_restantes'] as int? ?? 0,
    );
  }
}
