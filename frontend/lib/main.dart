import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Backend base URL. Override for platforms where `localhost` is not the host
/// machine, e.g. the Android emulator:
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080`
const String apiBaseUrlEnv = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080',
);

void main() {
  runApp(const AiSdlcApp());
}

class AiSdlcApp extends StatelessWidget {
  const AiSdlcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI-SDLC Pilot',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: SmokeScreen(
        client: http.Client(),
        apiBaseUrl: Uri.parse(apiBaseUrlEnv),
      ),
    );
  }
}

/// Placeholder smoke screen (story #1 AC5): calls the backend health endpoint
/// and displays the result, proving the two sides are wired together.
class SmokeScreen extends StatefulWidget {
  const SmokeScreen({super.key, required this.client, required this.apiBaseUrl});

  final http.Client client;
  final Uri apiBaseUrl;

  @override
  State<SmokeScreen> createState() => _SmokeScreenState();
}

class _SmokeScreenState extends State<SmokeScreen> {
  late final Future<String> _status =
      fetchHealthStatus(widget.client, widget.apiBaseUrl);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI-SDLC Pilot')),
      body: Center(
        child: FutureBuilder<String>(
          future: _status,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _ErrorView(
                apiBaseUrl: widget.apiBaseUrl,
                error: snapshot.error!,
              );
            }
            if (!snapshot.hasData) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Checking backend health…'),
                ],
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  snapshot.data == 'UP' ? Icons.check_circle : Icons.error,
                  color: snapshot.data == 'UP' ? Colors.green : Colors.orange,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text('Backend health: ${snapshot.data}'),
                Text(
                  '${widget.apiBaseUrl.resolve('/actuator/health')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.apiBaseUrl, required this.error});

  final Uri apiBaseUrl;
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          const Text('Cannot reach the backend.'),
          Text(
            'Expected it at $apiBaseUrl — is it running? '
            'See README.md, "Running the backend".',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Fetches and validates the backend health contract (200 + status field).
/// Throws [HealthCheckException] on any deviation so the UI shows an explicit
/// error state instead of rendering a misleading value.
Future<String> fetchHealthStatus(http.Client client, Uri baseUrl) async {
  final uri = baseUrl.resolve('/actuator/health');
  final response = await client.get(uri);

  if (response.statusCode != 200) {
    throw HealthCheckException('HTTP ${response.statusCode} from $uri');
  }
  final body = jsonDecode(response.body) as Map<String, dynamic>;
  final status = body['status'] as String?;
  if (status == null || status.isEmpty) {
    throw HealthCheckException('Unexpected response from $uri: $body');
  }
  return status;
}

class HealthCheckException implements Exception {
  HealthCheckException(this.message);

  final String message;

  @override
  String toString() => message;
}
