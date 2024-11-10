# Instructions to run

This bot uses Langgraph's [Plan and Execute](https://github.com/langchain-ai/langgraph/blob/main/examples/plan-and-execute/plan-and-execute.ipynb) example to answer complex factual questions. It uses OpenAI's ``gpt-4-turbo-preview`` model to plan the tasks needed to be done, and Tavily to perform internet searches.

## Sample queries

```shell
Q. Who is older - the US president or the Indian Prime Minister?

{'plan': ['Find the current date.', 'Identify the current US president.', 'Find the birthdate of the current US president.', 'Identify the current Indian Prime Minister.', 'Find the birthdate of the current Indian Prime Minister.', 'Compare the birthdates of the US president and the Indian Prime Minister.', 'Determine who is older based on the comparison of their birthdates.']}
{'past_steps': ('Find the current date.', "Today's date is December 7, 2023.")}
{'plan': ['Identify the current US president.', 'Find the birthdate of the current US president.', 'Identify the current Indian Prime Minister.', 'Find the birthdate of the current Indian Prime Minister.', 'Compare the birthdates of the US president and the Indian Prime Minister.', 'Determine who is older based on the comparison of their birthdates.']}
{'past_steps': ('Identify the current US president.', 'The current President of the United States is Joe Biden.')}
{'plan': ['Find the birthdate of the current US president Joe Biden.', 'Identify the current Indian Prime Minister.', 'Find the birthdate of the current Indian Prime Minister.', 'Compare the birthdates of Joe Biden and the Indian Prime Minister.', 'Determine who is older based on the comparison of their birthdates.']}
{'past_steps': ('Find the birthdate of the current US president Joe Biden.', 'Joe Biden was born on November 20, 1942.')}
{'plan': ['Identify the current Indian Prime Minister.', 'Find the birthdate of the current Indian Prime Minister.', 'Compare the birthdates of Joe Biden and the Indian Prime Minister.', 'Determine who is older based on the comparison of their birthdates.']}
{'past_steps': ('Identify the current Indian Prime Minister.', 'The current Prime Minister of India is Narendra Modi. He has been in office since May 26, 2014.')}
{'plan': ['Find the birthdate of the current Indian Prime Minister Narendra Modi.', 'Compare the birthdates of Joe Biden and Narendra Modi.', 'Determine who is older based on the comparison of their birthdates.']}
{'past_steps': ('Find the birthdate of the current Indian Prime Minister Narendra Modi.', 'Narendra Modi was born on September 17, 1950.')}
{'plan': ['Compare the birthdates of Joe Biden and Narendra Modi.', 'Determine who is older based on the comparison of their birthdates.']}
{'past_steps': ('Compare the birthdates of Joe Biden and Narendra Modi.', 'Joe Biden was born on November 20, 1942, while Narendra Modi was born on September 17, 1950. This makes Joe Biden older than Narendra Modi.')}
{'response': 'No further steps are needed. The final answer is that Joe Biden is older than Narendra Modi.'}
```
