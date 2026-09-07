import html
import re
from typing import Any
from pydantic import BaseModel, ConfigDict, field_validator

class StrictInputSchema(BaseModel):
    """
    Point 8 & 14: Strict Pydantic v2 input model.
    Enforces extra='forbid' to eliminate parameter pollution and field tampering attacks.
    Trims strings, strips control tags, and normalizes inputs.
    """
    model_config = ConfigDict(
        extra="forbid",
        str_strip_whitespace=True,
        validate_assignment=True
    )

    @field_validator("*", mode="before")
    @classmethod
    def sanitize_strings(cls, value: Any) -> Any:
        if isinstance(value, str):
            # Point 15: Escape HTML and script tags to prevent stored XSS in draft exports
            cleaned = html.escape(value.strip())
            # Strip control characters except newline and tab
            return re.sub(r"[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]", "", cleaned)
        return value


class StrictOutputSchema(BaseModel):
    """
    Point 17: Strict response projection model.
    Prevents API leaks by stripping unexposed database columns, internal credentials,
    and raw upstream third-party dumps.
    """
    model_config = ConfigDict(
        extra="ignore",
        from_attributes=True
    )
