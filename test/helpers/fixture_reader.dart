import 'dart:io';

import 'package:http/http.dart' as http;

/// Reads a file from `test/fixtures/`.
String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

/// Builds an HTTP response with the `content-type` TheCatAPI actually sends.
///
/// The header is not decorative: `http.Response(String body, int status)` encodes
/// the body using the charset declared in the headers, and **defaults to
/// latin1**. Without it, any non-ASCII byte in a description would round-trip
/// differently than in production, i.e. we would be testing a different decoder.
http.Response jsonResponse(String body, [int status = 200]) => http.Response(
  body,
  status,
  headers: const {'content-type': 'application/json; charset=utf-8'},
);
