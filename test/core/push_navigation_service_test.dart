import 'package:flutter_test/flutter_test.dart';
import 'package:app_tenda/core/routes/app_routes.dart';
import 'package:app_tenda/core/services/push_navigation_service.dart';

void main() {
  group('PushNavigationService.parse', () {
    test('comprovante pendente abre a revisão com o id da solicitação', () {
      final destination = PushNavigationService.parse({
        'type': 'payment_receipt_pending',
        'requestId': 'r1',
        'userId': 'u1',
      });

      expect(destination, isNotNull);
      expect(destination!.route, AppRoutes.receiptReview);
      expect(destination.arguments, {'requestId': 'r1'});
    });

    test('sem requestId não há destino', () {
      expect(
        PushNavigationService.parse({'type': 'payment_receipt_pending'}),
        isNull,
      );
      expect(
        PushNavigationService.parse({
          'type': 'payment_receipt_pending',
          'requestId': '',
        }),
        isNull,
      );
    });

    test('pushes de outros tipos não navegam', () {
      expect(PushNavigationService.parse({'type': 'presence_confirmed'}), isNull);
      expect(PushNavigationService.parse({}), isNull);
    });
  });
}
