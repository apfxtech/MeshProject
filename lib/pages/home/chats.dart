// lib/pages/home/chats.dart
import 'dart:convert';
import 'package:flutter/material.dart';

import '../../widgets/avatars.dart';
import '../../widgets/search.dart';

import '../../data/models/message.dart';
import '../../data/models/chat.dart';
import '../../data/models/contact.dart';
import '../../data/repo/chats.dart';

import '../../services/meshtastic.dart';
import '../../services/notification.dart';
import '../../services/providers/mesh.dart';

import 'contacts.dart';
import 'candidates.dart';

class ChatsView extends StatefulWidget {
  final MeshtasticClient client;
  final bool isClientInitialized;
  final int? selectedChatId;
  final Function(int) onChatSelected;
  final Function(int) onDeleteChat;

  const ChatsView({
    super.key,
    required this.client,
    this.isClientInitialized = false,
    required this.selectedChatId,
    required this.onChatSelected,
    required this.onDeleteChat,
  });

  @override
  ChatsViewState createState() => ChatsViewState();
}

class ChatsViewState extends State<ChatsView> {
  List<Chat> _chats = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadChats();
  }

  Future<void> loadChats() async {
    _chats = await ChatsRepository.get();
    setState(() {});
  }

  Future<void> createNewChatWithList() async {
    final Contact? selectedContact = await showModalBottomSheet<Contact>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return const ContactsListWidget();
      },
    );

    if (selectedContact != null) {
      Chat newChat = Chat(
        title: selectedContact.name,
        assistant: selectedContact.type,
        key: 'AQ==', // Default key
        source: '', // Default source
        temperature: 0.7,
        top_p: 0.9,
        max_tokens: 256,
      );
      int id = await ChatsRepository.add(newChat);
      Chat? createdChat = await ChatsRepository.getChat(id);
      if (createdChat != null) {
        _chats.add(createdChat);
        widget.onChatSelected(createdChat.id);
        setState(() {});
      }
    }
  }

  Future<void> createNewChatWithCards() async {
    final Contact? selectedContact = await showModalBottomSheet<Contact>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return const ContactsCardsWidget();
      },
    );

    if (selectedContact != null) {
      Chat newChat = Chat(
        title: selectedContact.name,
        assistant: selectedContact.type,
        key: 'AQ==', // Default key
        source: 'o:', // Default source
        temperature: 0.7,
        top_p: 0.9,
        max_tokens: 256,
      );
      int id = await ChatsRepository.add(newChat);
      Chat? createdChat = await ChatsRepository.getChat(id);
      if (createdChat != null) {
        _chats.add(createdChat);
        widget.onChatSelected(createdChat.id);
        setState(() {});
      }
    }
  }

  Future<void> _deleteChat(int id, int index) async {
    await ChatsRepository.remove(id);
    _chats.removeAt(index);
    widget.onDeleteChat(id);
    setState(() {});
  }

  Widget _buildChatsList() {
    final colorScheme = Theme.of(context).colorScheme;
    if (_chats.isEmpty) {
      return const Center(child: Text('Нет чатов'));
    }

    final lowerQuery = _searchQuery.toLowerCase();
    final filteredChats = _chats.where((chat) {
      final titleLower = chat.title.toLowerCase();
      return titleLower.contains(lowerQuery);
    }).toList();

    return Column(
      children: [
        SearchWidget(
          labelText: 'Поиск чатов:',
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredChats.length,
            itemBuilder: (context, index) {
              final chat = filteredChats[index];
              bool isSelected = chat.id == widget.selectedChatId;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primaryFixedDim
                        : colorScheme.onSurfaceVariant.withAlpha(18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      widget.onChatSelected(chat.id);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AvatarWidget(
                            text: chat.title,
                            size: 48.0,
                            backgroundColor: isSelected
                                ? colorScheme.primaryContainer
                                : colorScheme.tertiaryContainer,
                            foregroundColor: isSelected
                                ? colorScheme.primary
                                : colorScheme.onTertiaryContainer,
                          ),
                          const SizedBox(width: 14.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  chat.title,
                                  style: TextStyle(
                                    color: isSelected
                                        ? colorScheme.onPrimaryFixedVariant
                                        : colorScheme.onSecondaryContainer,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            color: isSelected
                                ? colorScheme.onPrimaryFixedVariant
                                : colorScheme.onTertiaryContainer,
                            tooltip: 'Rename Chat',
                            onPressed: () async {
                              String? newName = await showDialog<String>(
                                context: context,
                                builder: (BuildContext context) {
                                  TextEditingController _controller =
                                      TextEditingController(text: chat.title);
                                  return AlertDialog(
                                    title: const Text('Переименовать чат'),
                                    content: TextField(
                                      controller: _controller,
                                      decoration: const InputDecoration(
                                        hintText: "Новое имя",
                                      ),
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        child: const Text('Отмена'),
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                      ),
                                      TextButton(
                                        child: const Text('OK'),
                                        onPressed: () => Navigator.of(
                                          context,
                                        ).pop(_controller.text),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (newName != null && newName.isNotEmpty) {
                                await ChatsRepository.rename(chat.id, newName);
                                final updatedChat = Chat(
                                  id: chat.id,
                                  title: newName,
                                  key: chat.key,
                                  assistant: chat.assistant,
                                  source: chat.source,
                                  temperature: chat.temperature,
                                  top_p: chat.top_p,
                                  max_tokens: chat.max_tokens,
                                  system: chat.system,
                                  opening: chat.opening,
                                );
                                _chats[_chats.indexWhere(
                                      (c) => c.id == chat.id,
                                    )] =
                                    updatedChat;
                                setState(() {});
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            color: isSelected
                                ? colorScheme.onPrimaryFixedVariant
                                : colorScheme.onTertiaryContainer,
                            tooltip: 'Delete Chat',
                            onPressed: () async {
                              final originalIndex = _chats.indexWhere(
                                (c) => c.id == chat.id,
                              );
                              await _deleteChat(chat.id, originalIndex);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildChatsList();
  }
}

Future<void> handleIncomingMessage(
  MeshtasticClient client,
  MeshPacketWrapper packet,
) async {
  if (!packet.isTextMessage) return;

  final senderId = packet.from.toRadixString(16);
  final receiverId = packet.to.toRadixString(16);
  final myNodeNum = client.myNodeInfo?.myNodeNum;
  if (myNodeNum == null) return;

  final isBroadcast = packet.to == 0xffffffff;
  final isDM = packet.to == myNodeNum;

  if (!isDM && !isBroadcast) return;

  final senderNode = client.nodes[packet.from];
  final senderName =
      senderNode?.user?.shortName ?? senderNode?.user?.longName.substring(0, 8);

  String chatSource;
  if (isBroadcast) {
    chatSource = "c:${packet.channel}";
  } else {
    chatSource = "n:$senderId";
  }

  Chat? chat = await ChatsRepository.getBySource(chatSource);
  if (chat == null) {
    String title;
    if (isBroadcast) {
      title = (packet.channel == 0) ? 'Global' : 'Channel ${packet.channel}';
    } else {
      title = senderName ?? "Node";
    }
    final newChat = Chat(title: title, source: chatSource, key: "AQ==");
    final chatId = await ChatsRepository.add(newChat);
    chat = await ChatsRepository.getChat(chatId);
  }

  if (chat != null) {
    String pld = utf8.decode(packet.decoded!.payload);
    final messageContent = isBroadcast ? '$senderName: ${pld}' : pld;

    final newMessage = Message(
      role: 'assistant',
      content: messageContent,
      origin: 'llm',
      dest: receiverId,
      date: DateTime.now(),
      hops: 0,
    );

    await NotificationService.sendTextNotification(
      title: senderName.toString(),
      body: packet.textMessage.toString(),
    );

    await ChatsRepository.messages(chat.id).add(newMessage);
    
    MeshtasticProvider.notifyNewMessage(chat.id);
  }
}
