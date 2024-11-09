from nemoguardrails.actions.actions import action


@action(name="CountWordsAction")
async def count_words_action(transcript: str) -> int:
    return len(transcript.split())
