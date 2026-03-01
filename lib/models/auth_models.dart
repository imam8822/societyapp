// ─────────────────────────────────────────────
// Auth Models
// ─────────────────────────────────────────────
class LoginResponse {
  final String token;
  final String role;
  final int userId;
  final String fullName;

  LoginResponse(
      {required this.token,
      required this.role,
      required this.userId,
      required this.fullName});

  factory LoginResponse.fromJson(Map<String, dynamic> j) => LoginResponse(
        token: j['token'],
        role: j['role'],
        userId: j['userId'],
        fullName: j['fullName'],
      );
}
