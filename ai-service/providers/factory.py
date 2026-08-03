from __future__ import annotations

import os

from providers.base import AIProvider
from providers.rule_based import RuleBasedProvider


def build_provider() -> AIProvider:
    provider_name = os.getenv("FS25AI_PROVIDER", "rule-based").strip().lower()
    if provider_name == "rule-based":
        return RuleBasedProvider()
    raise ValueError(f"Unsupported provider '{provider_name}'.")
