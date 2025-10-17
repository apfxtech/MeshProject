import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import '../../services/meshtastic.dart';
import '../../data/repo/chats.dart';
import '../../data/models/message.dart';

class MeshtasticProvider extends LlmProvider with ChangeNotifier {
  List<ChatMessage> _history = [];
  final int? chatId;
  final MeshtasticClient? client;
  static final Map<int, MeshtasticProvider> _providers = {};

  MeshtasticProvider({this.chatId, this.client, Iterable<ChatMessage>? initialHistory}) {
    if (initialHistory != null) {
      _history = initialHistory.toList();
    }
    if (chatId != null) {
      _providers[chatId!] = this;
    }
    _loadHistoryFromDb();
  }

  static void removeProvider(int? chatId) {
    if (chatId != null) {
      _providers.remove(chatId);
    }
  }

  static void notifyNewMessage(int chatId) {
    final provider = _providers[chatId];
    if (provider != null) {
      provider._loadHistoryFromDb();
    }
  }

  Future<void> _loadHistoryFromDb() async {
    if (chatId == null) return;
    final messages = await ChatsRepository.messages(chatId!).get();
    _history = messages.map((msg) => _messageToChatMessage(msg)).toList();
    notifyListeners();
  }

  @override
  Iterable<ChatMessage> get history => _history;

  @override
  set history(Iterable<ChatMessage> value) {
    _history = value.toList();
    notifyListeners();
  }

  @override
  Stream<String> generateStream(String prompt, {Iterable<Attachment> attachments = const []}) {
    return Stream.value('echo: $prompt');
  }

  @override
  Stream<String> sendMessageStream(String prompt, {Iterable<Attachment> attachments = const []}) async* {
    if (chatId == null) {
      yield 'No chat selected';
      return;
    }

    final chat = await ChatsRepository.getChat(chatId!);
    if (chat == null) {
      yield 'Chat not found';
      return;
    }

    final userMsg = ChatMessage.user(prompt, attachments);
    _history.add(userMsg);
    notifyListeners();

    String? destHex;
    bool isMesh = false;
    int? channelIndex;

    if (chat.source.startsWith('n:')) {
      destHex = chat.source.substring(2);
      isMesh = true;
    } else if (chat.assistant.startsWith('n:')) {
      destHex = chat.assistant.substring(2);
      isMesh = true;
    } else if (chat.source.startsWith('c:')) {
      channelIndex = int.parse(chat.source.substring(2));
      isMesh = true;
    }

    if (isMesh) {
      if (client == null) {
        yield 'Client not available';
        return;
      }

      if (channelIndex != null) {
        await client?.sendTextMessage(prompt, channel: channelIndex);
      } else if (destHex != null) {
        int destId = int.parse(destHex, radix: 16);
        await client?.sendTextMessage(prompt, destinationId: destId);
      }

      yield '';
    } 

    final dbUserMsg = _chatMessageToMessage(userMsg, role: 'user', dest: destHex ?? '');
    await ChatsRepository.messages(chatId!).add(dbUserMsg);
  }

  ChatMessage _messageToChatMessage(Message msg) {
    return ChatMessage(
      origin: msg.role == 'user' ? MessageOrigin.user : MessageOrigin.llm,
      text: msg.content,
      attachments: const [],
    );
  }

  Message _chatMessageToMessage(ChatMessage chatMsg, {required String role, String dest = ''}) {
    return Message(
      role: role,
      content: chatMsg.text ?? '',
      origin: chatMsg.origin == MessageOrigin.user ? 'user' : 'llm',
      hops: 0,
      dest: dest,
      date: DateTime.now(),
    );
  }
}
