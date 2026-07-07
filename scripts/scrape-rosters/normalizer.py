"""
Data normalization for scraped college soccer roster data.

Converts raw scraped strings (positions, heights, academic years) into the
canonical formats used by Lanista's database.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Optional


# ── Position mapping ──────────────────────────────────────────────────────────
# Maps raw strings (as scraped from college sites) → Lanista position_key.
# Keys are lowercased + stripped; handle abbreviations, full names, slash combos.

_POSITION_MAP: dict[str, str] = {
    # ── Goalkeeper
    "gk": "gk", "g": "gk", "goalkeeper": "gk", "goalie": "gk",
    "goaltender": "gk", "keeper": "gk",

    # ── Right back
    "rb": "rb", "right back": "rb", "right fullback": "rb",
    "right defender": "rb", "r back": "rb",

    # ── Center back
    "cb": "cb", "center back": "cb", "centre back": "cb",
    "centreback": "cb", "centerback": "cb",
    "central defender": "cb", "central back": "cb",
    "center defender": "cb", "stopper": "cb", "sw": "cb", "sweeper": "cb",

    # ── Left back
    "lb": "lb", "left back": "lb", "left fullback": "lb",
    "left defender": "lb", "l back": "lb",

    # ── Generic defender (default to CB — most common central position)
    "d": "cb", "def": "cb", "defender": "cb", "df": "cb",
    "fb": "cb", "fullback": "cb", "full back": "cb",
    "back": "cb",

    # ── CDM
    "cdm": "cdm", "dm": "cdm", "dmf": "cdm",
    "defensive mid": "cdm", "defensive midfielder": "cdm",
    "holding mid": "cdm", "holding midfielder": "cdm",
    "defensive midfield": "cdm", "d mid": "cdm",

    # ── CM
    "cm": "cm", "cmf": "cm",
    "center mid": "cm", "centre mid": "cm",
    "central mid": "cm", "central midfielder": "cm",
    "center midfielder": "cm", "centre midfielder": "cm",
    "central midfield": "cm",

    # ── CAM
    "cam": "cam", "am": "cam", "amf": "cam",
    "attacking mid": "cam", "attacking midfielder": "cam",
    "attacking midfield": "cam", "playmaker": "cam",
    "a mid": "cam",

    # ── Right midfielder
    "rm": "rm", "right mid": "rm", "right midfielder": "rm",
    "right midfield": "rm",

    # ── Left midfielder
    "lm": "lm", "left mid": "lm", "left midfielder": "lm",
    "left midfield": "lm",

    # ── Generic midfielder (default to CM)
    "m": "cm", "mid": "cm", "mf": "cm", "midfielder": "cm",
    "midfield": "cm",

    # ── Right winger
    "rw": "rw", "right wing": "rw", "right winger": "rw",
    "right wing forward": "rw", "rws": "rw",

    # ── Left winger
    "lw": "lw", "left wing": "lw", "left winger": "lw",
    "left wing forward": "lw", "lws": "lw",

    # ── Generic winger (default to RW — matches the most common college label)
    "w": "rw", "wing": "rw", "winger": "rw", "wide": "rw",

    # ── Striker
    "st": "st", "striker": "st", "target": "st",

    # ── Center forward
    "cf": "cf", "center forward": "cf", "centre forward": "cf",
    "center fwd": "cf", "centre fwd": "cf",

    # ── Generic forward (default to CF as broadest term)
    "f": "cf", "fw": "cf", "fwd": "cf", "forward": "cf",
    "attacker": "cf", "att": "cf",
}

# ── Academic year mapping ─────────────────────────────────────────────────────

_YEAR_MAP: dict[str, str] = {
    # Freshman
    "fr": "Fr", "fr.": "Fr", "fresh": "Fr", "freshman": "Fr",
    "freshmen": "Fr", "1st": "Fr", "1st year": "Fr", "year 1": "Fr",
    "1": "Fr",

    # Sophomore
    "so": "So", "so.": "So", "soph": "So", "sophomore": "So",
    "2nd": "So", "2nd year": "So", "year 2": "So", "2": "So",

    # Junior
    "jr": "Jr", "jr.": "Jr", "junior": "Jr",
    "3rd": "Jr", "3rd year": "Jr", "year 3": "Jr", "3": "Jr",

    # Senior
    "sr": "Sr", "sr.": "Sr", "senior": "Sr",
    "4th": "Sr", "4th year": "Sr", "year 4": "Sr", "4": "Sr",

    # Graduate / 5th year / Redshirt
    "gr": "Grad", "gr.": "Grad", "grad": "Grad", "graduate": "Grad",
    "5th": "Grad", "5th year": "Grad", "year 5": "Grad", "5": "Grad",
    "rs": "Grad", "rs-fr": "Grad", "rs-so": "Grad", "rs-jr": "Grad", "rs-sr": "Grad",
    "redshirt": "Grad", "redshirt freshman": "Fr",
    "grad transfer": "Grad", "transfer": "Grad",
}

# Graduation offset from season year (fall semester reference)
_YEAR_OFFSET: dict[str, int] = {
    "Fr": 4,
    "So": 3,
    "Jr": 2,
    "Sr": 1,
    "Grad": 1,
}


# ── Normalizer functions ──────────────────────────────────────────────────────

def normalize_position(raw: Optional[str]) -> Optional[str]:
    """
    Map a raw position string to a Lanista position_key (gk, cb, st, …).

    Handles slash-separated combos ("GK / CB" → first token), parenthetical
    suffixes ("Defender (CB)" → "cb"), and case/punctuation variants.
    Returns None if unmappable.
    """
    if not raw:
        return None

    # Normalise separators and case
    cleaned = raw.strip().lower()
    cleaned = re.sub(r"['\".()]", "", cleaned)   # remove punctuation
    cleaned = re.sub(r"[\-_]", " ", cleaned)     # hyphen → space
    cleaned = cleaned.strip()

    # Direct lookup on full string
    if cleaned in _POSITION_MAP:
        return _POSITION_MAP[cleaned]

    # Hybrid combo resolution before first-token fallback.
    # College sites often list "F/M", "M/D", etc. — map to the linking position.
    _HYBRID_MAP: dict[tuple[str, str], str] = {
        ("f", "m"): "cam",   ("m", "f"): "cam",   # forward-mid bridge
        ("mid", "fwd"): "cam", ("fwd", "mid"): "cam",
        ("m", "d"): "cdm",   ("d", "m"): "cdm",   # mid-def bridge
        ("d", "mf"): "cdm",  ("mf", "d"): "cdm",
        ("def", "mid"): "cdm", ("mid", "def"): "cdm",
        ("f", "d"): "cam",   ("d", "f"): "cam",   # unusual combo → attacking mid
    }
    tokens = [t.strip() for t in re.split(r"[/,]+", cleaned) if t.strip()]
    if len(tokens) == 2:
        pair = (tokens[0], tokens[1])
        if pair in _HYBRID_MAP:
            return _HYBRID_MAP[pair]

    # Try first token of slash/comma/space-separated combos ("gk / def")
    first = re.split(r"[/,\s]+", cleaned)[0].strip()
    if first in _POSITION_MAP:
        return _POSITION_MAP[first]

    # Substring match as last resort
    for key, val in _POSITION_MAP.items():
        if key in cleaned and len(key) > 1:
            return val

    return None


def normalize_height_cm(raw: Optional[str]) -> Optional[int]:
    """
    Convert raw height string to centimetres.

    Supported formats:
      "6-1"        feet-inches (hyphen-separated)
      "6'1\""      feet-inches (apostrophe)
      "6'01\""     feet-inches with leading zero
      "6 ft 1 in"  feet-inches (text)
      "183"        already in cm (3 digits, no unit)
      "183cm"      cm with unit
      "1.83"       decimal metres
    Returns None if unparseable.
    """
    if not raw:
        return None
    raw = raw.strip()

    # Already in cm: "183" / "183cm" / "183 cm"
    m = re.match(r"^(\d{2,3})\s*cm?$", raw, re.I)
    if m:
        val = int(m.group(1))
        return val if 140 <= val <= 220 else None

    # Decimal metres: "1.83"
    m = re.match(r"^1\.(\d{2})$", raw)
    if m:
        return round(100 + int(m.group(1)))

    # Feet-inches: "6-1", "6'1", "6'1\"", "6 ft 1 in", "6'01\""
    m = re.match(
        r"(\d)\s*(?:ft\.?|feet|'|′)?\s*(?:\-|and|,)?\s*0?(\d{1,2})\s*(?:in\.?|inches|\")?",
        raw, re.I,
    )
    if m:
        feet = int(m.group(1))
        inches = int(m.group(2))
        if 4 <= feet <= 7 and 0 <= inches <= 11:
            return round(feet * 30.48 + inches * 2.54)

    # Just feet: "6'" or "6"
    m = re.match(r"^(\d)'?$", raw)
    if m:
        feet = int(m.group(1))
        return round(feet * 30.48) if 4 <= feet <= 7 else None

    return None


def normalize_academic_year(raw: Optional[str]) -> Optional[str]:
    """
    Normalize raw year/class label → one of: Fr / So / Jr / Sr / Grad.
    Returns None if unmappable.
    """
    if not raw:
        return None
    cleaned = raw.strip().lower()
    cleaned = re.sub(r"[.\-]", "", cleaned).strip()  # "Jr." → "jr", "rs-fr" → "rsfr"... handled via map
    return _YEAR_MAP.get(cleaned)


def compute_graduation_year(academic_year: Optional[str], season_year: int) -> Optional[int]:
    """
    Estimate graduation year from academic year label and the fall season year.

    E.g. a Freshman in the 2025 season is expected to graduate in 2029.
    Grad students / 5th-years are treated as graduating in season_year + 1.
    """
    if not academic_year:
        return None
    offset = _YEAR_OFFSET.get(academic_year)
    return season_year + offset if offset is not None else None


# ── Dataclass returned by the normalizer pipeline ────────────────────────────

@dataclass
class NormalizedPlayer:
    name: str
    position_raw: Optional[str]
    position_key: Optional[str]
    academic_year: Optional[str]
    graduation_year: Optional[int]
    height_cm: Optional[int]
    hometown: Optional[str]
    high_school: Optional[str]
    jersey_number: Optional[str]
