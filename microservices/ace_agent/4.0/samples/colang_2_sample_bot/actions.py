# Custom Actions can be defined in an actions.py file and called from Colang

from nemoguardrails.actions.actions import action
from datetime import datetime


@action(name="GetCurrentDateTimeAction")
async def get_current_date_time_action() -> str:
    return f"current time ISO Format: {datetime.now().isoformat()}"
