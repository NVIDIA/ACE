# SPDX-FileCopyrightText: Copyright (c) 2022-2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.


# ACE SIMULATOR
# ACE Simulator is a simple command line tool that simulates a basic interactive system that can be used
# with ACE Agent event interface
########################################################################################################################

import asyncio
import json
import logging
import uuid
from abc import ABC, abstractmethod
from collections import deque, namedtuple
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any, Deque, Dict, List, Optional, Tuple, Type, Union
from uuid import uuid4

import redis.asyncio as redis
import typer
from rich import print
from textual.app import App, ComposeResult
from textual.containers import Container, Horizontal, Vertical
from textual.reactive import reactive
from textual.widget import Widget
from textual.widgets import (
    Button,
    Footer,
    Header,
    Input,
    Label,
    Markdown,
    RadioButton,
    Static,
    TextLog,
)
from textual.worker import Worker, WorkerState
from transitions import Machine
from typing_extensions import Annotated

logging.basicConfig(filename="umim_compliance_errors.txt", level=logging.WARNING)
logger = logging.getLogger("ace_sim")

cli = typer.Typer()
stream_id = "1"
channel_id = "umim_events_1"
create_pipeline = False
app_in_active_mode = False
redis_host = "localhost"
redis_port = 6379
ui_sidebar_open = False

SYSTEM_EVENTS_STREAM = "ace_agent_system_events"

MOTION_DURATION = 20

EVENT_FIELDS_TO_HIDE = {
    "uid",
    "action_info_modality",
    "action_info_modality_policy",
    "user_id",
    "bot_id",
    "source_uid",
    "tags",
    "event_created_at",
    "action_started_at",
    "action_finished_at",
    "action_updated_at",
    "type",
}


########################################################################################################################
# UTILITIES
########################################################################################################################


class EventProvider(ABC):
    @abstractmethod
    async def receive_events(self, timeout_ms: Optional[int] = 500) -> List[str]:
        """Receive incoming events. Returns when it received one or more events"""
        raise NotImplementedError

    @abstractmethod
    async def send_event(self, channel_id: str, event_data: Union[str, Dict[str, Any]]) -> None:
        """Publishes the event"""
        raise NotImplementedError


class RedisEventProvider(EventProvider):
    def __init__(
        self,
        redis_host: str,
        redis_port: int,
        channels: List[str],
        discard_existing_events: bool = True,
    ):
        super().__init__()
        self.redis: redis.Redis = redis.Redis(host=redis_host, port=redis_port)
        self._channel_state: Dict[str, str] = dict(
            map(lambda c: (c, "$" if discard_existing_events else "0"), channels)
        )

    async def receive_events(self, timeout_ms: Optional[int] = 500) -> List[str]:
        """Receive incoming events. Returns when it received one or more events"""
        if timeout_ms is not None and timeout_ms < 100:
            logger.warning(f"Redis timeout resolution is about 100ms, but a timeout of {timeout_ms}ms was given.")

        result = await self.redis.xread(streams=self._channel_state, block=timeout_ms)
        event_list: List[str] = []

        for channel in result:
            channel_id = str(channel[0].decode())
            for event_id, value in channel[1]:
                for key in value.keys():
                    event_data = value[key].decode()
                    event_list.append(event_data)

                self._channel_state[channel_id] = event_id.decode()

        return event_list

    async def send_event(self, channel_id: str, event_data: Union[str, Dict[str, Any]]) -> None:
        """Publishes the event"""

        if isinstance(event_data, dict):
            event_data = json.dumps(event_data)

        await self.redis.xadd(channel_id, {"event": event_data.encode()})


def event_provider_factory(
    provider_name: str,
    host: str,
    port: int,
    channels=List[str],
    discard_existing_events: bool = True,
) -> EventProvider:
    providers = ["redis"]
    if provider_name == "redis":
        return RedisEventProvider(host, port, channels, discard_existing_events)
    else:
        raise Exception(f"Event provider {provider_name} does not exist. Available providers { ','.join(providers)}")


def new_uuid() -> str:
    """Helper to create a new UID."""

    return str(uuid.uuid4())


# Very basic event validation - will be replaced by validation based on pydantic models
Property = namedtuple("Property", ["name", "type"])
Validator = namedtuple("Validator", ["description", "function"])


def _has_property(e: Dict[str, Any], p: Property) -> bool:
    return p.name in e and type(e[p.name]) == p.type


_event_validators = [
    Validator("Events need to provide 'type'", lambda e: "type" in e),
    Validator("Events need to provide 'uid'", lambda e: _has_property(e, Property("uid", str))),
    Validator(
        "Events need to provide 'event_created_at' of type 'str'",
        lambda e: _has_property(e, Property("event_created_at", str)),
    ),
    Validator(
        "Events need to provide 'source_uid' of type 'str'",
        lambda e: _has_property(e, Property("source_uid", str)),
    ),
    Validator(
        "***Action events need to provide an 'action_uid' of type 'str'",
        lambda e: "Action" not in e["type"] or _has_property(e, Property("action_uid", str)),
    ),
    Validator(
        "***ActionFinished events require 'action_finished_at' field of type 'str'",
        lambda e: "ActionFinished" not in e["type"] or _has_property(e, Property("action_finished_at", str)),
    ),
    Validator(
        "***ActionFinished events require 'is_success' field of type 'bool'",
        lambda e: "ActionFinished" not in e["type"] or _has_property(e, Property("is_success", bool)),
    ),
    Validator(
        "Unsuccessful ***ActionFinished events need to provide 'failure_reason'.",
        lambda e: "ActionFinished" not in e["type"] or (e["is_success"] or "failure_reason" in e),
    ),
    Validator(
        "***StartUtteranceBotAction events need to provide 'script' of type 'str'",
        lambda e: e["type"] != "StartUtteranceBotAction" or _has_property(e, Property("script", str)),
    ),
    Validator(
        "***UtteranceBotActionScriptUpdated events need to provide 'interim_script' of type 'str'",
        lambda e: e["type"] != "UtteranceBotActionScriptUpdated " or _has_property(e, Property("interim_script", str)),
    ),
    Validator(
        "***UtteranceBotActionFinished events need to provide 'final_script' of type 'str'",
        lambda e: e["type"] != "UtteranceBotActionFinished" or _has_property(e, Property("final_script", str)),
    ),
    Validator(
        "***UtteranceUserActionTranscriptUpdated events need to provide 'interim_transcript' of type 'str'",
        lambda e: e["type"] != "UtteranceUserActionTranscriptUpdated"
        or _has_property(e, Property("interim_transcript", str)),
    ),
    Validator(
        "***UtteranceUserActionFinished events need to provide 'final_transcript' of type 'str'",
        lambda e: e["type"] != "UtteranceUserActionFinished" or _has_property(e, Property("final_transcript", str)),
    ),
]


_action_to_modality_info: Dict[str, Tuple[str, str]] = {
    "UtteranceBotAction": ("bot_speech", "replace"),
    "UtteranceUserAction": ("user_speech", "replace"),
    "VisualChoiceSceneAction": ("information", "override"),
    "VisualInformationSceneAction": ("information", "override"),
    "VisualFormSceneAction": ("information", "override"),
    "GestureBotAction": ("bot_gesture", "override"),
    "TimerBotAction": ("time", "parallel"),
}


def _add_modality_info(event_dict: Dict[str, Any]) -> None:
    """Add modality related information to the action event"""
    for action_name, modality_info in _action_to_modality_info.items():
        modality_name, modality_policy = modality_info
        if action_name in event_dict["type"]:
            event_dict["action_info_modality"] = modality_name
            event_dict["action_info_modality_policy"] = modality_policy


