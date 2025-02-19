"""
 copyright(c) 2023 NVIDIA Corporation.All rights reserved.

 NVIDIA Corporation and its licensors retain all intellectual property
 and proprietary rights in and to this software, related documentation
 and any modifications thereto.Any use, reproduction, disclosure or
 distribution of this software and related documentation without an express
 license agreement from NVIDIA Corporation is strictly prohibited.
"""

"""Order food fulfillment to manage user orders and cart"""

import logging
import os
import sys
from time import time
from typing import Any, Dict, List, Optional, Tuple

from fastapi import APIRouter
from word2number import w2n
import editdistance

from cart_manager import CartManager
from menu_api import MenuDB

router = APIRouter()
logger = logging.getLogger("plugin")

# Initialize cart manager and menu database
menudb = MenuDB()
cart_manager = CartManager()


def find_similar_item(input_food, food_list):
    """Return first item from the cart within editdistance of 1"""

    threshold = 1  # Set the threshold for edit distance

    for food_item in food_list:
        distance = editdistance.eval(input_food, food_item)
        if distance <= threshold:
            return food_item

    return None  # No matching item found


def get_item_from_menu(food_item: str, food_size: Optional[str] = ""):
    """fetch item details from menu database"""

    # Get all items from the menu
    items_in_menu = menudb.get_all_menu_item()
    food_list = []
    for item in items_in_menu:
        if item.get("category", "") in ["sides", "drinks", "salads", "entrees"] and item.get("menu_item", False):
            food_list.append(item.get("name", ""))

    # if food item is not in the menu, check if it's in editdistance of 1 with any menu item
    if food_item not in food_list:
        logger.info(f"{food_item} not found in the menu, finding item 1 editdistance from the menu")
        food_name = find_similar_item(food_item, food_list)
        if food_name:
            logger.info(f"Replacing {food_item} with {food_name} for furthur operation")
            food_item = food_name
        else:
            logger.info(f"No similar item to {food_item} found in the menu")
            # If not match found
            return []

    # Query to DB to check if food item is present in menu
    query = [{"field": "name", "values": food_item, "condition": "eq"}]

    resp_db = menudb.filter_query(query)
    result = []
    if food_size:
        for r in resp_db.get("items", []):
            # If food itme is not menu item don't add it as result
            # This is to make sure we don't add toppings and indegridents as part of resp
            if not r.get("menu_item", False):
                continue
            for variation in r.get("variations", []):
                if food_size == variation.get("size", None):
                    result.append(r)
    else:
        for r in resp_db.get("items", []):
            # If food itme is not menu item don't add it as result
            # This is to make sure we don't add toppings and indegridents as part of resp
            if not r.get("menu_item", False):
                continue
            result.append(r)

    return result


@router.post("/add_item")
def add_item(
    user_id: str, food_name: Optional[str] = None, food_size: Optional[str] = "", food_quantity: Optional[str] = ""
) -> Optional[str]:
    """Add new item to cart
    return_value:
        resp: Details of item added to cart
        invalid_items: List of items not present in menu
    """
    try:
        logger.info(f"Adding {food_quantity} {food_size} {food_name}")
        # WAR to convert food_name to list
        food_name = [food_name] if food_name else []
        food_size = [food_size] if food_size else []
        food_quantity = [food_quantity] if food_quantity else []

        logger.debug(f"Adding {food_name} for {user_id}")
        valid_items_filter = []
        invalid_item = []
        valid_items = []

        # Assumption is index of food size, quantity and food name are in same order
        # e.g. [3, 2] [fish sandwich,onion rings]
        for idx, food_item in enumerate(food_name):
            current_food_size = food_size[idx] if idx < len(food_size) else ""
            resp = get_item_from_menu(food_item, current_food_size)
            if len(resp) == 0:
                invalid_item.append(f"{current_food_size} {food_item}")
            for r in resp:
                item = {
                    "item_id": r.get("item_id"),
                    "quantity": w2n.word_to_num(food_quantity[idx]) if idx < len(food_quantity) else 1,
                    "toppings": [],
                }

                if idx < len(food_size):
                    item.update({"size": food_size[idx]})
                valid_items_filter.append(item)
                valid_items.append(f"{item.get('quantity')} {current_food_size} {food_item}")
        valid_items_filter = {"items": valid_items_filter}

        status, resp = cart_manager.cart_items_add(user_id, valid_items_filter)
        resp_str = ""
        if valid_items:
            resp_str = f"I've added {', '.join(valid_items)} added to cart."
        if invalid_item:
            resp_str += f" We don't have {', '.join(invalid_item)} in menu."
        logger.info(f"Response:  {resp_str}")
        return resp_str
    except Exception as e:
        logger.error(f"Exception {e} while building response")
        return None


