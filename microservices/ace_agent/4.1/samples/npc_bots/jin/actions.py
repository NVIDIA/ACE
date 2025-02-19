"""
 copyright(c) 2024 NVIDIA Corporation.All rights reserved.

 NVIDIA Corporation and its licensors retain all intellectual property
 and proprietary rights in and to this software, related documentation
 and any modifications thereto.Any use, reproduction, disclosure or
 distribution of this software and related documentation without an express
 license agreement from NVIDIA Corporation is strictly prohibited.
"""

import logging

from nemoguardrails.actions.actions import action


logger = logging.getLogger("nemoguardrails")

# Transcript filtering for spurious transcript and filler words. Along with this any transcript less than 3 chars is removed
FILTER_WORDS = [
    "yeah",
    "okay",
    "right",
    "yes",
    "yum",
    "and",
    "one",
    "all",
    "when",
    "thank",
    "but",
    "next",
    "what",
    "i see",
    "the",
    "hmm",
    "mmm",
    "so that",
    "why",
    "that",
    "well",
]

INCLUDE_WORDS = ["hi"]


@action(name="IsSpuriousAction")
async def is_spurious(query):
    """
    Filter transcript less than 3 chars or in FILTER_WORDS list to avoid spurious transcript and filler words.
    """
    if query.strip().lower() in FILTER_WORDS or (len(query) < 3 and query.strip().lower() not in INCLUDE_WORDS):
        return True
    else:
        return False
