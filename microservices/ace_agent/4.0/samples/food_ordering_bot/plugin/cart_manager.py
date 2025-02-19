"""
 copyright(c) 2023 NVIDIA Corporation.All rights reserved.

 NVIDIA Corporation and its licensors retain all intellectual property
 and proprietary rights in and to this software, related documentation
 and any modifications thereto.Any use, reproduction, disclosure or
 distribution of this software and related documentation without an express
 license agreement from NVIDIA Corporation is strictly prohibited.
"""
from dataclasses import asdict
from typing import Any, Dict
from uuid import uuid4
import logging

from data_format import *
from menu_api import MenuDB

menu_db = MenuDB()
logger = logging.getLogger("plugin")


class CartManager:
    def __init__(self) -> None:
        """Cart Manager to manager user information in cart"""
        self._cart_table = {}  # maintains session_id: cart_item

    def is_ready(self):
        # Remove if not required
        return True

    def get_total_bill(self, session_id):
        """List of items in cart for given session_id"""
        if session_id in self._cart_table:
            cart = self._cart_table.get(session_id)
            return cart.total_bill
        return 0

    def __get_menu_item_by_id(self, id_to_search):
        return menu_db.get_item_from_id(id_to_search)

    def __get_details_from_variation(self, menu_item, current_item):
        item_desc = None
        item_img_loc = None
        item_size = None
        item_calories = None
        item_price = None
        variations = None
        for key, value in menu_item.items():
            if key == "variations":
                variations = value

        print(variations, current_item)
        for variation in variations:
            if "is_default" in variation:
                item_desc = variation["description"]
                item_img_loc = variation["image"]
                item_size = variation["size"]
                item_calories = variation["calories"]
                item_price = variation["price"]

        if "size" not in current_item:
            return [
                menu_item["name"],
                item_img_loc,
                item_size,
                item_calories,
                item_price,
                item_desc,
            ]

        for variation in variations:
            if current_item["size"] == variation["size"]:
                return [
                    menu_item["name"],
                    item_img_loc,
                    variation["size"],
                    variation["calories"],
                    variation["price"],
                    item_desc,
                ]

    def __get_toppings_for_item_id(self, item_toppings):
        mesg = "Success"
        toppings = []
        for topping in item_toppings:
            topping_id = topping["item_id"]
            menu_item_by_id = self.__get_menu_item_by_id(topping_id)
            if menu_item_by_id == None:
                return toppings, "Could not get the menu item"

            print("Menu item by id is: {}".format(menu_item_by_id))
            toppings.append(
                ToppingItem(
                    menu_item_by_id["item_id"],
                    menu_item_by_id["name"],
                    menu_item_by_id["variations"][0]["image"],
                    1,
                    menu_item_by_id["variations"][0]["calories"],
                    menu_item_by_id["variations"][0]["price"],
                )
            )
        return toppings, mesg

    def __update_total_bill_calories(self, uuid):
        self._cart_table[uuid].total_bill = round(
            sum(cart_item["price"] for cart_item in self._cart_table[uuid].items), 2
        )

        for item in self._cart_table[uuid].items:
            print("Item is: {}".format(item))

        self._cart_table[uuid].total_calories = round(
            sum(cart_item["calories"] for cart_item in self._cart_table[uuid].items), 2
        )

        print(
            "Updated total bill: {}, {}".format(
                self._cart_table[uuid].total_bill, self._cart_table[uuid].total_calories
            )
        )

    def __fold_cart(self, uuid):
        print("Trying to fold cart")
        for i in range(len(self._cart_table[uuid].items) - 1, 0, -1):
            for j in range(i - 1, -1, -1):
                if self._cart_table[uuid].items[i] == self._cart_table[uuid].items[j]:
                    print("Found similar items in pos {} and {}. Clubbing them into one.".format(i, j))
                    self._cart_table[uuid].items[i].quantity += self._cart_table[uuid].items[j].quantity
                    self._cart_table[uuid].items[i].price += self._cart_table[uuid].items[j].price
                    self._cart_table[uuid].items[i].calories += self._cart_table[uuid].items[j].calories
                    self._cart_table[uuid].items[j].item_id = -1

        new_cart = Cart()
        for item in self._cart_table[uuid].items:
            if item.item_id != -1:
                new_cart.items.append(item)
        new_cart.total_bill = self._cart_table[uuid].total_bill
        new_cart.total_calories = self._cart_table[uuid].total_calories

        self._cart_table[uuid] = new_cart

    def __add_to_cart(self, uuid, menu_item, item_to_add):
        added_toppings = []
        item_to_add["toppings"].sort(key=lambda x: x["item_id"], reverse=False)
        (
            item_name,
            item_img_loc,
            item_size,
            item_calories,
            item_price,
            item_desc,
        ) = self.__get_details_from_variation(menu_item, item_to_add)
        added_toppings, mesg = self.__get_toppings_for_item_id(item_to_add["toppings"])
        if mesg != "Success":
            return mesg
        total_toppings_price = sum(top.price for top in added_toppings)
        total_toppings_calories = sum(top.calories for top in added_toppings)

        # Logic to increase the count of item in cart,
        # if similar item config already present
        for cart_item in self._cart_table[uuid].items:
            if (
                cart_item.item_id == item_to_add["item_id"]
                and cart_item.toppings == added_toppings
                and (
                    cart_item.size == ""
                    or item_to_add.get("size", None) is None
                    or (cart_item.size != "" and cart_item.size == item_to_add["size"])
                )
            ):
                # same item, increment the count instead.
                cart_item.quantity += item_to_add["quantity"]

                cart_item.price = round(
                    cart_item.price + item_to_add["quantity"] * (item_price + total_toppings_price),
                    2,
                )
                cart_item.calories = round(
                    cart_item.calories + item_to_add["quantity"] * (item_calories + total_toppings_calories),
                    2,
                )
                self.__update_total_bill_calories(uuid)
                print("Item already present. Updating count in cart.")
                return

        self._cart_table[uuid].items.append(
            CartItem(
                item_to_add["item_id"],
                item_name,
                added_toppings,
                item_size,
                round(
                    item_to_add["quantity"] * (item_calories + total_toppings_calories),
                    2,
                ),
                item_img_loc,
                item_to_add["quantity"],
                round(item_to_add["quantity"] * (item_price + total_toppings_price), 2),
                item_desc,
                menu_item["category"],
                str(uuid4()),
            )
        )

        self.__update_total_bill_calories(uuid)
        self.__fold_cart(uuid)
        return mesg

    def __add_item(self, session_id, item_to_add):
        mesg = "Success"
        menu_item_by_id = self.__get_menu_item_by_id(item_to_add["item_id"])
        if menu_item_by_id == None:
            print("Item not found on the menu")
            return "Item not found on the menu"
        self.__add_to_cart(session_id, menu_item_by_id, item_to_add)
        return mesg

    def cart_items_add(self, session_id, req):
        items_to_add = req["items"]

        if session_id not in self._cart_table:
            self._cart_table[session_id] = Cart()

        for item in items_to_add:
            mesg = self.__add_item(session_id, item)
            if mesg != "Success":
                return 409, asdict(self._cart_table[session_id])
            print('item "{}" added to cart'.format(item))

        return 200, asdict(self._cart_table.get(session_id))

    def items_in_cart(self, session_id):
        """List of items in cart for given session_id"""
        if session_id in self._cart_table:
            return asdict(self._cart_table.get(session_id, {}))
        return {}

    def __remove_from_cart(self, uuid, menu_item, item_to_remove):
        item_to_remove["toppings"].sort(key=lambda x: x["item_id"], reverse=False)

        print("item_to_remove is: {}".format(item_to_remove))
        _, _, _, item_calories, item_price, _ = self.__get_details_from_variation(menu_item, item_to_remove)

        removed_toppings, mesg = self.__get_toppings_for_item_id(item_to_remove["toppings"])
        print("Checking if item {} is present in the cart".format(item_to_remove))
        for idx, cart_item in enumerate(self._cart_table[uuid].items):
            if (
                cart_item.item_id == item_to_remove["item_id"]
                and ("toppings" not in item_to_remove or cart_item.toppings == removed_toppings)
                and ("size" not in item_to_remove or cart_item.size.lower() == item_to_remove["size"].lower())
            ):
                if cart_item.quantity >= item_to_remove["quantity"]:
                    cart_item.quantity -= item_to_remove["quantity"]
                    total_toppings_price = 0
                    total_toppings_price = sum(top.price for top in removed_toppings)
                    total_toppings_calories = sum(top.calories for top in removed_toppings)
                    cart_item.price = round(
                        cart_item.price - item_to_remove["quantity"] * (item_price + total_toppings_price), 2
                    )
                    cart_item.calories = round(
                        cart_item.calories - item_to_remove["quantity"] * (item_calories + total_toppings_calories), 2
                    )
                    self.__update_total_bill_calories(uuid)

                    if cart_item.quantity == 0:
                        self._cart_table[uuid].items.pop(idx)
                    logger.info("Item removed from the cart")
                    return True

        logger.info("Item not found in cart")
        return False

    def __remove_item(self, uuid, item_to_remove: Dict[str, Any]):
        logger.info("Item to be removed: {}".format(item_to_remove))
        mesg = "Success"
        menu_item_by_id = self.__get_menu_item_by_id(item_to_remove["item_id"])
        if menu_item_by_id == None:
            return "Could not find the item on the menu", False
        is_item_removed = self.__remove_from_cart(uuid, menu_item_by_id, item_to_remove)
        self.__fold_cart(uuid)
        return mesg, is_item_removed

    def cart_items_delete(self, session_id, req):
        STATUS = 200
        MESG = "No item found to delete from cart"

        if session_id not in self._cart_table:
            logger.info("No cart found for the session {}".format(session_id))
            MESG = "No cart found for the session {}".format(session_id)
            STATUS = 409
            return STATUS, MESG

        logger.info("Deleting items in the cart for session_id {}".format(session_id))

        remove_items = req["remove_items"]

        for item in remove_items:
            item_info = self.__get_menu_item_by_id(item.get("item_id"))
            item_name = item_info.get("name")
            logger.info(f"Trying to remove {item_name} from cart")
            mesg, is_item_removed = self.__remove_item(session_id, item)
            if mesg != "Success" or is_item_removed == False:
                STATUS = 409
                return STATUS, f"Failed to remove {item_name} from cart"
            if is_item_removed and mesg == "Success":
                return STATUS, f"I've removed only one {item_name} from cart"

        return STATUS, MESG

    def cart_items_replace(self, session_id, req):
        # Delete the item to be replaced
        STATUS, MESG = self.cart_items_delete(session_id, req)
        if STATUS != 200:
            return STATUS, MESG
        # Add the requested item
        STATUS, MESG = self.cart_items_add(session_id, req)
        if STATUS != 200:
            return STATUS, MESG

        return STATUS, "Item replaced successfully"

    # Note: We don't yet have functionality to distinguish between same item with different toppings already in cart
    def __add_toppings(self, uuid, item_toppings_to_add):
        mesg = "Success"
        item_toppings_to_add["toppings"].sort(key=lambda x: x["item_id"], reverse=False)

        toppings_to_add, mesg = self.__get_toppings_for_item_id(item_toppings_to_add["toppings"])

        if mesg != "Success":
            return mesg

        total_toppings_price = sum(top.price for top in toppings_to_add)
        total_toppings_calories = sum(top.calories for top in toppings_to_add)
        match_found = False
        # Logic to increase the count of item in cart,
        # if similar item config already present
        for cart_item in self._cart_table[uuid].items:
            if cart_item.item_id == item_toppings_to_add["item_id"] and (
                cart_item.size == "" or (cart_item.size != "" and cart_item.size == item_toppings_to_add["size"])
            ):
                cart_item.toppings.extend(toppings_to_add)
                # total_toppings_price = sum(top.price for top in toppings_to_add)
                cart_item.price = round(cart_item.price + cart_item.quantity * total_toppings_price, 2)
                cart_item.calories = round(cart_item.calories + cart_item.quantity * total_toppings_calories, 2)
                self.__update_total_bill_calories(uuid)
                match_found = True

        if not match_found:
            mesg = "Topping could not be added. Check if the requested item is in the cart."

        return mesg

    def cart_toppings_add(self, session_id):
        STATUS = 200
        MESG = "Success"
        session_id = session_id
        print("Adding toppings to the cart for {}".format(session_id))

        if session_id not in self._cart_table:
            print("No cart found for the session {}".format(session_id))
            STATUS = 409
            MESG = "No cart found for the session {}".format(session_id)
            return STATUS, MESG

        items_to_be_updated = req["items"]

        for item in items_to_be_updated:
            mesg = self.__add_toppings(session_id, item)
            if mesg != "Success":
                STATUS = 409
                return STATUS, mesg

        print("The cart is: {}".format(self._cart_table[session_id]))
        return STATUS, MESG

    # Note: We don't yet have functionality to distinguish between same item with different toppings already in cart
    def __remove_toppings(self, uuid, item_topping_to_remove):
        mesg = "Success"
        item_topping_to_remove["toppings"].sort(key=lambda x: x["item_id"], reverse=False)

        toppings_to_remove, mesg = self.__get_toppings_for_item_id(item_topping_to_remove["toppings"])

        if mesg != "Success":
            return mesg
        total_toppings_price = sum(top.price for top in toppings_to_remove)
        total_toppings_calories = sum(top.calories for top in toppings_to_remove)

        print("Item topping to remove: {}".format(item_topping_to_remove))
        # Logic to increase the count of item in cart,
        # if similar item config already present
        for cart_item in self._cart_table[uuid].items:
            if cart_item.item_id == item_topping_to_remove["item_id"] and (
                cart_item.size == "" or (cart_item.size != "" and cart_item.size == item_topping_to_remove["size"])
            ):
                for topping in toppings_to_remove:
                    if topping in cart_item.toppings:
                        cart_item.toppings.remove(topping)
                        cart_item.price = round(cart_item.price - cart_item.quantity * topping.price, 2)
                        cart_item.calories = round(
                            cart_item.calories - cart_item.quantity * total_toppings_calories, 2
                        )

        self.__update_total_bill_calories(uuid)
        self.__fold_cart(uuid)
        return mesg

    def cart_toppings_remove(self, session_id):
        STATUS = 200
        MESG = "Success"
        print("Removing toppings from the cart for {}".format(session_id))

        if session_id not in self._cart_table:
            print("No cart found for the session {}".format(session_id))
            STATUS = 409
            MESG = "No cart found for the session {}".format(session_id)
            return STATUS, MESG

        remove_items = req["remove_items"]

        for item in remove_items:
            mesg = self.__remove_toppings(session_id, item)
            if mesg != "Success":
                STATUS = 409
                return STATUS, mesg

        print("The cart is: {}".format(self._cart_table[session_id]))
        return STATUS, MESG

    def cart_toppings_replace(self, session_id):
        # Delete the topping to be replaced
        STATUS, MESG = self.cart_toppings_remove(session_id, req)
        if STATUS != 200:
            return STATUS, MESG
        # Add the requested topping
        STATUS, MESG = self.cart_toppings_add(session_id, req)
        return STATUS, MESG

    def cart_checkout(self, session_id):
        STATUS = 200
        MESG = "Success"

        if session_id not in self._cart_table:
            print("No cart found for the session {}".format(session_id))
            STATUS = 409
            MESG = "No cart found for the session {}".format(session_id)
            return STATUS, MESG, None

        cart_contents = self._cart_table[session_id]
        del self._cart_table[session_id]
        print("Cart checked out!")
        return STATUS, MESG, cart_contents

    def cart_delete(self, session_id):
        STATUS = 200
        MESG = "Success"

        if session_id not in self._cart_table:
            print("No cart found for the session {}".format(session_id))
            STATUS = 409
            MESG = "No cart found for the session {}".format(session_id)
            return STATUS, MESG

        del self._cart_table[session_id]
        return STATUS, MESG

    def cart_item_delete_by_id(self, session_id, cart_item_id):
        STATUS = 409
        MESG = "Entry not found"

        if session_id not in self._cart_table:
            print("No cart found for the session {}".format(session_id))
            MESG = "No cart found for the session {}".format(session_id)
            return STATUS, MESG

        for cart_item in self._cart_table[session_id].items:
            if cart_item_id == cart_item["cart_item_id"]:
                self._cart_table[session_id].items.remove(cart_item)
                STATUS = 200
                MESG = "Success"
                self.__update_total_bill_calories(session_id)
                return STATUS, MESG

            else:
                STATUS = 409
                MESG = "Cart item id {} not found".format(cart_item_id)
                return STATUS, MESG

        return STATUS, MESG


