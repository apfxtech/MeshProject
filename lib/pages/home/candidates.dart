import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../../widgets/avatars.dart';
import '../../data/models/contact.dart';
import '../../data/repo/ai_models.dart';

class ContactsCardsWidget extends StatefulWidget {
  const ContactsCardsWidget({super.key});

  @override
  State<ContactsCardsWidget> createState() => _ContactsCardsWidgetState();
}

class _ContactsCardsWidgetState extends State<ContactsCardsWidget> {
  List<Contact> _contacts = [];
  final CardSwiperController _swiperController = CardSwiperController();
  final AiModelRepository _repository = AiModelRepository();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final loadedContacts = await _repository.getAllContacts();
    if (mounted) {
      setState(() {
        _contacts = loadedContacts;
      });
    }
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  void _onContactSelected(Contact contact) {
    debugPrint('Selected contact: ${contact.name}');
    Navigator.of(context).pop(contact);
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    debugPrint(
      'Карточка $previousIndex была смахнута ${direction.name}. Теперь сверху карточка $currentIndex',
    );
    if (direction == CardSwiperDirection.right) {
      _onContactSelected(_contacts[previousIndex]);
    }
    return true;
  }

  bool _onUndo(
    int? previousIndex,
    int currentIndex,
    CardSwiperDirection direction,
  ) {
    debugPrint(
      'Действие для карточки $currentIndex было отменено из ${direction.name}',
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cards = _contacts.map((contact) => ContactCard(contact)).toList();
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: cards.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : CardSwiper(
                    controller: _swiperController,
                    cardsCount: cards.length,
                    onSwipe: _onSwipe,
                    onUndo: _onUndo,
                    numberOfCardsDisplayed: cards.length.clamp(1, 3),
                    backCardOffset: const Offset(40, 40),
                    padding: const EdgeInsets.all(24.0),
                    cardBuilder: (
                      context,
                      index,
                      horizontalThresholdPercentage,
                      verticalThresholdPercentage,
                    ) =>
                        cards[index],
                  ),
          ),
        ],
      ),
    );
  }
}

class ContactCard extends StatelessWidget {
  final Contact contact;

  const ContactCard(this.contact, {super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardHeight = 350.0;

    // Hardcoded values
    const String hardcodedImagePath = 'assets/images/sample_image.jpg';
    const String hardcodedDescription = 'Описание контакта: интересный человек с уникальными навыками.';
    const List<String> hardcodedTags = ['#AI', '#Developer', '#Flutter'];

    return Container(
      width: double.infinity,
      height: cardHeight,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 8,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.asset(
                hardcodedImagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: colorScheme.surfaceVariant,
                  child: const Icon(Icons.image_not_supported, size: 100),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Row(
                    children: [
                      AvatarWidget(imagePath: contact.imagePath, size: 40, text: 'ai'),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          contact.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Expanded(
                    child: Text(
                      hardcodedDescription,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Tags
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: hardcodedTags.map((tag) => Chip(
                      label: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      backgroundColor: colorScheme.primary,
                      visualDensity: VisualDensity.compact,
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}