def _update_action_properties(event_dict: Dict[str, Any]) -> None:
    """Update action related even properties and ensure UMIM compliance (very basic)"""

    if "Started" in event_dict["type"]:
        event_dict["action_started_at"] = datetime.now(timezone.utc).isoformat()
    elif "Start" in event_dict["type"]:
        event_dict["action_uid"] = new_uuid()
    elif "Finished" in event_dict["type"]:
        event_dict["action_finished_at"] = datetime.now(timezone.utc).isoformat()
        if event_dict["is_success"] and "failure_reason" in event_dict:
            del event_dict["failure_reason"]


def ensure_valid_event(event: Dict[str, Any]) -> None:
    """Performs basic event validation and throws an AssertionError if any of the validators fail."""
    for validator in _event_validators:
        assert validator.function(event), validator.description


def is_valid_event(event: Dict[str, Any]) -> bool:
    """Performs a basic event validation and returns True if the event conforms."""
    for validator in _event_validators:
        if not validator.function(event):
            return False
    return True


def new_event(event_type: str, **payload) -> Dict[str, Any]:
    """Helper to create a generic event structure."""

    event: Dict[str, Any] = {
        "type": event_type,
        "uid": new_uuid(),
        "event_created_at": datetime.now(timezone.utc).isoformat(),
        "source_uid": "umim_tui_app",
    }

    event = {**event, **payload}

    if "Action" in event_type:
        _add_modality_info(event)
        _update_action_properties(event)

    ensure_valid_event(event)
    return event


def read_isoformat(timestamp: str) -> datetime:
    """
    ISO 8601 has multiple legal ways to indicate UTC timezone. 'Z' or '+00:00'. However the Python
    datetime.fromisoformat only accepts the latter.
    This function provides a more flexible wrapper to accept all valid IOS 8601 formats
    """
    normalized = timestamp.replace("Z", "+00:00")
    return datetime.fromisoformat(normalized)


########################################################################################################################
# EVENT PARSING and PRINTING
########################################################################################################################
def _fix_event(event: Dict[str, Any]) -> None:
    """
    Try to make the event UMIM compatible
    """
    if "created_at" in event:
        event["event_created_at"] = event["created_at"]
        del event["created_at"]


def _type_to_sign(event_type: str) -> str:
    if "Started" in event_type:
        return ":rocket: "
    elif "Start" in event_type:
        return ":play_button:  "
    elif "Stop" in event_type:
        return ":stop_button:  "
    elif "Finished" in event_type:
        return ":stop_sign: "
    elif "Updated" in event_type:
        return ":counterclockwise_arrows_button: "
    elif "Change" in event_type:
        return ":pencil: "
    else:
        return ":frog: "


def _timestamp(show_time: bool, timestamp: Optional[str] = None) -> str:
    if show_time:
        if timestamp:
            date = read_isoformat(timestamp)
            date_str = date.strftime("%m/%d,%H:%M:%S.%f")
            return f"[blue]{date_str}[/blue] "
        else:
            return "                      "
    else:
        return ""


def _event_to_short_str(event: dict, show_time: bool = True) -> str:
    action_info = ""
    if "action_uid" in event:
        action_info = f", id={event['action_uid'][0:4]}.."

    if event["type"] == "StartTimerBotAction":
        param_str = f'"{event["timer_name"]}", duration={event["duration"]}{action_info}'
    elif event["type"] == "TimerBotActionStarted":
        param_str = f'{read_isoformat(event["action_started_at"]).strftime("%H:%M:%S")}{action_info}'
    elif event["type"] == "ChangeTimerBotAction":
        param_str = f"duration={event['duration']}{action_info}"
    elif event["type"] == "StopTimerBotAction":
        param_str = f"{action_info}"
    elif event["type"] == "TimerBotActionFinished":
        if not event["is_success"]:
            status = '"success"' if event["is_success"] else '"failure"'
            reason = f', reason="{event["failure_reason"]}"' if not event["is_success"] else ""
            param_str = f"{status}{reason}{action_info}"
        else:
            if event["was_stopped"]:
                param_str = f"was_stopped=True{action_info}"
            else:
                param_str = f'{read_isoformat(event["action_finished_at"]).strftime("%H:%M:%S")}{action_info}'
    elif event["type"] == "UtteranceUserActionFinished":
        param_str = f'"{event["final_transcript"]}"{action_info}'
    elif event["type"] == "UtteranceUserActionTranscriptUpdated":
        param_str = f'"{event["interim_transcript"]}"{action_info}'
    elif event["type"] == "UtteranceUserActionStarted":
        param_str = action_info

    elif event["type"] == "StartUtteranceBotAction":
        param_str = f'"{event["script"]}"{action_info}'
    elif event["type"] == "UtteranceBotActionStarted":
        param_str = action_info
    elif event["type"] == "StopUtteranceBotAction":
        param_str = action_info
    elif event["type"] == "UtteranceBotActionFinished":
        param_str = f'"{event["final_script"]}"{action_info}'

    elif event["type"] == "StartGestureBotAction":
        param_str = f'"{event["gesture"]}"{action_info}'
    elif event["type"] == "GestureBotActionStarted":
        param_str = action_info
    elif event["type"] == "StopGestureBotAction":
        param_str = action_info
    elif event["type"] == "GestureBotActionFinished":
        status = '"success"' if event["is_success"] else '"failure"'
        was_stopped = f", was_stopped={'True' if event['was_stopped'] else 'False'}"
        reason = f', reason="{event["failure_reason"]}"' if not event["is_success"] else ""
        param_str = f"{status}{reason}{was_stopped}{action_info}"

    elif event["type"] == "StartPostureBotAction":
        param_str = f'"{event["posture"]}"{action_info}'
    elif event["type"] == "PostureBotActionStarted":
        param_str = action_info
    elif event["type"] == "StopPostureBotAction":
        param_str = action_info
    elif event["type"] == "PostureBotActionFinished":
        status = '"success"' if event["is_success"] else '"failure"'
        reason = f', reason="{event["failure_reason"]}"' if not event["is_success"] else ""
        param_str = f"{status}{reason}{action_info}"

    elif event["type"] == "AttentionUserActionStarted":
        param_str = f"level={event['attention_level']}{action_info}"
    elif event["type"] == "AttentionUserActionUpdated":
        param_str = f"level={event['attention_level']}{action_info}"
    elif event["type"] == "AttentionUserActionFinished":
        status = '"success"' if event["is_success"] else '"failure"'
        reason = f', reason="{event["failure_reason"]}"' if not event["is_success"] else ""
        param_str = f"{status}{reason}{action_info}"

    elif event["type"] == "PresenceUserActionStarted":
        param_str = action_info
    elif event["type"] == "PresenceUserActionFinished":
        status = '"success"' if event["is_success"] else '"failure"'
        reason = f', reason="{event["failure_reason"]}"' if not event["is_success"] else ""
        param_str = f"{status}{reason}{action_info}"

    elif event["type"] == "StartVisualInformationSceneAction":
        param_str = f'"{event["title"]}", summary={event.get("summary","")}{action_info}'
    elif event["type"] == "VisualInformationSceneActionStarted":
        param_str = action_info
    elif event["type"] == "StopVisualInformationSceneAction":
        param_str = action_info
    elif event["type"] == "VisualInformationSceneActionConfirmationUpdated":
        param_str = f"{event['confirmation_status']}{action_info}"
    elif event["type"] == "VisualInformationSceneActionFinished":
        status = '"success"' if event["is_success"] else '"failure"'
        reason = f', reason="{event["failure_reason"]}"' if not event["is_success"] else ""
        param_str = f"{status}{reason}{action_info}"

    elif event["type"] == "StartVisualChoiceSceneAction":
        param_str = f'"{event["prompt"]}"{action_info}'
    elif event["type"] == "VisualChoiceSceneActionStarted":
        param_str = action_info
    elif event["type"] == "VisualChoiceSceneActionConfirmationUpdated":
        param_str = f"{event['confirmation_status']}{action_info}"
    elif event["type"] == "VisualChoiceSceneActionChoiceUpdated":
        param_str = f"{event['current_choice']}{action_info}"
    elif event["type"] == "StopVisualChoiceSceneAction":
        param_str = action_info
    elif event["type"] == "VisualChoiceSceneActionFinished":
        status = '"success"' if event["is_success"] else '"failure"'
        reason = f', reason="{event["failure_reason"]}"' if not event["is_success"] else ""
        param_str = f"{status}{reason}{action_info}"

    elif event["type"] == "StartVisualFormSceneAction":
        param_str = f'"{event["prompt"]}"{action_info}'
    elif event["type"] == "VisualFormSceneActionStarted":
        param_str = action_info
    elif event["type"] == "VisualFormSceneActionConfirmationUpdated":
        param_str = f"{event['confirmation_status']}{action_info}"
    elif event["type"] == "VisualFormSceneActionInputUpdated":
        inputs = ",".join([f'{input["id"]}="{input["value"]}"' for input in event["interim_inputs"]])
        param_str = f"{inputs}{action_info}"
    elif event["type"] == "StopVisualFormSceneAction":
        param_str = action_info
    elif event["type"] == "VisualFormSceneActionFinished":
        status = '"success"' if event["is_success"] else '"failure"'
        reason = f', reason="{event["failure_reason"]}"' if not event["is_success"] else ""
        param_str = f"{status}{reason}{action_info}"

    elif event["type"] == "UserIntent":
        param_str = f'"{event["intent"]}"'
    elif event["type"] == "BotIntent":
        param_str = f'"{event["intent"]}"'
    else:
        param_str = ",".join([f"{key}={value}" for key, value in event.items()])

    return (
        f"{_timestamp(show_time, event['event_created_at'])}{_type_to_sign(event['type'])}{event['type']}({param_str})"
    )


