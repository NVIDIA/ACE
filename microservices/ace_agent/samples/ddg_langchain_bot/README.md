# Instructions to run

This bot uses DuckDuckGo to answer questions. Here is somethings you should know before deploying the bot:

Note: The FM requires langchain==1.1, which conflicts with the langchain version used by nemo-guardrails. This affects the native python mode of ACE Agent. To avoid this, create a new virtual environment for the plugin server, where langchain==1.1 will be installed. The original virtual environment should be able to use nemo-guardrails as expected.

This can be avoided by using the bot in the docker flow.

## Sample queries

This bot uses chat history to answer contextual queries.

```shell
Q. Who was the 44th president of the United States?
A. Barack Obama was the 44th US president.

Q. When was he born?
A. Barack Obama was born on 4th August, 1961.

Q. Which state is he from?
A. Barack Obama is from Hawaii.
```
