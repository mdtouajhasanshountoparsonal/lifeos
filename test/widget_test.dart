import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/app.dart';

void main() {
  testWidgets('App should render', (WidgetTester tester) async {
    await tester.pumpWidget(const LifeOSApp());
    expect(find.byType(LifeOSApp), findsOneWidget);
  });
}
