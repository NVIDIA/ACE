import re


def validate_url(url: str):
    """
    This function checks if the input string adheres to a format like "http://20.235.248.119:8081".

    Args:
        url: The URL string to validate.

    Returns:
        True if the URL is valid, False otherwise.
    """
    regex = r"^https?://\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:[1-9]\d{0,4}$"
    return re.match(regex, url) is not None
