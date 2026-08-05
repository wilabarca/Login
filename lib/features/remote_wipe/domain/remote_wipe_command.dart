class RemoteWipeCommand {
  final String action;
  final String targetUserId;
  final String commandId;
  final DateTime issuedAt;
  final DateTime expiresAt;

  RemoteWipeCommand({
    required this.action,
    required this.targetUserId,
    required this.commandId,
    required this.issuedAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
