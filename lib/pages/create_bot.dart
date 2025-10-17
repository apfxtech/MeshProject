// lib/pages/create_bot_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/repo/bots.dart'; 
import '../widgets/avatars.dart'; 

class CreateBotPage extends StatefulWidget {
  final String initialTitle;
  const CreateBotPage({super.key, required this.initialTitle});

  @override
  State<CreateBotPage> createState() => _CreateBotPageState();
}

class _CreateBotPageState extends State<CreateBotPage> with TickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _systemController = TextEditingController();
  final _firstMessageController = TextEditingController(); // ДОБАВЛЕНО: Контроллер для стартового сообщения
  final _modelController = TextEditingController();
  final _apiKeyController = TextEditingController();

  late TabController _tabController;
  String _selectedType = '';
  Set<String> _selectedTags = {};
  bool _isPrivate = false;
  late double _temperature;
  late double _topP;
  late double _maxTokens;

  final List<String> _contactsTypes = [
    'openai',
    'grok',
    'claude',
    'deepseek',
    'gemini',
    'openrouter',
    'custom',
  ];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle;
    _tabController = TabController(length: 2, vsync: this);

    _temperature = 0.8;
    _topP = 0.6;
    _maxTokens = 256;

    _selectedType = 'openai'; 
    _modelController.text = 'gpt-5';
    _apiKeyController.text = 'sk-xxx';
    _systemController.text = '';
    _firstMessageController.text = '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _systemController.dispose();
    _firstMessageController.dispose();
    _modelController.dispose();
    _apiKeyController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  String _getAuthor() {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser?.uid ?? 'anonymous';
  }

  bool _isFormValid() {
    final titleFilled = _titleController.text.isNotEmpty;
    final descriptionFilled = _descriptionController.text.isNotEmpty;
    // ИЗМЕНЕНО: Убрана проверка systemFilled, firstMessage тоже не проверяем
    final typeFilled = _selectedType.isNotEmpty;
    final modelFilled = _modelController.text.isNotEmpty; // Изменено: модель всегда обязательна
    final apiKeyFilled = (_selectedType == 'openrouter' || _selectedType == 'custom') ? _apiKeyController.text.isNotEmpty : true;
    return titleFilled && descriptionFilled && typeFilled && modelFilled && apiKeyFilled;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать бота'),
      ),
      body: Column(
        children: [
           Container(
                color: colorScheme.primaryContainer, // Set background color to primary
                child:TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Личность'),
                    Tab(text: 'Нейросеть'),
                  ],
                ),
           ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AvatarWidget(
                            imagePath: getModelImagePathByType(_selectedType),
                            size: 60,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Имя бота (заголовок)',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Описание бота',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _systemController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Системное сообщение (инструкция)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ДОБАВЛЕНО: Поле для стартового сообщения
                      TextField(
                        controller: _firstMessageController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Стартовое сообщение (инициатор)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Теги', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: BotRepository.allowedTags.map((tag) {
                          final isSelected = _selectedTags.contains(tag);
                          return ChoiceChip(
                            label: Text(tag),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedTags.add(tag);
                                } else {
                                  _selectedTags.remove(tag);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Тип провайдера', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: _contactsTypes.map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.toUpperCase()),
                        )).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedType = value;
                              _modelController.text = DefaultAiSettings.getDefaultModel(value);
                              _apiKeyController.text = DefaultAiSettings.defaultApiKey;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // Изменено: Поле модели всегда отображается
                      TextField(
                        controller: _modelController,
                        decoration: InputDecoration(
                          labelText: 'Модель',
                          hintText: 'Введите ID модели (например, ${_selectedType == 'openai' ? 'gpt-4o' : _selectedType == 'grok' ? 'grok' : _selectedType == 'claude' ? 'claude-3-opus' : _selectedType == 'deepseek' ? 'deepseek-pro' : _selectedType == 'gemini' ? 'gemini-pro' : 'gpt-4o'})',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      // Поле API ключа только для openrouter/custom
                      if (_selectedType == 'openrouter' || _selectedType == 'custom') ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _apiKeyController,
                          decoration: const InputDecoration(
                            labelText: 'API Key',
                            hintText: 'Введите API ключ',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                        ),
                      ],
                      const SizedBox(height: 24),
                      _buildSlider(
                        label: 'Креативность (temperature)',
                        value: _temperature,
                        min: 0.0,
                        max: 2.0,
                        onChanged: (value) => setState(() => _temperature = value),
                        description: 'Контролирует случайность генерации. Высокие значения делают ответы более креативными и разнообразными, низкие - более предсказуемыми и точными. Рекомендуемые значения: 0.2-0.8 для точных задач, 0.8-1.5 для креативных.',
                      ),
                      const SizedBox(height: 16),
                      _buildSlider(
                        label: 'Фокусирование (top_p)',
                        value: _topP,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (value) => setState(() => _topP = value),
                        description: 'Ограничивает выбор слов по кумулятивной вероятности. Низкие значения фокусируют на наиболее вероятных токенах, высокие позволяют больше разнообразия. Рекомендуемые значения: 0.9-1.0.',
                      ),
                      const SizedBox(height: 16),
                      _buildSlider(
                        label: 'Длинна ответа (Max tokens)',
                        value: _maxTokens,
                        min: 256.0,
                        max: 4096.0,
                        onChanged: (value) => setState(() => _maxTokens = value),
                        isInt: true,
                        description: 'Ограничивает максимальную длину ответа в токенах. Высокие значения позволяют длинные ответы, но увеличивают стоимость и время. Рекомендуемые значения: 512-2048 для большинства задач.',
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Checkbox(
                            value: _isPrivate,
                            onChanged: (value) => setState(() => _isPrivate = value ?? false),
                          ),
                          const Text('Приватный бот (только для вас)'),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _isFormValid() ? _createBot : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text('Создать'),
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required String description,
    bool isInt = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          label: isInt ? value.toInt().toString() : value.toStringAsFixed(1),
          onChanged: onChanged,
        ),
        Text(
          isInt ? value.toInt().toString() : value.toStringAsFixed(1),
          style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _createBot() async {
    if (!_isFormValid()) return;

    final data = <String, dynamic>{
      'title': _titleController.text,
      'description': _descriptionController.text,
      'systemChat': _systemController.text,
      'firstMessage': _firstMessageController.text, // ДОБАВЛЕНО
      'chatType': _selectedType,
      'tags': _selectedTags.toList(),
      'image': (_selectedType),
      'author': _getAuthor(),
      'usage': '',
      'isPrivate': _isPrivate,
      'model': _modelController.text, 
      if ((_selectedType == 'openrouter' || _selectedType == 'custom') && _apiKeyController.text.isNotEmpty) 'apiKey': _apiKeyController.text,
      'temperature': _temperature,
      'topP': _topP,
      'maxTokens': _maxTokens,
    };

    try {
      await BotRepository.create(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Бот создан!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }
}