if __name__ == "__main__":
    cart_manager = CartManager()
    session_id = uuid4()
    print(cart_manager.items_in_cart(session_id))

    req = {
        # "user_id": "17a9bd89-c3aa-4e10-8ff1-461e4f790bd0",
        # "query_id": "1c4a4b6d-39cb-43eb-8f9b-bc88d3878164",
        "items": [
            {"item_id": "17", "quantity": 2, "size": "regular", "toppings": []},
            # {"item_id": "8", "quantity": 1, "size": "small", "toppings": []},
        ],
    }
    # Add items to cart
    cart_manager.cart_items_add(session_id, req)
    cart_manager.get_total_bill(session_id)
    print(cart_manager.items_in_cart(session_id))

    req_remove_item = {
        "user_id": "17a9bd89-c3aa-4e10-8ff1-461e4f790bd0",
        "query_id": "2c5a4b6d-39cb-43eb-8f9b-bc88d3878164",
        "remove_items": [
            {"item_id": "17", "quantity": 1, "size": "regular", "toppings": []},
        ],
    }

    resp = cart_manager.cart_items_delete(session_id, req_remove_item)
    print(resp)
    print(cart_manager.items_in_cart(session_id))

    cart_manager.cart_item_delete_by_id(session_id, 8)

    resp = cart_manager.cart_checkout(session_id)
    print("******* Cart Checkout *******\n", resp)
    print("\nItems In Cart\n\n", cart_manager.items_in_cart(session_id))
