import 'dart:convert';

import 'package:aisdlc_frontend/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Configurable fake HTTP client: serves [body]/[statusCode], throws on
/// request when [throwException] is set, and records the requested URL.
class FakeClient extends http.BaseClient {
  FakeClient({
    this.statusCode = 200,
    this.body = '{"status":"UP"}',
    this.throwException = false,
  });

  final int statusCode;
  final String body;
  final bool throwException;
  final List<Uri> requestedUrls = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestedUrls.add(request.url);
    if (throwException) {
      throw http.ClientException('Connection refused', request.url);
    }
    return http.StreamedResponse(
      http.ByteStream.fromBytes(utf8.encode(body)),
      statusCode,
    );
  }
}

void main() {
  test('fetchHealthStatus requests /actuator/health under the base URL', () async {
    final client = FakeClient();

    await fetchHealthStatus(client, Uri.parse('http://test:8080'));

    expect(
      client.requestedUrls.single.toString(),
      'http://test:8080/actuator/health',
    );
  });

  testWidgets('shows health status UP when the backend responds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SmokeScreen(
          client: FakeClient(),
          apiBaseUrl: Uri.parse('http://test:8080'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Backend health: UP'), findsOneWidget);
  });

  testWidgets('shows an error state, not a crash, when the backend is down',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SmokeScreen(
          client: FakeClient(throwException: true),
          apiBaseUrl: Uri.parse('http://test:8080'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Cannot reach the backend.'), findsOneWidget);
    expect(tester.takeException(), isNull); // no unhandled framework error
  });

  testWidgets('shows an error state on a malformed health response',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SmokeScreen(
          client: FakeClient(body: '{"unexpected": true}'),
          apiBaseUrl: Uri.parse('http://test:8080'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Cannot reach the backend.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('fetchHealthStatus throws on non-200 responses', () async {
    final client = FakeClient(statusCode: 503, body: '{"status":"DOWN"}');

    await expectLater(
      fetchHealthStatus(client, Uri.parse('http://test:8080')),
      throwsA(isA<HealthCheckException>()),
    );
  });
}
