# Copyright(c) 2024 NVIDIA Corporation. All rights reserved.

# NVIDIA Corporation and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA Corporation is strictly prohibited.

from fastapi import APIRouter, status, Body, Response
from fastapi.responses import StreamingResponse
import logging
import os
import sys
import json
import operator
from typing import Annotated, List, Tuple, TypedDict, Union, Dict

from langchain.agents import create_openai_functions_agent
from langchain.chains.openai_functions import (
    create_openai_fn_runnable,
    create_structured_output_runnable,
)
from langchain_community.tools.tavily_search import TavilySearchResults
from langchain_core.messages import HumanMessage, SystemMessage
from langchain_core.prompts import (
    ChatPromptTemplate,
    HumanMessagePromptTemplate,
    MessagesPlaceholder,
    PromptTemplate,
    SystemMessagePromptTemplate,
)
from langchain_core.pydantic_v1 import BaseModel, Field
from langchain_openai import ChatOpenAI
from langgraph.graph import END, StateGraph
from langgraph.prebuilt import create_agent_executor

logger = logging.getLogger("plugin")
router = APIRouter()

sys.path.append(os.path.dirname(__file__))

from schemas import ChatRequest, EventRequest, EventResponse, ChatResponse, FALLBACK_RESPONSE

EVENTS_NOT_REQUIRING_RESPONSE = [
    "system.event_pipeline_acquired",
    "system.event_pipeline_released",
    "system.event_exit",
]

#### The execution agent and prompts ####

tools = [TavilySearchResults(max_results=3)]

tool_prompt = ChatPromptTemplate(
    input_variables=["agent_scratchpad", "input"],
    input_types={
        "chat_history": Union[SystemMessage, HumanMessage],
        "agent_scratchpad": Union[SystemMessage, HumanMessage],
    },
    messages=[
        SystemMessagePromptTemplate(prompt=PromptTemplate(input_variables=[], template="You are a helpful assistant")),
        MessagesPlaceholder(variable_name="chat_history", optional=True),
        HumanMessagePromptTemplate(prompt=PromptTemplate(input_variables=["input"], template="{input}")),
        MessagesPlaceholder(variable_name="agent_scratchpad"),
    ],
)

llm = ChatOpenAI(model="gpt-4-turbo")

# Construct the OpenAI Functions agent
agent_runnable = create_openai_functions_agent(llm, tools, tool_prompt)
agent_executor = create_agent_executor(agent_runnable, tools)

#### Planning and State Management ####


class PlanExecute(TypedDict):
    input: str
    plan: List[str]
    past_steps: Annotated[List[Tuple], operator.add]
    response: str


class Plan(BaseModel):
    """Plan to follow in future"""

    steps: List[str] = Field(description="different steps to follow, should be in sorted order")


planner_prompt = ChatPromptTemplate.from_template(
    """For the given objective, come up with a simple step by step plan. \
This plan should involve individual tasks, that if executed correctly will yield the correct answer. Do not add any superfluous steps. \
The result of the final step should be the final answer. Make sure that each step has all the information needed - do not skip steps.

{objective}"""
)
planner = create_structured_output_runnable(Plan, ChatOpenAI(model="gpt-4-turbo", temperature=0), planner_prompt)


class PlanResponse(BaseModel):
    """Response to user."""

    response: str


replanner_prompt = ChatPromptTemplate.from_template(
    """For the given objective, come up with a simple step by step plan. \
This plan should involve individual tasks, that if executed correctly will yield the correct answer. Do not add any superfluous steps. \
The result of the final step should be the final answer. Make sure that each step has all the information needed - do not skip steps.

Your objective was this:
{input}

Your original plan was this:
{plan}

You have currently done the follow steps:
{past_steps}

Update your plan accordingly. If no more steps are needed and you can return to the user, then respond with that. Otherwise, fill out the plan. Only add steps to the plan that still NEED to be done. Do not return previously done steps as part of the plan."""
)

