class TokenHolder {
  TokenHolder._();
  static final TokenHolder _instance = TokenHolder._();
  factory TokenHolder() => _instance;

  String? _token;
  String? get token => _token;
  set token(String? value) => _token = value;
}