def pretty_event(event_data: Dict[str, Any], show_time: bool = True, strict: bool = True) -> str:
    try:
        if not strict:
            _fix_event(event_data)

        if event_data["type"] == "Error":
            return f"[red]ERROR[/red] {event_data['reason']}"

        if event_data["type"] == "Listen":
            return f"[blue][Legacy Event][/blue] Listen()"

        if "InternalSystemAction" in event_data["type"]:
            return f"[blue][Internal][/blue] {event_data['type']}()"

        return _event_to_short_str(event_data, show_time)

    except Exception as ex:
        logging.error(f"[Malformed] " + str(event_data) + f"\n[Error] {str(ex)}\n\n")
        return ":ogre: [Malformed] " + str(event_data)


def try_parse_event(data):
    if isinstance(data, str):
        data = json.loads(data)
    return data


def get_action_name(event_type: str) -> str:
    action_name = (
        event_type.replace("Started", "")
        .replace("Start", "")
        .replace("Finished", "")
        .replace("Updated", "")
        .replace("Stop", "")
        .replace("Change", "")
    )

    # For Updated action there might still be a part after Action (e.g. UtteranceBotActionScriptUpdated)
    keyword = "Action"
    index = action_name.find(keyword)
    if index != -1:
        cleaned_action_name = action_name[: index + len(keyword)]
    else:
        cleaned_action_name = action_name

    return cleaned_action_name


########################################################################################################################
# ACTION HANDLERS
########################################################################################################################


@dataclass
class InternalEvent:
    type: str
    data: Any = None


class ActionHandler(object):
    states = ["init", "running", "background", "finished"]
    triggers: List[str]
    action_name: str
    tui_element_id: str

    def __init__(self, active_mode: bool, app: App) -> None:
        self.active_mode = active_mode
        self.app: App = app
        self.action_state: Dict[str, Any] = {}
        self.task_done = False
        self.was_stopped = False

        transitions = [
            {"trigger": "start", "source": "init", "dest": "running", "before": ["update_action_state", "on_start"]},
            {
                "trigger": "started",
                "source": "init",
                "dest": "running",
                "before": ["update_action_state", "on_started_from_init"],
            },
            {
                "trigger": "started",
                "source": "running",
                "dest": "running",
                "before": ["update_action_state", "on_started_from_running"],
            },
            {
                "trigger": "change",
                "source": "running",
                "dest": "running",
                "before": ["update_action_state", "on_change"],
            },
            {
                "trigger": "promote",
                "source": "running",
                "dest": "running",
                "before": ["update_action_state", "on_promote_when_running"],
            },
            {"trigger": "tick", "source": "running", "dest": "running", "before": ["update_action_state", "on_tick"]},
            {
                "trigger": "demote",
                "source": "running",
                "dest": "background",
                "before": ["update_action_state", "on_demote"],
            },
            {
                "trigger": "promote",
                "source": "background",
                "dest": "running",
                "before": ["update_action_state", "on_promote"],
            },
            {
                "trigger": "started",
                "source": "background",
                "dest": "background",
                "before": ["update_action_state"],
            },
            {
                "trigger": "stop",
                "source": "running",
                "dest": "finished",
                "before": ["update_action_state", "on_stop_from_running"],
            },
            {
                "trigger": "stop",
                "source": "background",
                "dest": "finished",
                "before": ["update_action_state", "on_stop_from_background"],
            },
            {
                "trigger": "finished",
                "source": "running",
                "dest": "finished",
                "before": ["update_action_state", "on_finished_from_running"],
            },
            {
                "trigger": "done",
                "source": "running",
                "dest": "finished",
                "before": ["update_action_state", "on_done"],
            },
            {
                "trigger": "finished",
                "source": "finished",
                "dest": "finished",
                "before": ["update_action_state", "on_finished_from_finished"],
            },
            {
                "trigger": "started",
                "source": "finished",
                "dest": "finished",
                "before": ["update_action_state"],
            },
        ]

        self.machine = Machine(model=self, states=ActionHandler.states, initial="init", transitions=transitions)

    def update_action_state(self, event: Union[InternalEvent, dict]) -> None:
        if isinstance(event, dict):
            assert "action_uid" not in self.action_state or event["action_uid"] == self.action_state["action_uid"]
            self.action_state.update(event)

    def send_event(self, event: Union[InternalEvent, dict]) -> None:
        if not app_in_active_mode:
            return
        self.app.run_worker(self.app.send_events(event), exclusive=False)

    def on_started_from_running(self, event: Union[InternalEvent, dict]) -> None:
        pass

    def on_tick(self, event: Union[InternalEvent, dict]) -> None:
        pass

    def on_finished_from_finished(self, event: Union[InternalEvent, dict]):
        pass

    def get_string_for_tui_element_on_start(self) -> str:
        return ""

    def on_promote_when_running(self, event: Union[InternalEvent, dict]) -> None:
        self.send_event({"type": "Error", "reason": f"Event promote received for running action {self.action_uid}"})

    def send_action_started_event(self) -> None:
        pass

    def send_action_finished_event(self) -> None:
        pass

    def _update_ui_element(self) -> None:
        self.app.query_one(self.tui_element_id, expect_type=Static).add_class("active").update(
            self.get_string_for_tui_element_on_start()
        )

    def on_start(self, event: Union[InternalEvent, dict]) -> None:
        if self.active_mode:
            self.send_action_started_event()
        self._update_ui_element()

    def on_promote(self, event: Union[InternalEvent, dict]) -> None:
        self._update_ui_element()

    def on_demote(self, event: Union[InternalEvent, dict]):
        pass

    def on_started_from_init(self, event: Union[InternalEvent, dict]) -> None:
        self._update_ui_element()

    def on_finished_from_running(self, event: Union[InternalEvent, dict]):
        self.app.query_one(self.tui_element_id, expect_type=Static).remove_class("active").update("")

    def on_done(self, event: Union[InternalEvent, dict]):
        if self.active_mode:
            self.send_action_finished_event()
        self.app.query_one(self.tui_element_id, expect_type=Static).remove_class("active").update("")

    def _handle_generic_stop_behavior(self):
        self.was_stopped = True
        if self.active_mode:
            self.send_action_finished_event()

        self.app.query_one(self.tui_element_id, expect_type=Static).remove_class("active").update("[Stopped]")

    def on_stop_from_running(self, event: Union[InternalEvent, dict]):
        self._handle_generic_stop_behavior()

    def on_stop_from_background(self, event: Union[InternalEvent, dict]):
        self._handle_generic_stop_behavior()

    @property
    def action_uid(self) -> str:
        return self.action_state["action_uid"]


