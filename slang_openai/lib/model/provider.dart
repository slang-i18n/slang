enum Provider {
  openai,
  openrouter,
  ollama;

  static Provider? fromString(String value) {
    switch (value) {
      case 'openai':
        return Provider.openai;
      case 'openrouter':
        return Provider.openrouter;
      case 'ollama':
        return Provider.ollama;
      default:
        return null;
    }
  }
}
