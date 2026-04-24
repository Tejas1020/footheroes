/// Status of a join request.
enum JoinRequestStatus {
  pending,
  approved,
  declined,
  expired,
  cancelled,
  waitlisted,
}

extension JoinRequestStatusX on JoinRequestStatus {
  String get value {
    switch (this) {
      case JoinRequestStatus.pending:
        return 'pending';
      case JoinRequestStatus.approved:
        return 'approved';
      case JoinRequestStatus.declined:
        return 'declined';
      case JoinRequestStatus.expired:
        return 'expired';
      case JoinRequestStatus.cancelled:
        return 'cancelled';
      case JoinRequestStatus.waitlisted:
        return 'waitlisted';
    }
  }

  static JoinRequestStatus fromString(String value) {
    switch (value) {
      case 'approved':
        return JoinRequestStatus.approved;
      case 'declined':
        return JoinRequestStatus.declined;
      case 'expired':
        return JoinRequestStatus.expired;
      case 'cancelled':
        return JoinRequestStatus.cancelled;
      case 'waitlisted':
        return JoinRequestStatus.waitlisted;
      default:
        return JoinRequestStatus.pending;
    }
  }
}

/// Side a player is assigned to after approval.
enum AssignedSide {
  home,
  away,
}

extension AssignedSideX on AssignedSide {
  String get value {
    switch (this) {
      case AssignedSide.home:
        return 'home';
      case AssignedSide.away:
        return 'away';
    }
  }

  static AssignedSide? fromString(String? value) {
    switch (value) {
      case 'home':
        return AssignedSide.home;
      case 'away':
        return AssignedSide.away;
      default:
        return null;
    }
  }
}

/// A request from a player to join an open match.
class JoinRequest {
  final String id;
  final String matchId;
  final String requesterUid;
  final String requesterPosition;
  final String? requesterMessage;
  final JoinRequestStatus status;
  final AssignedSide? assignedSide;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const JoinRequest({
    required this.id,
    required this.matchId,
    required this.requesterUid,
    required this.requesterPosition,
    this.requesterMessage,
    required this.status,
    this.assignedSide,
    required this.createdAt,
    this.respondedAt,
  });
}
