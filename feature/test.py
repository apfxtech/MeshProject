import os
import sys
from openai import OpenAI
import time

# Псевдографические символы для рамок в стиле MS-DOS
BOX_TOP_LEFT = '╔'
BOX_TOP_RIGHT = '╗'
BOX_BOTTOM_LEFT = '╚'
BOX_BOTTOM_RIGHT = '╝'
BOX_HORIZONTAL = '═'
BOX_VERTICAL = '║'
BOX_TOP_T = '╦'
BOX_BOTTOM_T = '╩'
BOX_LEFT_T = '╠'
BOX_RIGHT_T = '╣'
BOX_CROSS = '╬'

# Цвета ANSI для стиля MS-DOS (синий фон, белый текст, но адаптировано для терминала)
BLUE = '\033[44m'
WHITE = '\033[37m'
GREEN = '\033[32m'
RED = '\033[31m'
RESET = '\033[0m'
BOLD = '\033[1m'

def clear_screen():
    """Очистка экрана для имитации перерисовки."""
    os.system('cls' if os.name == 'nt' else 'clear')

def draw_border(width, height, title=""):
    """Рисует псевдографическую рамку."""
    lines = []
    # Верхняя линия
    top_line = BOX_TOP_LEFT + BOX_HORIZONTAL * (width - 2) + BOX_TOP_RIGHT
    if title:
        title_pad = (width - len(title) - 4) // 2
        top_line = BOX_TOP_LEFT + BOX_HORIZONTAL * title_pad + ' ' + title + ' ' + BOX_HORIZONTAL * (width - title_pad - len(title) - 3) + BOX_TOP_RIGHT
    lines.append(top_line)
    
    # Средние линии
    for _ in range(height - 2):
        lines.append(BOX_VERTICAL + ' ' * (width - 2) + BOX_VERTICAL)
    
    # Нижняя линия
    bottom_line = BOX_BOTTOM_LEFT + BOX_HORIZONTAL * (width - 2) + BOX_BOTTOM_RIGHT
    lines.append(bottom_line)
    
    return lines

def print_colored(text, color=WHITE):
    """Выводит текст с цветом."""
    print(f"{color}{text}{RESET}")

def main():
    client = OpenAI(
        base_url = "https://api.proxyapi.ru/openrouter/v1",
        api_key="sk-ewl70MJkW1XLn2BYqNE9PlWuLm9gT0eY")
    
    # Параметры чата
    chat_history = []
    screen_width = 80
    screen_height = 24  # Стандартный DOS-экран
    
    print_colored("Инициализация MS-DOS AI CHAT v1.0", BLUE + BOLD)
    time.sleep(1)
    clear_screen()
    
    while True:
        clear_screen()
        
        # Заголовок
        header_lines = draw_border(screen_width, 3, " MS-DOS AI CHAT - OpenAI Interface ")
        for line in header_lines:
            print_colored(line, BLUE)
        
        print()  # Пустая строка
        
        # Область сообщений (центральная панель)
        messages_height = screen_height - 8  # Оставляем место для ввода и статуса
        messages_lines = draw_border(screen_width, messages_height + 2, " Conversation ")
        
        # Выводим историю сообщений
        message_area = []
        for i, msg in enumerate(chat_history[- (messages_height - 2): ]):  # Последние сообщения
            if msg['role'] == 'user':
                prefix = f"{GREEN}USER:{RESET} "
            elif msg['role'] == 'assistant':
                prefix = f"{WHITE}AI:{RESET} "
            else:
                prefix = ""
            wrapped = wrap_text(msg['content'], screen_width - 4)
            message_area.extend([f"{BOX_VERTICAL} {prefix}{line}" for line in wrapped])
        
        # Заполняем оставшееся пространство пустыми строками
        while len(message_area) < messages_height - 2:
            message_area.append(BOX_VERTICAL + ' ' * (screen_width - 2) + BOX_VERTICAL)
        
        # Собираем полную панель сообщений
        full_messages = [messages_lines[0]]  # Верх
        full_messages.extend(message_area)
        full_messages.append(messages_lines[-1])  # Низ
        
        for line in full_messages:
            print(line)
        
        print()  # Пустая строка
        
        # Поле ввода (нижняя панель)
        input_lines = draw_border(screen_width, 3, " Enter Message (Ctrl+C to Exit) ")
        for line in input_lines[:-1]:  # Все кроме нижней
            print(line)
        
        # Подсказка
        print_colored(f"{BOX_VERTICAL} > ", WHITE, end='')
        sys.stdout.flush()
        
        try:
            user_input = input().strip()
            if not user_input:
                continue
            
            # Добавляем сообщение пользователя
            chat_history.append({'role': 'user', 'content': user_input})
            
            # Отправка в OpenAI
            print_colored("AI thinking...", WHITE)
            response = client.chat.completions.create(
                model="gpt-3.5-turbo",  # Или gpt-4, если доступно
                messages=chat_history
            )
            ai_reply = response.choices[0].message.content
            
            # Добавляем ответ AI
            chat_history.append({'role': 'assistant', 'content': ai_reply})
            
            # Короткая пауза для имитации загрузки
            time.sleep(0.5)
            
        except KeyboardInterrupt:
            clear_screen()
            print_colored("Exiting MS-DOS AI CHAT. Goodbye!", BLUE + BOLD)
            sys.exit(0)
        except Exception as e:
            print_colored(f"Error: {str(e)}", RED)
            time.sleep(2)

def wrap_text(text, width):
    """Переносит текст по ширине."""
    words = text.split(' ')
    lines = []
    current_line = []
    for word in words:
        if len(' '.join(current_line + [word])) <= width:
            current_line.append(word)
        else:
            lines.append(' '.join(current_line))
            current_line = [word]
    if current_line:
        lines.append(' '.join(current_line))
    return lines

if __name__ == "__main__":
    main()