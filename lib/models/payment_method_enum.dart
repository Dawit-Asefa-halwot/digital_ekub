/// Supported simulated payment methods for Digital Ekub.
enum PaymentMethod {
  telebirr,
  cbeBirr,
  bankTransfer,
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.telebirr:
        return 'Telebirr';
      case PaymentMethod.cbeBirr:
        return 'CBE Birr';
      case PaymentMethod.bankTransfer:
        return 'Commercial Bank Transfer';
    }
  }

  String get shortCode {
    switch (this) {
      case PaymentMethod.telebirr:
        return 'TEL';
      case PaymentMethod.cbeBirr:
        return 'CBE';
      case PaymentMethod.bankTransfer:
        return 'BNK';
    }
  }
}