@router.post("/remove_item")
def remove_item(
    user_id: str, food_name: Optional[str] = None, food_size: Optional[str] = None, food_quantity: Optional[str] = None
) -> Optional[str]:
    """remove item from cart"""

    valid_items = []
    invalid_item = []
    try:
        logger.info(f"Removing {food_quantity} {food_size} {food_name}")
        # WAR to convert food_name to list
        food_name = [food_name] if food_name else []
        food_size = [food_size] if food_size else []
        food_quantity = [food_quantity] if food_quantity else []

        for idx, food_item in enumerate(food_name):
            items = get_item_from_menu(food_item=food_item)

            if len(items) == 0:
                invalid_item.append(food_item)

            for i in items:
                item = {
                    "item_id": i.get("item_id"),
                    "quantity": w2n.word_to_num(food_quantity[idx]) if idx < len(food_quantity) else 1,
                    "toppings": [],
                }

                if idx < len(food_size):
                    item.update({"size": food_size[idx]})
                valid_items.append(item)

        if len(invalid_item):
            return f"Failed to remove {' '.join(invalid_item)} as it's not present in cart"

        valid_items = {"remove_items": valid_items}

        status, msg = cart_manager.cart_items_delete(user_id, valid_items)
        logger.info(f"{msg}")
        return msg
    except Exception as e:
        logger.error(f"Exception {e} while processing removing item")
        return "Failed to remove item from cart"


@router.post("/replace_items")
def replace_items(
    user_id: str,
    add_food_name: Optional[str] = None,
    add_food_size: Optional[str] = None,
    add_food_quantity: Optional[str] = None,
    remove_food_name: Optional[str] = None,
    remove_food_size: Optional[str] = None,
    remove_food_quantity: Optional[str] = None,
) -> Optional[str]:
    """replace item from cart"""
    try:
        logger.info(
            f"Replacing Items: UserId: {user_id}, Replace: {add_food_quantity} {add_food_size} {add_food_name} with {remove_food_size} {remove_food_quantity} {remove_food_name}"
        )
        remove_msg = remove_item(user_id, remove_food_name, remove_food_size, remove_food_quantity)
        if "Failed" in remove_msg or "No item found to delete from cart" in remove_msg:
            return f"{remove_msg}. Skipping adding {add_food_name}"
        add_msg = add_item(user_id, add_food_name, add_food_size, add_food_quantity)
        if add_msg is None:
            return f"{remove_msg}. Failed to add item in cart"
        if "We don't have" in add_msg:
            return f"{remove_msg}. Failed to add {add_food_name} in cart"
        return f"Replaced only one {remove_food_name} with only one {add_food_name}"
    except Exception as e:
        logger.error(f"Exception {e} while processing removing item")
        return "Failed to replace item"


@router.post("/query_items")
def query_items(
    user_id: str, food_name: Optional[str] = None, food_size: Optional[str] = None, food_quantity: Optional[str] = None
) -> Optional[str]:
    """query items from menu"""
    logger.info("Fetching details for food items")
    try:
        # WAR to convert food_name to list
        food_size = [food_size] if food_size else []
        food_quantity = [food_quantity] if food_quantity else []

        item_narattive = ""
        items = get_item_from_menu(food_item=food_name)
        for variations in items:
            for variation in variations.get("variations", []):
                if "description" in variation:
                    item_narattive = ""
                    item_narattive += variations.get("name", "") + " is " + variation.get("description").lower()
                    if item_narattive[-1] != ".":
                        item_narattive += "."
                    if variation.get("size") == food_size:
                        return item_narattive

        logger.info(f"Item Narattive:  {item_narattive}")
        return item_narattive

    except Exception as e:
        logger.error(f"Exception {e} while processing removing item")
        return ""


@router.post("/place_order")
def place_order(user_id: str) -> Optional[Dict]:
    """place order for items in cart"""
    try:
        # It clears cart and returns the cart details
        # containing bill, order summary, calory details etc
        status, msg, cart_info = cart_manager.cart_checkout(user_id)
        cart_info = cart_info.asdict()
        logger.info(f"Cart details for user {user_id}:  {cart_info}")
        return cart_info
    except Exception as e:
        logger.error(f"Exception {e} while processing removing item")


@router.post("/check_bill")
def check_bill(user_id: str) -> Optional[float]:
    """returns total bill"""
    try:
        logger.info(f"Checking bill for user: {user_id}")
        return float(cart_manager.get_total_bill(user_id))
    except Exception as e:
        logger.error(f"Exception {e} while checking bill")
        return 0


@router.post("/clear_cart")
def clear_cart(user_id: str) -> None:
    """clear items from cart"""
    try:
        logger.info(f"Clearing cart for user: {user_id}")
        # clear cart items from cart for user
        cart_manager.cart_delete(user_id)
    except Exception as e:
        logger.error(f"Exception {e} while clearing cart")


@router.post("/repeat_order")
def repeat_order(user_id: str) -> str:
    """repeat current order/items in cart"""
    try:
        logger.info(f"Repeating order")
        items = cart_manager.items_in_cart(user_id)
        items = items.get("items", [])

        # convert item dict to a str
        cart_item = ""
        if len(items) == 0:
            return "Your cart is empty"
        for item in items:
            cart_item += f" {item.get('quantity', '')} {item.get('size', '')} {item.get('name')}"
        logger.info(f"Cart has {cart_item} for user {user_id}")
        return f"You have {cart_item} in cart"
    except Exception as e:
        logger.error(f"Exception {e} repeating order")
        return ""


@router.post("/show_menu")
def show_menu() -> str:
    """returns all the itmes in the menu"""
    try:
        logger.info(f"Showing menu items")
        items = menudb.get_all_menu_item()
        menu = []
        for item in items:
            if item.get("category", "") in ["sides", "drinks", "salads", "entrees"] and item.get("menu_item", False):
                menu.append(item.get("name", ""))
        logger.info(f"Items in menu: {' '.join(menu)}")
        return " ".join(menu)
    except Exception as e:
        logger.error(f"Exception {e} while getting menu")
        return ""
