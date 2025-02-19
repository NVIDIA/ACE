# Copyright(c) 2023 NVIDIA Corporation. All rights reserved

# NVIDIA Corporation and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA Corporation is strictly prohibited.

"""
    Templates used to store the intent to intent class mappings
    and menu or user information internally in
    drive through bot.
"""

from dataclasses import dataclass, field, asdict
from typing import Any, Dict, List, Tuple

# Dataclasses which are used to store and pass data internally among
# all intent handlers


@dataclass(unsafe_hash=True)
class ValueWithSentiment:
    """
    Template to store values along with whether it is with a negative sentiment.
    Eg: "add it without cheese" -> ValueWithSentiment(value="cheese", is_negative=True)
        "add it with cheese" -> ValueWithSentiment(value="cheese", is_negative=False)
    """

    value: str
    is_negative: bool = False

    def __eq__(self, other) -> bool:
        return self.value == other.value and self.is_negative == other.is_negative


@dataclass()
class FoodItem:
    """
    Template that is used to store given/inferred details of the each food item
    from user query
    """

    item_id: str = ""
    name: str = ""
    unknown_name: str = ""
    reference_name: str = ""
    size: str = ""
    quantity: int = None
    item_type: str = ""
    toppings: Tuple[ValueWithSentiment] = field(default_factory=lambda: ())
    ingredients: Tuple[ValueWithSentiment] = field(default_factory=lambda: ())
    tags: Tuple[ValueWithSentiment] = field(default_factory=lambda: ())

    def __eq__(self, other) -> bool:
        return (
            self.item_id == other.item_id
            and self.name == other.name
            and self.unknown_name == other.unknown_name
            and self.reference_name == other.reference_name
            and self.size == other.size
            and (self.quantity == other.quantity or (not self.quantity and not other.quantity))
            and self.item_type == other.item_type
            and self.toppings == other.toppings
            and self.ingredients == other.ingredients
            and self.tags == other.tags
        )

    def __hash__(self):
        """Define the hash to allow set creation."""

        return hash(
            (self.item_id, self.name, self.unknown_name, self.reference_name, self.size, self.item_type, self.toppings)
        )


@dataclass
class UserData:
    """All relevant info about current user, their preferences
    and cart details that are stored externally
    Args:
    1. queried_items: Slots passed onto FM are mapped to food items
    2. Different uuids relating to the conversation
    3. contextual_data: Local context about the conversation
    4. nlu_intent: The intent tagged by Intent Slot model
    """

    user_id: str = ""
    session_id: str = ""
    stream_id: str = ""
    query_id: str = ""
    queried_items: List[FoodItem] = field(default_factory=lambda: [])
    contextual_data: Dict[str, Any] = field(default_factory=lambda: {})
    nlu_intent: str = ""
    cart_state: Dict[str, Any] = field(default_factory=lambda: {})
    page_state: Dict[str, Any] = field(default_factory=lambda: {})


@dataclass
class Cart:
    """Cart dataclass for storing all the information
    pertaining to an order per user per session"""

    total_bill: float = 0.0
    total_calories: float = 0.0
    items: List["CartItem"] = field(default_factory=lambda: [])

    def asdict(self):
        return asdict(self)


@dataclass
class ToppingItem:
    def __eq__(self, other):
        print(self.item_id)
        print(other.item_id)

        return self.item_id == other.item_id

    item_id: str = ""
    name: str = ""
    image_loc: str = ""
    quantity: int = 0
    calories: float = 0.0
    price: float = 0.0

    def __getitem__(self, item):
        return getattr(self, item)


@dataclass
class CartItem:
    """Class which stores information about all items in a cart"""

    def __eq__(self, other):
        return self.item_id == other.item_id and self.toppings == other.toppings and self.size == other.size

    item_id: str = ""
    name: str = ""
    toppings: List["ToppingItem"] = field(default_factory=lambda: ())
    size: str = "regular"
    calories: float = 0.0
    image_loc: str = ""
    quantity: int = 1
    price: float = 0.0
    description: str = ""
    category: str = ""
    cart_item_id: str = ""

    def __getitem__(self, item):
        return getattr(self, item)


@dataclass
class LatencyStats:
    overall_cm_latency: int = 0
    menu_api_latency: int = 0
    database_transactions_latency: int = 0
    time_unit: str = "ms"

    def dict(self):
        return self.__dict__

    def reset(self):
        # setting all the members to initial value
        self.overall_cm_latency = 0
        self.menu_api_latency = 0
        self.database_transactions_latency = 0