class TimerActionHandler(ActionHandler):
    triggers = [
        "StartTimerBotAction",
        "TimerBotActionStarted",
        "ChangeTimerBotAction",
        "StopTimerBotAction",
        "TimerBotActionFinished",
    ]
    action_name = "TimerBotAction"
    tui_element_id = "#bot-timer"

    def __init__(self, active_mode: bool, app: App) -> None:
        super().__init__(active_mode, app)
        self.timer_duration: timedelta = timedelta(seconds=11)
        self.timer_start: datetime = datetime.now(timezone.utc)

    def get_string_for_tui_element_on_start(self) -> str:
        return f"Timer: {self.timer_duration.total_seconds()} sec"

    def on_start(self, event: Union[InternalEvent, dict]) -> None:
        if isinstance(event, dict) and event["type"] == "StartTimerBotAction":
            self.timer_duration = timedelta(seconds=event["duration"])
            self.timer_start = read_isoformat(event["event_created_at"])

        super().on_start(event)

    def on_change(self, event: Union[InternalEvent, dict]) -> None:
        assert isinstance(event, dict) and event["type"] == "ChangeTimerBotAction"
        self.timer_duration = event["duration"]

        self._update_ui_element()

    def on_tick(self, event: Union[InternalEvent, dict]) -> None:
        if self.active_mode:
            if datetime.now(timezone.utc) - self.timer_start > self.timer_duration:
                self.task_done = True
            else:
                difference = self.timer_duration - (datetime.now(timezone.utc) - self.timer_start)
                self.app.query_one("#bot-timer", expect_type=Static).update(
                    f"Timer: {difference.total_seconds():.2f} sec"
                )

    def send_action_started_event(self) -> None:
        action_started = new_event("TimerBotActionStarted", action_uid=self.action_uid)
        self.send_event(action_started)

    def send_action_finished_event(self) -> None:
        action_finished = new_event(
            "TimerBotActionFinished",
            action_uid=self.action_uid,
            was_stopped=self.was_stopped,
            is_success=True,
        )
        self.send_event(action_finished)


class PresenceUserActionHandler(ActionHandler):
    triggers = [
        "PresenceUserActionStarted",
        "PresenceUserActionFinished",
    ]
    action_name = "PresenceUserAction"
    tui_element_id = "#presence-user"

    def __init__(self, active_mode: bool, app: App) -> None:
        super().__init__(active_mode, app)

    def get_string_for_tui_element_on_start(self) -> str:
        return "User present."

    def send_action_started_event(self) -> None:
        pass

    def send_action_finished_event(self) -> None:
        pass


_gesture_stack = deque([])


class GestureActionHandler(ActionHandler):
    triggers = ["StartGestureBotAction", "GestureBotActionStarted", "StopGestureBotAction", "GestureBotActionFinished"]
    action_name = "GestureBotAction"
    tui_element_id = "#bot-gesture"

    def __init__(self, active_mode: bool, app: App) -> None:
        super().__init__(active_mode, app)
        self.progress = 0

    @property
    def gesture(self) -> str:
        return self.action_state.get("gesture", "unknown")

    def get_string_for_tui_element_on_start(self) -> str:
        return f"Gesture: {self.gesture}"

    def on_start(self, event: Union[InternalEvent, dict]) -> None:
        super().on_start(event)
        _gesture_stack.append(self.app.current_animation)
        self.app.current_animation = self.gesture

    def on_started_from_running(self, event: Union[InternalEvent, dict]) -> None:
        _gesture_stack.append(self.app.current_animation)
        self.app.current_animation = self.gesture

    def on_enter_finished(self, event: Union[InternalEvent, dict]) -> None:
        previous_gesture = _gesture_stack.pop()
        self.app.current_animation = previous_gesture

    def on_tick(self, event: Union[InternalEvent, dict]) -> None:
        if self.active_mode:
            if self.progress < MOTION_DURATION:
                self.progress += 1
            else:
                self.task_done = True

    def send_action_started_event(self) -> None:
        action_started = new_event("GestureBotActionStarted", action_uid=self.action_uid)
        self.send_event(action_started)

    def send_action_finished_event(self) -> None:
        action_finished = new_event(
            "GestureBotActionFinished",
            action_uid=self.action_uid,
            was_stopped=self.was_stopped,
            is_success=True,
        )
        self.send_event(action_finished)


class FacialGestureActionHandler(ActionHandler):
    triggers = [
        "StartFacialGestureBotAction",
        "FacialGestureBotActionStarted",
        "StopFacialGestureBotAction",
        "FacialGestureBotActionFinished",
    ]
    action_name = "FacialGestureBotAction"
    tui_element_id = "#bot-facial-gesture"

    def __init__(self, active_mode: bool, app: App) -> None:
        super().__init__(active_mode, app)
        self.progress = 0

    @property
    def gesture(self) -> str:
        return self.action_state.get("facial_gesture", "unknown")

    def get_string_for_tui_element_on_start(self) -> str:
        return f"Face: {self.gesture}"

    def on_start(self, event: Union[InternalEvent, dict]) -> None:
        super().on_start(event)
        self.app.current_animation = self.gesture

    def on_started_from_running(self, event: Union[InternalEvent, dict]) -> None:
        self.app.current_animation = self.gesture

    def on_tick(self, event: Union[InternalEvent, dict]) -> None:
        if self.active_mode:
            if self.progress < MOTION_DURATION:
                self.progress += 1
            else:
                self.task_done = True

    def send_action_started_event(self) -> None:
        action_started = new_event("FacialGestureBotActionStarted", action_uid=self.action_uid)
        self.send_event(action_started)

    def send_action_finished_event(self) -> None:
        action_finished = new_event(
            "FacialGestureBotActionStarted", action_uid=self.action_uid, was_stopped=self.was_stopped
        )
        self.send_event(action_finished)


class MotionEffectActionHandler(ActionHandler):
    triggers = [
        "StartMotionEffectCameraAction",
        "MotionEffectCameraActionStarted",
        "StopMotionEffectCameraAction",
        "MotionEffectCameraActionFinished",
    ]
    action_name = "MotionEffectCameraAction"
    tui_element_id = "#camera-motion-effect"

    def __init__(self, active_mode: bool, app: App) -> None:
        super().__init__(active_mode, app)
        self.progress = 0

    @property
    def effect(self) -> str:
        return self.action_state.get("effect", "unknown")

    def get_string_for_tui_element_on_start(self) -> str:
        return f"Camera Effect: {self.effect}"

    def on_tick(self, event: Union[InternalEvent, dict]) -> None:
        if self.active_mode:
            if self.progress < MOTION_DURATION:
                self.progress += 1
            else:
                self.task_done = True

    def send_action_started_event(self) -> None:
        action_started = new_event("MotionEffectCameraActionStarted", action_uid=self.action_uid)
        self.send_event(action_started)

    def send_action_finished_event(self) -> None:
        action_finished = new_event(
            "MotionEffectCameraActionFinished",
            action_uid=self.action_uid,
            was_stopped=self.was_stopped,
            is_success=True,
        )
        self.send_event(action_finished)