replanner = create_openai_fn_runnable(
    [Plan, PlanResponse],
    ChatOpenAI(model="gpt-4-turbo", temperature=0),
    replanner_prompt,
)

#### Creating the edges of the graph ####


async def execute_step(state: PlanExecute):
    task = state["plan"][0]
    agent_response = await agent_executor.ainvoke({"input": task, "chat_history": []})
    return {"past_steps": (task, agent_response["agent_outcome"].return_values["output"])}


async def plan_step(state: PlanExecute):
    plan = await planner.ainvoke({"objective": state["input"]})
    return {"plan": plan.steps}


async def replan_step(state: PlanExecute):
    output = await replanner.ainvoke(state)
    if isinstance(output, PlanResponse):
        return {"response": output.response}
    else:
        return {"plan": output.steps}


def should_end(state: PlanExecute):
    if state.get("response"):
        return True
    else:
        return False


#### Creating the graph ####

workflow = StateGraph(PlanExecute)

# Add the plan node
workflow.add_node("planner", plan_step)

# Add the execution step
workflow.add_node("agent", execute_step)

# Add a replan node
workflow.add_node("replan", replan_step)

workflow.set_entry_point("planner")

# From plan we go to agent
workflow.add_edge("planner", "agent")

# From agent, we replan
workflow.add_edge("agent", "replan")

workflow.add_conditional_edges(
    "replan",
    # The function that determines whether execution should end or not
    should_end,
    {
        True: END,
        False: "agent",
    },
)

app = workflow.compile()


@router.post(
    "/chat",
    status_code=status.HTTP_200_OK,
)
async def chat(
    request: Annotated[
        ChatRequest,
        Body(
            description="Chat Engine Request JSON. All the fields populated as part of this JSON is also available as part of request JSON."
        ),
    ],
    response: Response,
) -> ChatResponse:
    """
    This endpoint can be used to provide response to query driven user request.
    """

    req = request.dict(exclude_none=True)
    logger.info(f"Received request JSON at /chat endpoint: {json.dumps(req, indent=4)}")

    try:

        async def generator(query: str):

            if query:
                answer = ChatResponse()
                inputs = {"input": req["Query"]}
                config = {"recursion_limit": 50}
                final_response = {}
                async for event in app.astream(inputs, config=config):
                    for k, v in event.items():
                        if k != "__end__":
                            logger.info(v)
                            final_response = v

                if final_response and "response" in final_response:
                    answer.Response.Text = final_response["response"]
                    answer.Response.CleanedText = final_response["response"]

                elif final_response:
                    answer.Response.Text = FALLBACK_RESPONSE
                    answer.Response.CleanedText = FALLBACK_RESPONSE

                answer = json.dumps(answer.dict())
                yield answer

            json_chunk = ChatResponse()
            json_chunk.Response.IsFinal = True
            json_chunk.Response.CleanedText = ""
            json_chunk = json.dumps(json_chunk.dict())
            yield json_chunk

        return StreamingResponse(generator(req["Query"]), media_type="text/event-stream")

    except Exception as e:
        response.status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
        return {"StatusMessage": str(e)}


@router.post("/event", status_code=status.HTTP_200_OK)
async def event(
    request: Annotated[
        EventRequest,
        Body(
            description="Chat Engine Request JSON. All the fields populated as part of this JSON is also available as part of request JSON."
        ),
    ],
    response: Response,
) -> Union[EventResponse, Dict[str, str]]:
    """
    This endpoint can be used to provide response to an event driven user request.
    """

    req = request.dict(exclude_none=True)
    logger.info(f"Received request JSON at /event endpoint: {json.dumps(req, indent=4)}")

    try:
        resp = EventResponse()
        resp.UserId = req["UserId"]
        resp.Response.IsFinal = True

        if req["EventType"] in EVENTS_NOT_REQUIRING_RESPONSE:
            resp.Response.NeedUserResponse = False

        return resp
    except Exception as e:
        response.status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
        return {"StatusMessage": str(e)}
