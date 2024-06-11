enum TokenType {
  copilot,
  openai,
}

TokenType tokenTypeFromString(String type) {
  switch (type) {
    case 'copilot':
      return TokenType.copilot;
    case 'openai':
      return TokenType.openai;
    default:
      throw ArgumentError('Invalid token type: $type');
  }
}

String tokenTypeToString(TokenType type) {
  switch (type) {
    case TokenType.copilot:
      return 'copilot';
    case TokenType.openai:
      return 'openai';
  }
}