class OverrideActionHandler(ActionHandler):
    action_stack: Deque[ActionHandler] = deque()

    def __init__(self, active_mode: bool, app: App) -> None:
        super().__init__(active_mode, app)
        self.stopped_from_running = False

    def on_start(self, event: Union[InternalEvent, dict]) -> None:
        super().on_start(event)

        if len(self.action_stack) > 0:
            for action in reversed(self.action_stack):
                if action.state != "finished":
                    self.action_stack[-1].demote(InternalEvent("overridden"))
                    break
        self.action_stack.append(self)

    def on_stop_from_background(self, event: Union[InternalEvent, dict]):
        super().on_stop_from_background(event)

        self._remove_from_stack()

    def on_stop_from_running(self, event: Union[InternalEvent, dict]):
        super().on_stop_from_running(event)

        self._remove_from_stack()
        self.stopped_from_running = True

    def _remove_from_stack(self) -> None:
        action_to_remove: Optional[ActionHandler] = None
        for action in reversed(self.action_stack):
            if action.action_uid == self.action_uid:
                action_to_remove = action
                break

        if action_to_remove:
            self.action_stack.remove(action_to_remove)

    def on_enter_finished(self, event: Union[InternalEvent, dict]) -> None:
        if self.stopped_from_running:
            if len(self.action_stack) > 0:
                for action in reversed(self.action_stack):
                    if action.state != "finished":
                        self.action_stack[-1].promote(InternalEvent("overriding action finished"))
                        break
            else:
                self._reset_default_state()

    def _reset_default_state(self) -> None:
        pass


class PostureActionHandler(OverrideActionHandler):
    triggers = ["StartPostureBotAction", "PostureBotActionStarted", "StopPostureBotAction", "PostureBotActionFinished"]
    action_name = "PostureBotAction"
    tui_element_id = "#bot-posture"
    # Posture has its own action stack
    action_stack: Deque[ActionHandler] = deque()

    def __init__(self, active_mode: bool, app: App) -> None:
        super().__init__(active_mode, app)
        self.progress = 0

    @property
    def posture(self) -> str:
        return self.action_state.get("posture", "unknown")

    def on_start(self, event: Union[InternalEvent, dict]) -> None:
        super().on_start(event)
        self._change_animation()

    def on_promote(self, event: Union[InternalEvent, dict]) -> None:
        super().on_promote(event)
        self._change_animation()

    def get_string_for_tui_element_on_start(self) -> str:
        return f"Posture: {self.posture}"

    def send_action_started_event(self) -> None:
        action_started = new_event("PostureBotActionStarted", action_uid=self.action_uid)
        self.send_event(action_started)

    def send_action_finished_event(self) -> None:
        action_finished = new_event(
            "PostureBotActionFinished",
            action_uid=self.action_uid,
            was_stopped=self.was_stopped,
            is_success=True,
        )
        self.send_event(action_finished)

    def _change_animation(self) -> None:
        self.app.current_animation = self.posture

    def _reset_default_state(self) -> None:
        self.app.current_animation = "idle"


class PositionActionHandler(OverrideActionHandler):
    triggers = [
        "StartPositionBotAction",
        "PositionBotActionStarted",
        "StopPositionBotAction",
        "PositionBotActionFinished",
    ]
    action_name = "PositionBotAction"
    tui_element_id = "#bot-position"
    # Position has its own action stack
    action_stack: Deque[ActionHandler] = deque()

    def __init__(self, active_mode: bool, app: App) -> None:
        super().__init__(active_mode, app)

    @property
    def position(self) -> str:
        return self.action_state.get("position", "unknown")

    def get_string_for_tui_element_on_start(self) -> str:
        return f"Position: {self.position}"

    def send_action_started_event(self) -> None:
        action_started = new_event("PositionBotActionStarted", action_uid=self.action_uid)
        self.send_event(action_started)

    def send_action_finished_event(self) -> None:
        action_finished = new_event(
            "PositionBotActionFinished",
            action_uid=self.action_uid,
            was_stopped=self.was_stopped,
            is_success=True,
        )
        self.send_event(action_finished)


class CameraShotActionHandler(OverrideActionHandler):
    triggers = [
        "StartShotCameraAction",
        "ShotCameraActionStarted",
        "StopShotCameraAction",
        "ShotCameraActionFinished",
    ]
    action_name = "ShotCameraAction"
    tui_element_id = "#camera-shot"
    # Position has its own action stack
    action_stack: Deque[ActionHandler] = deque()

    def __init__(self, active_mode: bool, app: App) -> None:
        super().__init__(active_mode, app)

    @property
    def position(self) -> str:
        return self.action_state.get("shot", "unknown")

    @property
    def start_transition(self) -> str:
        return self.action_state.get("start_transition", "unknown")

    def get_string_for_tui_element_on_start(self) -> str:
        return f"Shot: {self.position} Transition: {self.start_transition}"

    def send_action_started_event(self) -> None:
        action_started = new_event("ShotCameraActionStarted", action_uid=self.action_uid)
        self.send_event(action_started)

    def send_action_finished_event(self) -> None:
        action_finished = new_event(
            "ShotCameraActionFinished",
            action_uid=self.action_uid,
            was_stopped=self.was_stopped,
            is_success=True,
        )
        self.send_event(action_finished)


class UtteranceBotActionHandler(ActionHandler):
    triggers = [
        "StartUtteranceBotAction",
        "UtteranceBotActionStarted",
        "StopUtteranceBotAction",
        "UtteranceBotActionFinished",
    ]
    action_name = "UtteranceBotAction"
    tui_element_id = "#bot-utterance"

    @property
    def script(self) -> str:
        return self.action_state.get("script", "unknown")

    def __init__(self, active_mode: bool, app: App) -> None:
        super().__init__(active_mode, app)
        self.progress = 0

    def get_string_for_tui_element_on_start(self) -> str:
        return self.script if not self.active_mode else ""

    def on_tick(self, event: Union[InternalEvent, dict]) -> None:
        if self.active_mode:
            if self.progress < len(self.script):
                self.progress += 4
                self.app.bell()
                self.app.query_one("#bot-utterance", expect_type=Static).update(self.script[: self.progress])
            else:
                self.task_done = True

    def send_action_started_event(self) -> None:
        action_started = new_event("UtteranceBotActionStarted", action_uid=self.action_uid)
        self.send_event(action_started)

    def send_action_finished_event(self) -> None:
        action_finished = new_event(
            "UtteranceBotActionFinished",
            action_uid=self.action_uid,
            is_success=True,
            final_script=self.script,
            was_stopped=self.was_stopped,
        )
        self.send_event(action_finished)


class VisualActionHandler(OverrideActionHandler):
    tui_element_id = "#scene-ui"
    # All UI actions share one action stack
    action_stack: Deque[ActionHandler] = deque()

    def on_start(self, event: Union[InternalEvent, dict]) -> None:
        super().on_start(event)
        self._show_screen()

    def on_enter_finished(self, event: Union[InternalEvent, dict]) -> None:
        self._hide_screen()
        super().on_enter_finished(event)

    def on_promote(self, event: Union[InternalEvent, dict]) -> None:
        super().on_promote(event)
        self._show_screen()

    def _show_screen(self) -> None:
        choices = self.app.query("UserChoice")
        choices.remove()
        buttons = self.app.query("ConfirmationButtons")
        buttons.remove()
        forms = self.app.query("InputForm")
        forms.remove()
        self.app.query_one("#ui-view", expect_type=Markdown).update(self._generate_ui_content())
        global ui_sidebar_open
        if not ui_sidebar_open:
            self.app.action_toggle_sidebar()
            ui_sidebar_open = True

    def _hide_screen(self) -> None:
        global ui_sidebar_open
        if ui_sidebar_open:
            self.app.action_toggle_sidebar()
            ui_sidebar_open = False

    def _reset_default_state(self) -> None:
        choices = self.app.query("UserChoice")
        choices.remove()
        buttons = self.app.query("ConfirmationButtons")
        buttons.remove()
        forms = self.app.query("InputForm")
        forms.remove()
        self.app.query_one("#ui-view", expect_type=Markdown).update("")


