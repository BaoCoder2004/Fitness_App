class UnlockRequest {
  UnlockRequest({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.createdAt,
    required this.reason,
    required this.status,
    this.processedAt,
    this.processedBy,
    this.adminNote,
  });

  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final DateTime createdAt;
  final String? reason;
  final String status; // pending | approved | rejected
  final DateTime? processedAt;
  final String? processedBy;
  final String? adminNote;
}

