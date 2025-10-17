// lib/services/providers/openai.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';

String sanitizeString(String input) {
  return input.replaceAll('\n', '').replaceAll('\t', '').trim();
}

class OpenAIProvider extends ChangeNotifier implements LlmProvider {
  late final OpenAIClient _client;
  List<ChatMessage> _history = [];
  bool _isStreaming = false;

  @override
  Iterable<ChatMessage> get history => _history;

  @override
  set history(Iterable<ChatMessage> h) {
    _history = h.toList();
    notifyListeners();
  }

  bool get isStreaming => _isStreaming;

  // ДОБАВЛЕНО: systemPrompt в конструкторе
  OpenAIProvider({
    required String apiKey,
    required String baseUrl,
    required String model,
    required double temperature,
    required double topP,
    required double maxTokens,
    Iterable<ChatMessage>? initialHistory,
    this.systemPrompt = '', // ДОБАВЛЕНО: По умолчанию пустой
  })  : _model = sanitizeString(model),
        _temperature = temperature,
        _topP = topP,
        _maxTokens = maxTokens.toInt() {
    // Debug для проверки применения настроек
    debugPrint('OpenAIProvider init: apiKey=${apiKey.isEmpty ? "EMPTY" : apiKey.substring(0, 5)}..., baseUrl=$baseUrl, model=$model, temperature=$temperature, topP=$_topP, maxTokens=$_maxTokens, systemPrompt=${systemPrompt.substring(0, min(20, systemPrompt.length))}...');
    _client = OpenAIClient(
      apiKey: sanitizeString(apiKey),
      baseUrl: sanitizeString(baseUrl),
    );
    // Use setter to set initial history and notifyListeners for UI to render all messages
    if (initialHistory != null) {
      history = initialHistory;
    }
  }

  final String _model;
  final double _temperature;
  final double _topP;
  final int _maxTokens;
  final String systemPrompt; // ДОБАВЛЕНО

  @override
  Stream<String> sendMessageStream(String prompt, {Iterable<Attachment>? attachments}) async* {
    final userMessage = ChatMessage.user(prompt, attachments ?? const []);
    _history.add(userMessage);
    notifyListeners();

    final List<ChatCompletionMessage> openaiMessages = [];
    // ДОБАВЛЕНО: Добавить system prompt если не пустой
    if (systemPrompt.isNotEmpty) {
      openaiMessages.add(ChatCompletionMessage.system(content: systemPrompt));
    } else {
      openaiMessages.add(ChatCompletionMessage.system(content: 'You are a helpful assistant.'));
    }
    for (final msg in _history) {
      final text = msg.text ?? '';
      if (msg.origin.isUser) {
        openaiMessages.add(ChatCompletionMessage.user(
          content: ChatCompletionUserMessageContent.string(text),
        ));
      } else {
        openaiMessages.add(ChatCompletionMessage.assistant(
          content: text,
        ));
      }
    }

    Stream<CreateChatCompletionStreamResponse> stream;
    try {
      stream = _client.createChatCompletionStream(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId(_model),
          messages: openaiMessages,
          stream: true,
          temperature: _temperature,
          topP: _topP,
          maxTokens: _maxTokens,
        ),
      );
      debugPrint('OpenAI stream started successfully with model=$_model');
    } catch (e) {
      debugPrint('Error starting OpenAI stream: $e');
      yield '';
      return;
    }

    _isStreaming = true;
    notifyListeners();

    final assistantMessage = ChatMessage(
      origin: MessageOrigin.llm,
      text: '',
      attachments: const [],
    );
    _history.add(assistantMessage);
    notifyListeners();

    String buffer = '';
    List<(int deltaTime, int deltaChars)> chunkDeltas = [];
    int prevTimeMs = 0;
    try {
      await for (final res in stream) {
        final choices = res.choices;
        if (choices != null && choices.isNotEmpty) {
          final choice = choices.first;
          final delta = choice.delta;
          if (delta != null) {
            final deltaText = delta.content ?? '';
            if (deltaText.isNotEmpty) {
              int nowMs = DateTime.now().millisecondsSinceEpoch;
              if (prevTimeMs == 0) {
                prevTimeMs = nowMs;
              } else {
                int deltaT = nowMs - prevTimeMs;
                chunkDeltas.add((deltaT, deltaText.length));
                prevTimeMs = nowMs;
              }
              buffer += deltaText;
            }
          }
        }
      }
      debugPrint('OpenAI stream completed.');
      if (buffer.isEmpty) {
        assistantMessage.text = 'No response from model.';
        notifyListeners();
      } else {
        // Рассчитать среднюю скорость
        double avgSpeed = 20.0; // default chars/sec
        if (chunkDeltas.isNotEmpty) {
          int totalTimeMs = 0;
          int totalChars = 0;
          for (var delta in chunkDeltas) {
            totalTimeMs += delta.$1;
            totalChars += delta.$2;
          }
          if (totalTimeMs > 0 && totalChars > 0) {
            avgSpeed = totalChars / (totalTimeMs / 1000.0);
          }
        }
        int delayMs = (1000 / avgSpeed).round().clamp(10, 200); // clamp for reasonable delays
        String displayed = '';
        for (int i = 0; i < buffer.length; i++) {
          displayed += buffer[i];
          assistantMessage.text = displayed;
          notifyListeners();
          yield buffer[i];
          if (i < buffer.length - 1) {
            await Future.delayed(Duration(milliseconds: delayMs));
          }
        }
      }
    } catch (e) {
      debugPrint('Error in OpenAI stream: $e');
      assistantMessage.text = 'Ошибка: $e';
      notifyListeners();
    } finally {
      _isStreaming = false;
      notifyListeners();
    }
  }

  @override
  Stream<String> generateStream(String prompt, {Iterable<Attachment>? attachments}) async* {
    final List<ChatCompletionMessage> openaiMessages = [
      // ДОБАВЛЕНО: System prompt если не пустой
      if (systemPrompt.isNotEmpty)
        ChatCompletionMessage.system(content: systemPrompt)
      else
        ChatCompletionMessage.system(content: 'You are a helpful assistant.'),
      ChatCompletionMessage.user(
        content: ChatCompletionUserMessageContent.string(prompt),
      ),
    ];

    Stream<CreateChatCompletionStreamResponse> stream;
    try {
      stream = _client.createChatCompletionStream(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId(_model),
          messages: openaiMessages,
          stream: true,
          temperature: _temperature,
          topP: _topP,
          maxTokens: _maxTokens,
        ),
      );
      debugPrint('OpenAI generate stream started.');
    } catch (e) {
      debugPrint('Error starting generate stream: $e');
      yield '';
      return;
    }

    String buffer = '';
    try {
      await for (final res in stream) {
        final choices = res.choices;
        if (choices != null && choices.isNotEmpty) {
          final choice = choices.first;
          final delta = choice.delta;
          if (delta != null) {
            final deltaText = delta.content ?? '';
            if (deltaText.isNotEmpty) {
              buffer += deltaText;
              yield deltaText;
            }
          }
        }
      }
      debugPrint('Generate stream completed.');
    } catch (e) {
      debugPrint('Error in generate stream: $e');
    }
  }
}