class VisualInformationActionHandler(VisualActionHandler):
    triggers = [
        "StartVisualInformationSceneAction",
        "VisualInformationSceneActionStarted",
        "StopVisualInformationSceneAction",
        "VisualInformationSceneActionFinished",
        "VisualInformationSceneActionConfirmationUpdated",
    ]
    action_name = "VisualInformationSceneAction"

    def get_string_for_tui_element_on_start(self) -> str:
        return f"Information: {self.action_state.get('title', 'unknown')}"

    def _show_screen(self) -> None:
        super()._show_screen()
        new_buttons = ConfirmationButtons(self, "VisualInformationSceneAction")
        self.app.query_one("#ui-controls-view").mount(new_buttons)

    def _generate_ui_content(self) -> str:
        prompts = self.action_state.get("support_prompts", []) or []
        support_prompts = " | ".join([p for p in prompts])

        content = "Content:\n"

        for i, c in enumerate(self.action_state.get("content", [])):
            content += "- "
            if "text" in c and c["text"]:
                content += f"{c['text']} "
            if "image" in c and c["image"]:
                content += f"🌆  `[{c['image']}]`"

            content += "\n"

        return f"""
# {self.action_state['title']}

*Hints : {support_prompts or "None"}*

{content}
"""

    def send_action_started_event(self) -> None:
        action_started = new_event("VisualInformationSceneActionStarted", action_uid=self.action_uid)
        self.send_event(action_started)

    def send_action_finished_event(self) -> None:
        action_finished = new_event(
            "VisualInformationSceneActionFinished",
            action_uid=self.action_uid,
            is_success=True,
        )
        self.send_event(action_finished)


class VisualChoiceActionHandler(VisualActionHandler):
    triggers = [
        "StartVisualChoiceSceneAction",
        "VisualChoiceSceneActionStarted",
        "StopVisualChoiceSceneAction",
        "VisualChoiceSceneActionFinished",
    ]
    action_name = "VisualChoiceSceneAction"

    def get_string_for_tui_element_on_start(self) -> str:
        return f"Choice: {self.action_state.get('prompt', 'unknown')}"

    def _show_screen(self) -> None:
        super()._show_screen()
        options = self.action_state.get("options", [])

        max_text_length = max([len(o.get("text", "")) for o in options]) + 1
        max_image_length = max([len(o.get("image", "")) for o in options]) + 1

        choices = []
        for option in self.action_state.get("options", []):
            option_id = option.get("id", "")
            option_text = option.get("text", "")
            option_image = option.get("image", "")
            text = f"{option_text:<{max_text_length}}:city_sunset: {option_image:<{max_image_length}}([italic]{option_id}[/])"
            choices.append((option_id, text))

        new_choice = UserChoice(self, choices)
        new_buttons = ConfirmationButtons(self, "VisualChoiceSceneAction")

        self.app.query_one("#ui-controls-view").mount(new_choice, new_buttons)

    def _generate_ui_content(self) -> str:
        prompts = self.action_state.get("support_prompts", []) or []
        support_prompts = " | ".join([p for p in prompts])

        return f"""
# {self.action_state['prompt']}

*Hints : {support_prompts or "None"}*
"""

    def send_action_started_event(self) -> None:
        action_started = new_event("VisualChoiceSceneActionStarted", action_uid=self.action_uid)
        self.send_event(action_started)

    def send_action_finished_event(self) -> None:
        action_finished = new_event(
            "VisualChoiceSceneActionFinished",
            action_uid=self.action_uid,
            is_success=True,
        )
        self.send_event(action_finished)


class VisualFormActionHandler(VisualActionHandler):
    triggers = [
        "StartVisualFormSceneAction",
        "VisualFormSceneActionStarted",
        "StopVisualFormSceneAction",
        "VisualFormSceneActionFinished",
        "VisualFormSceneActionInputUpdated",
        "VisualFormSceneActionConfirmationUpdated",
    ]
    action_name = "VisualFormSceneAction"

    def get_string_for_tui_element_on_start(self) -> str:
        return f"Form: {self.action_state.get('prompt', 'unknown')}"

    @property
    def inputs(self) -> List[Dict[str, str]]:
        inputs = self.action_state.get("inputs", [])
        return [{"id": i["id"], "value": i.get("value", ""), "description": i.get("description", "")} for i in inputs]

    def _show_screen(self) -> None:
        super()._show_screen()
        new_buttons = ConfirmationButtons(self, "VisualFormSceneAction")
        new_form = InputForm(self, self.inputs)
        self.app.query_one("#ui-controls-view").mount(new_form, new_buttons)

    def _generate_ui_content(self) -> str:
        prompts = self.action_state.get("support_prompts", []) or []
        support_prompts = " | ".join([p for p in prompts])

        # content = ""
        # for input in self.action_state.get("inputs", []):
        #     input_id = input.get("id", "")
        #     input_value = input.get("value", "")
        #     input_description = input.get("description", "")
        #     content += f"\n- Input `{input_id}` : *{input_description}*  (Value: {input_value})"

        return f"""
# {self.action_state['prompt']}

*Hints : {support_prompts or "None"}*
"""

    def send_action_started_event(self) -> None:
        action_started = new_event("VisualFormSceneActionStarted", action_uid=self.action_uid)
        self.send_event(action_started)

    def send_action_finished_event(self) -> None:
        action_finished = new_event(
            "VisualFormSceneActionFinished",
            action_uid=self.action_uid,
            is_success=True,
        )
        self.send_event(action_finished)


########################################################################################################################
# Textual UI
########################################################################################################################


@dataclass
class UserUtteranceState:
    in_progress: bool
    interim_transcript: str
    action_uid: str


class Title(Static):
    pass


class UserChoice(Widget):
    def __init__(self, action_handler: ActionHandler, options: List[Tuple[str, str]]) -> None:
        self.action_handler = action_handler
        self.options = options
        self.choices = set()
        super().__init__()

    def toggle_choice(self, id: str) -> None:
        if id not in self.choices:
            self.choices.add(id)
        else:
            self.choices.remove(id)

    def compose(self) -> ComposeResult:
        for id, text in self.options:
            yield RadioButton(text, id=id)

    def on_radio_button_changed(self, event: RadioButton.Changed) -> None:
        self.toggle_choice(event.radio_button.id)
        e = new_event(
            "VisualChoiceSceneActionChoiceUpdated",
            action_uid=self.action_handler.action_uid,
            current_choice=list(self.choices),
        )
        self.action_handler.send_event(e)


class InputForm(Static):
    def __init__(self, action_handler: ActionHandler, inputs: List[Dict[str, str]]) -> None:
        self.action_handler = action_handler
        self.inputs = {i["id"]: i for i in inputs}
        super().__init__()

    def compose(self) -> ComposeResult:
        for input in self.inputs.values():
            yield Label(input["description"], id=f"label-{input['id']}")
            yield Input(id=input["id"], value=input["value"])

    def on_input_changed(self, event: Input.Changed) -> None:
        if event.input.id in self.inputs:
            self.inputs[event.input.id]["value"] = event.value
            e = new_event(
                "VisualFormSceneActionInputUpdated",
                action_uid=self.action_handler.action_uid,
                interim_inputs=list(self.inputs.values()),
            )

            self.action_handler.send_event(e)


