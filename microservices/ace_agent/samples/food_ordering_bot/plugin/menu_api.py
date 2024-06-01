"""
 copyright(c) 2023 NVIDIA Corporation.All rights reserved.

 NVIDIA Corporation and its licensors retain all intellectual property
 and proprietary rights in and to this software, related documentation
 and any modifications thereto.Any use, reproduction, disclosure or
 distribution of this software and related documentation without an express
 license agreement from NVIDIA Corporation is strictly prohibited.
"""

import json
import os
import re
from pathlib import Path
from typing import Any, Dict, List, Optional

from tinydb import Query, TinyDB


class MenuDB:
    def __init__(self) -> None:
        """Create a menu database using TinyDB and store all the menu items in database"""
        self.db = self._create_db()
        self._sample_value = self.get_item_from_id("25")

    def _create_db(self) -> TinyDB:
        """Initialize database and add menu items into database"""
        DATABASE = "database.json"
        MENU_API = os.path.join(os.path.dirname(os.path.abspath(__file__)), "all_gtc_items_with_diff_sizes_v3.json")

        # Remove older database
        Path(DATABASE).unlink(missing_ok=True)
        # Create database object
        db = TinyDB(DATABASE)

        # load the food items json file
        with open(MENU_API) as f:
            data = json.load(f)

        # Insert the menu data into the database
        db.insert_multiple(data)
        return db

    def get_all_menu_item(self) -> List[Dict[str, Any]]:
        """Return all the items in the menu"""
        return self.db.all()

    def get_item_from_id(self, id: str) -> Optional[Dict[str, Any]]:
        query = Query()
        res = self.db.search(query.item_id == id)
        if len(res) >= 1:
            return res[0]
        return None

    def filter_query(self, filters):
        def _is_regex(text):
            if isinstance(text, (int, float)):
                return False
            return text.startswith("regex:")

        def _compile_regex(text):
            try:
                return re.compile(r"(?i)\b" + text.replace("regex:", "").strip() + r"\b")
            except Exception:
                raise ValueError("Invalid regular expression: {}".format(text))

        def comparison_op(field, value, op):
            query = Query()

            field_type = self._sample_value.get(field)
            is_regex = False
            if _is_regex(value):
                value = _compile_regex(f"{value}")
                is_regex = True

            if op == "eq":
                if isinstance(field_type, list):
                    if is_regex:
                        return getattr(query, field).test(lambda x: any(re.search(value, item) for item in x))
                    query = getattr(query, field).any(value)
                else:
                    if is_regex:
                        return getattr(query, field).test(MenuDB.regex_match, value)
                    query = getattr(query, field) == value
            elif op == "ne":
                if isinstance(field_type, list):
                    if is_regex:
                        return ~getattr(query, field).test(lambda x: any(re.search(value, item) for item in x))
                    query = ~getattr(query, field).any(value)
                else:
                    if is_regex:
                        return ~getattr(query, field).test(MenuDB.regex_match, value)
                    query = getattr(query, field) != value
            return query

        logical_ops = {"and": "&", "or": "|"}
        query = Query()
        try:
            for i, filter in enumerate(filters):
                logical_op = logical_ops.get(filter.get("logical", ""), "")
                value = filter["values"]
                comp = filter["condition"]
                field = filter["field"]

                if logical_op == "&":
                    query = query & comparison_op(field, value, comp)
                elif logical_op == "|":
                    query = query | comparison_op(field, value, comp)
                else:
                    query = comparison_op(field, value, comp)

            result = self.db.search(query)
            return {"items": result}
        except Exception as e:
            print(f"Exception {e} while building response")
            return {"items": []}

    @staticmethod
    def regex_match(query, pattern):
        return re.search(pattern, query) is not None
