// lib/pages/home/chat.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import '../../services/meshtastic.dart';
import '../../services/providers/mesh.dart';
import '../../services/providers/openai.dart';
import '../../data/repo/chats.dart';

class ChatView extends StatefulWidget {
  final MeshtasticClient client;
  final bool isClientInitialized;
  final ScrollController? scrollController;
  final int? selectedChatId;

  const ChatView({
    super.key,
    required this.client,
    this.isClientInitialized = false,
    this.scrollController,
    this.selectedChatId,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  LlmProvider? provider;

  @override
  void initState() {
    super.initState();
    _initProvider();
  }

  @override
  void didUpdateWidget(covariant ChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedChatId != widget.selectedChatId) {
      if (oldWidget.selectedChatId != null) {
        MeshtasticProvider.removeProvider(oldWidget.selectedChatId);
      }
      _initProvider();
    }
  }

  Future<void> _initProvider() async {
    if (widget.selectedChatId == null) return;

    final chat = await ChatsRepository.getChat(widget.selectedChatId!);
    if (chat == null) return;

    final msgs = await ChatsRepository.messages(chat.id).get();
    final hist = msgs.map((m) {
      if (m.origin == 'user' || m.role == 'user') {
        return ChatMessage(
          origin: MessageOrigin.user,
          text: m.content,
          attachments: const [],
        );
      } else {
        return ChatMessage(
          origin: MessageOrigin.llm,
          text: m.content,
          attachments: const [],
        );
      }
    }).toList();

    LlmProvider newProvider;
    if (chat.source.startsWith('o:')) {
      final model = 'deepseek/deepseek-chat-v3.1:free';
      final apiKey = 'sk-ewl70MJkW1XLn2BYqNE9PlWuLm9gT0eY'; // Assuming chat.key holds the API key
      final baseUrl = 'https://api.proxyapi.ru/openrouter/v1'; // Hardcoded default base URL
      newProvider = OpenAIProvider(
        apiKey: apiKey,
        baseUrl: baseUrl,
        model: model,
        temperature: chat.temperature,
        topP: chat.top_p,
        maxTokens: chat.max_tokens.toDouble(),
        initialHistory: hist,
        systemPrompt: chat.system,
      );
    } else {
      newProvider = MeshtasticProvider(chatId: widget.selectedChatId, client: widget.client);
      newProvider.history = hist;
    }

    setState(() {
      provider = newProvider;
    });
  }

  @override
  void dispose() {
    if (widget.selectedChatId != null) {
      MeshtasticProvider.removeProvider(widget.selectedChatId);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedChatId == null) {
      return const Center(child: Text('Выберите чат'));
    }

    if (provider == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final colorScheme = Theme.of(context).colorScheme;
    final iconDecorationBtn = BoxDecoration(
      color: colorScheme.tertiaryContainer,
      shape: BoxShape.circle,
    );
    final actionButtonStyle = ActionButtonStyle(
      iconDecoration: iconDecorationBtn,
      iconColor: colorScheme.onTertiaryContainer,
    );
    final iconDecorationBtnDis = BoxDecoration(
      color: colorScheme.tertiaryContainer,
      shape: BoxShape.circle,
    );
    final disableButtonStyle = ActionButtonStyle(
      iconDecoration: iconDecorationBtnDis,
      iconColor: colorScheme.onTertiaryFixed,
    );
    final markdownStyleAssistant = MarkdownStyleSheet(
      p: TextStyle(color: colorScheme.onSecondaryContainer),
    );
    final chatStyle = LlmChatViewStyle(
      backgroundColor: colorScheme.surface,
      userMessageStyle: UserMessageStyle(
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: TextStyle(color: colorScheme.onPrimaryContainer),
      ),
      llmMessageStyle: LlmMessageStyle(
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        markdownStyle: markdownStyleAssistant,
      ),
      chatInputStyle: ChatInputStyle(
        backgroundColor: colorScheme.surfaceContainer,
        textStyle: TextStyle(color: colorScheme.onTertiaryContainer),
        hintStyle: TextStyle(color: colorScheme.onTertiaryContainer.withValues(alpha: 0.8)),
        hintText: 'Введите свой запрос...',
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer,
          border: Border.all(width: 1, color: colorScheme.onTertiaryContainer),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      submitButtonStyle: actionButtonStyle,
      attachFileButtonStyle: actionButtonStyle,
      stopButtonStyle: actionButtonStyle,
      addButtonStyle: actionButtonStyle,
      recordButtonStyle: actionButtonStyle,
      disabledButtonStyle: disableButtonStyle,
    );

    return LlmChatView(
      provider: provider!,
      style: chatStyle,
      enableAttachments: false,
      enableVoiceNotes: false,
    );
  }
}