class ConfirmationButtons(Static):
    def __init__(
        self,
        action_handler: ActionHandler,
        action_type: str,
    ) -> None:
        self.action_handler = action_handler
        self.action_type = action_type
        super().__init__()

    def on_button_pressed(self, event: Button.Pressed) -> None:
        """Event handler called when a button is pressed."""

        button_id = event.button.id
        if button_id == "confirm-button":
            e = new_event(
                f"{self.action_type}ConfirmationUpdated",
                action_uid=self.action_handler.action_uid,
                confirmation_status="confirm",
            )
            self.action_handler.send_event(e)
        elif button_id == "deny-button":
            e = new_event(
                f"{self.action_type}ConfirmationUpdated",
                action_uid=self.action_handler.action_uid,
                confirmation_status="cancel",
            )
            self.action_handler.send_event(e)

    def compose(self) -> ComposeResult:
        yield Button("OK", variant="primary", classes="confirm-button", id="confirm-button")
        yield Button("Cancel", classes="deny-button", id="deny-button")


class UIView(Static):
    def compose(self) -> ComposeResult:
        yield Markdown("", id="ui-view")


class UIControlsView(Container):
    pass


class Sidebar(Container):
    def compose(self) -> ComposeResult:
        yield UIView()
        yield UIControlsView(id="ui-controls-view")


class UmimTuiApp(App):
    """A Textual app to manage stopwatches."""

    TITLE = "ACE CLI Simulator"
    SUB_TITLE = "Welcome"

    BINDINGS = [
        ("ctrl+t", "toggle_timestamps", "Toggle timestamps"),
        ("ctrl+s", "save_interaction", "Save events"),
        ("ctrl+c", "exit_app", "Exit"),
        ("ctrl+b", "toggle_sidebar", "Toggle scene UI"),
    ]
    CSS_PATH = "style.css"

    show_sidebar = reactive(False)

    event_worker: Optional[Worker] = None
    interaction_history: List[Dict[str, Any]] = []

    utterance_to_process: Optional[Dict[str, Any]] = None
    motion_to_process: Optional[Dict[str, Any]] = None

    user_utterance = UserUtteranceState(in_progress=False, interim_transcript="", action_uid="")

    show_system_events = False
    show_timestamps = False

    def __init__(self, event_log_path: Optional[Path] = None):
        self.SUB_TITLE = f"Connected to stream {stream_id}"
        super().__init__()

        self.running_actions: Dict[str, ActionHandler] = {}
        self.latest_action_id_per_action: Dict[str, List[str]] = {}
        self.trigger_to_handler: Dict[str, Type[ActionHandler]] = {}
        self.event_log_path = event_log_path
        self.event_log_index = 0
        self.event_log: List[Dict[str, Any]] = []
        self.current_animation = "idle"

        for handler_cls in [
            GestureActionHandler,
            FacialGestureActionHandler,
            PostureActionHandler,
            VisualChoiceActionHandler,
            VisualFormActionHandler,
            VisualInformationActionHandler,
            UtteranceBotActionHandler,
            PositionActionHandler,
            CameraShotActionHandler,
            TimerActionHandler,
            MotionEffectActionHandler,
            PresenceUserActionHandler,
        ]:
            self._register_action_handler(handler_cls)

    def _register_action_handler(self, handler_cls: Type[ActionHandler]) -> None:
        for trigger in handler_cls.triggers:
            self.trigger_to_handler[trigger] = handler_cls

    def _load_event_log(self) -> None:
        with open(self.event_log_path, "r", encoding="utf-8") as f:
            self.event_log = json.loads(f.read())
            self.event_log_index = -1

    @property
    def chat_log(self) -> TextLog:
        """Get the Markdown widget."""
        return self.query_one(TextLog)

    @property
    def input_prompt(self) -> Input:
        """Get the prompt widget."""
        return self.query_one("#input-prompt", expect_type=Input)

    def on_mount(self) -> None:
        self.channel = channel_id
        self.event_client = event_provider_factory(
            "redis",
            redis_host,
            redis_port,
            [self.channel],
            discard_existing_events=False,
        )

        if create_pipeline:
            self.run_worker(self.event_client.redis.delete(self.channel), exclusive=False)  # type: ignore
            self.run_worker(self.send_pipeline_acquired(), exclusive=False)

        self.update_timer = self.set_interval(1 / 10, self.update_time, pause=False)
        self.action_task = self.set_interval(1 / 10, self.process_actions, pause=False)

    def on_input_changed(self, event: Input.Changed) -> None:
        """Called as the user types."""

        # Don't start the UserUtterance until we know if the user wants to create a event or if he is actually
        # entering an utterance
        if (
            len(event.value) < 2
            or event.value.startswith("/")
            or event.value.startswith("{")
            or not app_in_active_mode
        ):
            return

        if not self.user_utterance.in_progress:
            self.user_utterance.in_progress = True
            action_started = new_event("UtteranceUserActionStarted", action_uid=new_uuid())
            self.user_utterance.interim_transcript = ""
            self.user_utterance.action_uid = action_started["action_uid"]
            self.run_worker(self.send_events(action_started), exclusive=False)

        if abs(self.user_utterance.interim_transcript.count(" ") - event.value.count(" ")) > 1:
            self.user_utterance.interim_transcript = event.value
            action_updated = new_event(
                "UtteranceUserActionTranscriptUpdated",
                action_uid=self.user_utterance.action_uid,
                interim_transcript=self.user_utterance.interim_transcript,
                stability=0.1,
            )

            self.run_worker(self.send_events(action_updated), exclusive=False)

    async def process_actions(self) -> None:
        handlers_to_remove = []
        for handler in self.running_actions.values():
            if handler.state == "finished":
                handlers_to_remove.append(handler.action_uid)
            else:
                if handler.state == "running":
                    if not handler.task_done:
                        handler.tick(InternalEvent("tick"))
                    else:
                        handler.done(InternalEvent("done"))

        for id in handlers_to_remove:
            handler = self.running_actions[id]
            self.latest_action_id_per_action[handler.action_name].remove(id)
            del self.running_actions[id]

    async def update_time(self) -> None:
        if self.event_worker and (
            self.event_worker.state == WorkerState.RUNNING or self.event_worker.state == WorkerState.PENDING
        ):
            return

        self.event_worker = self.run_worker(self.process_events(), group="event_receivers", exclusive=False)

    async def process_events(self) -> None:
        events = await self.event_client.receive_events(200)
        for event_str in events:
            event = json.loads(event_str)
            self.add_event(event)

    async def send_events(self, event_data: Union[str, dict]) -> None:
        if isinstance(event_data, dict):
            if event_data["action_uid"] == "LATEST":
                action_name = self.trigger_to_handler[event_data["type"]].action_name
                if (
                    action_name in self.latest_action_id_per_action
                    and len(self.latest_action_id_per_action[action_name]) > 0
                ):
                    event_data["action_uid"] = self.latest_action_id_per_action[action_name][-1]
                else:
                    self.add_event({"type": "Error", "reason": f"LATEST used but no running {action_name}"})

        await self.event_client.send_event(self.channel, event_data)

    async def send_pipeline_acquired(self) -> None:
        session_user_id = new_uuid()
        await self.event_client.send_event(
            SYSTEM_EVENTS_STREAM, new_event("PipelineAcquired", stream_uid=stream_id, user_uid=session_user_id)
        )

    async def send_pipeline_released(self) -> None:
        await self.event_client.send_event(SYSTEM_EVENTS_STREAM, new_event("PipelineReleased", stream_uid=stream_id))

    def compose(self) -> ComposeResult:
        """Create child widgets for the app."""
        yield Container(
            Sidebar(classes="-hidden", id="ui-container"),
            Header(show_clock=True),
            Horizontal(
                Container(
                    Vertical(
                        Container(
                            Vertical(
                                Container(
                                    Static("\n:speech_balloon:  [yellow]Chat:[/yellow]"),
                                    Static(
                                        "...",
                                        classes="fill-width modality",
                                        id="bot-utterance",
                                    ),
                                    classes="fill-width",
                                ),
                                Container(
                                    Static("\n:wave:  [yellow]Motion:[/yellow]"),
                                    Static(
                                        "...",
                                        classes="fill-width modality-slim",
                                        id="bot-gesture",
                                    ),
                                    Static(
                                        "...",
                                        classes="fill-width modality-slim",
                                        id="bot-facial-gesture",
                                    ),
                                    Static(
                                        "...",
                                        classes="fill-width modality-slim",
                                        id="bot-posture",
                                    ),
                                    Static(
                                        "...",
                                        classes="fill-width modality-slim",
                                        id="bot-position",
                                    ),
                                ),
                            ),
                            classes="avatar-area",
                        ),
                        Container(
                            Horizontal(
                                Container(
                                    Static("\n:tv:  [yellow]UI/Camera:[/yellow]"),
                                    Static(
                                        "...",
                                        classes="modality-slim fill-width",
                                        id="scene-ui",
                                    ),
                                    Static(
                                        "...",
                                        classes="modality-slim fill-width",
                                        id="camera-shot",
                                    ),
                                    Static(
                                        "...",
                                        classes="modality-slim fill-width",
                                        id="camera-motion-effect",
                                    ),
                                    classes="fill-width",
                                ),
                                Container(
                                    Static("\n:watch:  [yellow]Utils:[/yellow]"),
                                    Static(
                                        "...",
                                        classes="modality-slim fill-width",
                                        id="bot-timer",
                                    ),
                                    Static(
                                        "...",
                                        classes="fill-width modality-slim",
                                        id="presence-user",
                                    ),
                                    classes="third",
                                ),
                            ),
                        ),
                    ),
                    Label("Prompt:"),
                    Input(id="input-prompt"),
                    classes="fill-width",
                ),
                Container(
                    Static("[bold]Interaction History[/bold]"),
                    TextLog(highlight=True, markup=True, wrap=True),
                    classes="fill-width log",
                ),
                classes="fill-width",
            ),
        )
        yield Footer()

    def action_toggle_timestamps(self) -> None:
        """An action to toggle showing timestamps."""
        self.show_timestamps = not self.show_timestamps

        self.chat_log.clear()
        for event in self.interaction_history:
            self._show_event(event)

    def action_toggle_sidebar(self) -> None:
        sidebar = self.query_one(Sidebar)

        self.set_focus(self.query_one("#input-prompt"))
        if sidebar.has_class("-hidden"):
            sidebar.remove_class("-hidden")
        else:
            if sidebar.query("*:focus"):
                self.screen.set_focus(self.query_one("#input-prompt"))
            sidebar.add_class("-hidden")

    def _show_event(self, event: Dict[str, Any]) -> None:
        if self.show_system_events or "is_system_action" not in event or not event["is_system_action"]:
            entry = pretty_event(event, show_time=self.show_timestamps)
            self.chat_log.write(entry)
            # self.update_ui(event)

    def action_save_interaction(self) -> None:
        """An action to toggle showing all events ."""
        if len(self.interaction_history) > 0:
            with open(f"interaction_{channel_id}.json", "w", encoding="utf-8") as f:
                f.write(json.dumps(self.interaction_history, indent=4))

    def action_exit_app(self) -> None:
        """Exit the app"""
        if create_pipeline:
            asyncio.ensure_future(self.send_pipeline_released())
        self.exit()

    def on_input_submitted(self, event: Input.Submitted) -> None:
        self.send_event(event.value)
        self.input_prompt.value = ""

    def add_event(self, event_dict: Dict[str, Any]) -> None:
        self._show_event(event_dict)
        self.interaction_history.append(event_dict)

        # Is it a UMIM event?
        if "uid" in event_dict:
            try:
                event = try_parse_event(event_dict)

                if not isinstance(event, dict) or "action_uid" not in event:
                    return

                action_uid = event["action_uid"]
                handler = None

                if action_uid in self.running_actions:
                    handler = self.running_actions[action_uid]
                elif ("Started" in event["type"] or "Start" in event["type"]) and event[
                    "type"
                ] in self.trigger_to_handler:
                    handler = self.trigger_to_handler[event["type"]](app_in_active_mode, self)
                    self.running_actions[action_uid] = handler
                    self.latest_action_id_per_action.setdefault(handler.action_name, []).append(action_uid)

                if handler and event["type"] in handler.triggers:
                    if "Started" in event["type"]:
                        handler.started(event)
                    elif "Start" in event["type"]:
                        handler.start(event)
                    elif "Change" in event["type"]:
                        handler.change(event)
                    elif "Stop" in event["type"]:
                        handler.stop(event)
                    elif "Finished" in event["type"]:
                        handler.finished(event)
            except Exception as e:
                self.add_event(
                    {
                        "type": "Error",
                        "reason": f"{str(type(e).__name__)}: {str(e)} when running handler {type(handler).__name__ or 'unknown'}",
                    }
                )

    def send_event(self, event_description: str) -> None:
        if event_description[:5] == "/bot ":
            event = new_event("StartUtteranceBotAction", script=event_description[5:])
            self.run_worker(self.send_events(event), exclusive=False)
        elif event_description.startswith("{"):
            try:
                event_json = json.loads(event_description)
                event_type = event_json["type"]
                del event_json["type"]
                self.run_worker(
                    self.send_events(json.dumps(new_event(event_type=event_type, **event_json))), exclusive=False
                )
            except Exception as e:
                self.add_event({"type": "Error", "reason": str(e)})
        else:
            action_finished = new_event(
                "UtteranceUserActionFinished",
                action_uid=self.user_utterance.action_uid or new_uuid(),
                final_transcript=event_description,
                is_success=True,
            )
            self.user_utterance = UserUtteranceState(in_progress=False, interim_transcript="", action_uid="")
            self.run_worker(self.send_events(action_finished), exclusive=False)


