import 'dart:ffi';

class Contagem {
  String ean;
  String description;
  String complement;
  String brand;
  Double quantity;

  Contagem(
      this.ean, this.description, this.complement, this.brand, this.quantity);
}
