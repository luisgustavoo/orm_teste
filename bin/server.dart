import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:orm/logger.dart';
import 'package:orm_teste/src/generated/prisma/prisma_client.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

// Configure routes.
final _router = Router()
  ..get('/', _rootHandler)
  ..post('/register', _register);

Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}

Future<Response> _register(Request request) async {
  final req = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  User user;
  final prisma = PrismaClient(
    stdout: Event.values, // print all events to the console
    datasources: const Datasources(
      db: 'mysql://root:ormdb@localhost:3306/orm_db?schema=orm_db',
    ),
  );

  try {
    user = await prisma.user.create(
      data: UserCreateInput(
        name: req['name'].toString(),
        email: req['email'].toString(),
      ),
    );

    log('${user.toJson()}');
  } finally {
    await prisma.$disconnect();
  }

  return Response.ok(jsonEncode(user.toJson()));
}

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(_router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  log('Server listening on port ${server.port}');
}