async def list_all_active_streams(redis_host, redis_port) -> None:
    event_client = event_provider_factory(
        "redis",
        redis_host,
        redis_port,
        [SYSTEM_EVENTS_STREAM],
        discard_existing_events=False,
    )

    streams = {}
    events = await event_client.receive_events()
    for event_str in events:
        event = json.loads(event_str)
        if event["type"].strip() == "PipelineAcquired":
            streams[event["stream_uid"]] = ("ACTIVE", event["event_created_at"])
        elif event["type"].strip() == "PipelineReleased":
            streams[event["stream_uid"]] = ("DONE", event["event_created_at"])

    active_streams = [(id, status) for id, status in streams.items() if status[0] != "DONE"]
    completed_streams = [(id, status) for id, status in streams.items() if status[0] == "DONE"]
    print(f"[green]Active streams:[/green]")
    for id, status in active_streams:
        time_difference = datetime.now(timezone.utc) - read_isoformat(status[1])
        print(f"Stream {id} is running since: {status[1]} (for {time_difference})")

    print("\n[red]The following streams are completed:[/red]")
    for id, status in completed_streams:
        time_difference = datetime.now(timezone.utc) - read_isoformat(status[1])
        print(f"Stream {id} is done. Closed since {status[1]} (for {time_difference})")


@cli.command()
def main(
    stream: Annotated[
        Optional[str], typer.Option(help="Stream ID to use. Will generated random stream ID if not set.")
    ] = None,
    create: bool = True,
    active_mode: bool = True,
    list_streams: bool = False,
    event_provider_host: Optional[str] = None,
    event_provider_port: Optional[int] = None,
    event_log: Optional[Path] = typer.Option(None),
) -> None:
    global channel_id
    global create_pipeline
    global stream_id
    global app_in_active_mode
    global redis_port
    global redis_host

    stream_id = stream or new_uuid()
    channel_id = f"umim_events_{stream_id}"
    create_pipeline = create
    app_in_active_mode = active_mode

    if event_provider_port:
        redis_port = event_provider_port
    if event_provider_host:
        redis_host = event_provider_host

    if list_streams:
        asyncio.run(list_all_active_streams(redis_host, redis_port))
        return

    app = UmimTuiApp(event_log)
    app.run()


if __name__ == "__main__":
    cli()
