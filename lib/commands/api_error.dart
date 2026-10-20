import 'package:fluxer_dart/fluxer_dart.dart';

/// [error] as one line for a reply, including each rejected field of a
/// `400 INVALID_FORM_BODY` — the top-level message alone is just
/// "Invalid form body."
String describeApiError(FluxerApiException error) => [
  error.message,
  for (final field in error.fieldErrors) '`${field.path}`: ${field.message}',
].join(' — ');
