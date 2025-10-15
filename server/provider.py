from openai import OpenAI
import os, json

class OpenAiProvider:
    def __init__(self, model=None, api_key=None, base_url=None, store_path="history.json"):
        self.store_path = store_path
        self.config = {
            "model": model or "cognitivecomputations/dolphin-mistral-24b-venice-edition:free",
            "api_key": api_key or self._load_key(),
            "base_url": base_url or "https://api.proxyapi.ru/openrouter/v1",
        }
        self.client = OpenAI(api_key=self.config["api_key"], base_url=self.config["base_url"])
        self.histories = self._load_store()

    def _load_key(self):
        with open(".key", "r") as f:
            return f.read().strip()

    def _load_store(self):
        if os.path.exists(self.store_path):
            with open(self.store_path, "r") as f:
                return json.load(f)
        return {}

    def _save_store(self):
        with open(self.store_path, "w") as f:
            json.dump(self.histories, f, ensure_ascii=False, indent=2)

    def set(self, params: dict):
        self.config.update(params)
        self.client = OpenAI(api_key=self.config["api_key"], base_url=self.config["base_url"])

    def ask(self, user_id: str, text: str) -> str:
        if user_id not in self.histories:
            self.histories[user_id] = []
        self.histories[user_id].append({"role": "user", "content": text})
        completion = self.client.chat.completions.create(
            model=self.config["model"],
            messages=self.histories[user_id],
            max_tokens=200,
        )
        answer = completion.choices[0].message.content.strip()[:175]
        self.histories[user_id].append({"role": "assistant", "content": answer})
        self._save_store()
        return answer

    def clear(self, user_id: str):
        if user_id in self.histories:
            del self.histories[user_id]
            self._save_store()