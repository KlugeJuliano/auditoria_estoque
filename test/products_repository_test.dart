import 'package:auditoria/repostiories/products_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductsRepository.parseScaleBarcode', () {
    test('interpreta codigo de balanca com prefixo 20-29', () {
      final repository = ProductsRepository();

      final result = repository.parseScaleBarcode('2012345007508');

      expect(result, isNotNull);
      expect(result!['prefix'], '20');
      expect(result['productCode'], '12345');
      expect(result['weight'], 0.75);
    });

    test('retorna nulo para codigo fora do padrao', () {
      final repository = ProductsRepository();

      expect(repository.parseScaleBarcode('7891234567890'), isNull);
      expect(repository.parseScaleBarcode('20123'), isNull);
    });
  });
}
