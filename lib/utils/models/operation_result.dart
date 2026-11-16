class OperationResult {
  final bool ok;
  final String? error;

  const OperationResult._({
    required this.ok,
    this.error,
  });

  const OperationResult.success()
      : this._(ok: true);

  const OperationResult.failure(String message)
      : this._(
    ok: false,
    error: message,
  );
}
