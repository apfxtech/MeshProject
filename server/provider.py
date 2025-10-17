from openai import OpenAI
import os, json

class OpenAiProvider:
    def __init__(self, model=None, api_key=None, base_url=None, store_path="store.json"):
        self.store_path = store_path
        self.default_config = {
            "model": model or "cognitivecomputations/dolphin-mistral-24b-venice-edition:free",
            "api_key": api_key or self._load_key(),
            "base_url": base_url or "https://api.proxyapi.ru/openrouter/v1",
        }
        self.data = self._load_store()

    def _load_key(self):
        with open(".key", "r") as f:
            return f.read().strip()

    def _load_store(self):
        if os.path.exists(self.store_path):
            with open(self.store_path, "r") as f:
                loaded_data = json.load(f)
            # Migrate old format if necessary
            for user_id, content in list(loaded_data.items()):
                if isinstance(content, list):
                    loaded_data[user_id] = {'history': content, 'config': self.default_config.copy()}
            return loaded_data
        return {}

    def _save_store(self):
        with open(self.store_path, "w") as f:
            json.dump(self.data, f, ensure_ascii=False, indent=2)

    def set(self, user_id: str, params: dict):
        if user_id not in self.data:
            self.data[user_id] = {'history': [], 'config': self.default_config.copy()}
        if 'config' not in self.data[user_id]:
            self.data[user_id]['config'] = self.default_config.copy()
        self.data[user_id]['config'].update(params)
        self._save_store()

    def ask(self, user_id: str, text: str) -> str:
        if user_id not in self.data:
            self.data[user_id] = {'history': [], 'config': self.default_config.copy()}
        user_data = self.data[user_id]
        if 'config' not in user_data:
            user_data['config'] = self.default_config.copy()
        if 'history' not in user_data:
            user_data['history'] = []
        user_data['history'].append({"role": "user", "content": text})
        config = user_data['config']
        client = OpenAI(api_key=config["api_key"], base_url=config["base_url"])
        completion = client.chat.completions.create(
            model=config["model"],
            messages=user_data['history'],
            max_tokens=200,
        )
        answer = completion.choices[0].message.content.strip()[:360]
        user_data['history'].append({"role": "assistant", "content": answer})
        self._save_store()
        return answer
    
    def split_blocks(s: str, size: int = 100) -> list[str]:
        return [s[i:i+size] for i in range(0, len(s), size)]

    def clear(self, user_id: str):
        if user_id in self.data:
            del self.data[user_id]
            self._save_store()