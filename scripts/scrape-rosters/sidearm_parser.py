"""
Sidearm Sports roster page parser.

Sidearm Sports is the dominant college athletics CMS (~75% of NCAA programs).
Their HTML follows consistent patterns but has evolved across versions; this
parser tries multiple selector strategies in order of reliability.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Optional

from bs4 import BeautifulSoup, Tag


@dataclass
class RawRosterPlayer:
    name: str
    position_raw: Optional[str] = None
    academic_year_raw: Optional[str] = None
    height_raw: Optional[str] = None
    hometown: Optional[str] = None
    high_school: Optional[str] = None
    jersey_number: Optional[str] = None


def parse_sidearm_roster(html: str) -> list[RawRosterPlayer]:
    """
    Parse a college soccer roster page.
    Tries strategies in order:
      1. Sidearm NextGen (2022+): div.s-person-card with bio-stats spans
      2. Modern Sidearm (2018-2022): li.s-person-card / data-label attributes
      3. Classic Sidearm (2015-2018): li.roster-player with class-based fields
      4. OAS / Nuxt JSON payload (Stanford, some other OAS schools)
      5. Table-based fallback
    Returns deduplicated list (NextGen renders each card twice for grid/list views).
    """
    soup = BeautifulSoup(html, "lxml")

    players = _parse_nextgen_sidearm(soup)
    if players:
        return players

    players = _parse_modern_sidearm(soup)
    if players:
        return players

    players = _parse_classic_sidearm(soup)
    if players:
        return players

    players = _parse_oas_nuxt_json(html)
    if players:
        return players

    players = _parse_table_roster(soup)
    return players


# ── Strategy 1: Sidearm NextGen (2022+) ──────────────────────────────────────

# Labels used in bio-stats spans — order matters (longest first to avoid prefix clash)
_NEXTGEN_LABELS = [
    "Academic Year", "Previous School", "Last School",
    "Hometown", "Position", "Height", "Weight",
]

def _parse_nextgen_sidearm(soup: BeautifulSoup) -> list[RawRosterPlayer]:
    """
    Sidearm NextGen (2022+): div.s-person-card with s-person-details__bio-stats-item spans.
    Each bio-stats span concatenates label + value: "Position GK", "Height 6' 1''".
    Cards are rendered twice (grid + list view) — deduplicate by name.
    """
    containers = soup.select("div.s-person-card")
    if not containers:
        return []

    seen: set[str] = set()
    players: list[RawRosterPlayer] = []

    for card in containers:
        name_el = card.select_one(
            "div.s-person-details__personal-single-line, "
            "div.s-person-details__personal-name, "
            ".s-person-details__personal"
        )
        if not name_el:
            continue
        name = name_el.get_text(" ", strip=True).strip()
        if not name or name in seen:
            continue
        seen.add(name)

        player = RawRosterPlayer(name=name)

        # Bio-stats items: "Position GK", "Academic Year So.", "Height 6' 1''"
        for stat in card.select("span.s-person-details__bio-stats-item"):
            raw = stat.get_text(" ", strip=True)
            for label in _NEXTGEN_LABELS:
                if raw.startswith(label):
                    value = raw[len(label):].strip()
                    _assign_field(player, label.lower(), value)
                    break

        # Hometown: span.s-person-card__content__person__location-item → "HometownCity, ST"
        loc = card.select_one("span.s-person-card__content__person__location-item")
        if loc and not player.hometown:
            loc_text = loc.get_text(" ", strip=True)
            if loc_text.startswith("Hometown"):
                player.hometown = loc_text[len("Hometown"):].strip()

        # Jersey number: s-stamp__text (skip sr-only child)
        stamp = card.select_one(".s-stamp__text")
        if stamp and not player.jersey_number:
            # Remove sr-only text ("Jersey Number"), keep numeric text
            for sr in stamp.select(".sr-only"):
                sr.decompose()
            player.jersey_number = stamp.get_text(strip=True) or None

        players.append(player)

    return players


# ── Strategy 2: Modern Sidearm (2020+) ───────────────────────────────────────

def _parse_modern_sidearm(soup: BeautifulSoup) -> list[RawRosterPlayer]:
    """
    Modern Sidearm pages use s-person-card elements with [data-label] attributes
    on each field, making parsing reliable regardless of visual layout.
    """
    containers = (
        soup.select("li.s-person-card")
        or soup.select("li.roster-player.s-person-card")
        or soup.select("[class*='s-person-card']")
    )
    if not containers:
        return []

    players = []
    for card in containers:
        name = _first_text(card, [
            ".s-person-details__personal-name",
            ".s-person-details__name",
            "h3.sidearm-roster-player-name",
            ".sidearm-roster-player-name",
        ])
        if not name:
            continue

        player = RawRosterPlayer(name=name.strip())

        # data-label is the most reliable — each field element carries its label
        for el in card.select("[data-label]"):
            label = (el.get("data-label") or "").lower().strip()
            value = (
                _first_text(el, [".field-value", "span", "dd"])
                or el.get_text(" ", strip=True)
            )
            _assign_field(player, label, value)

        # Class-name fallbacks for fields not covered by data-label
        if not player.jersey_number:
            player.jersey_number = _first_text(card, [
                ".s-person-card__jersey-number",
                "[class*='jersey']",
                ".roster-number",
            ])
        if not player.position_raw:
            player.position_raw = _first_text(card, [
                "[class*='position'] .field-value",
                ".sidearm-roster-player-position",
            ])
        if not player.academic_year_raw:
            player.academic_year_raw = _first_text(card, [
                "[class*='academic'] .field-value",
                "[class*='year'] .field-value",
                ".sidearm-roster-player-academic-year",
            ])
        if not player.height_raw:
            player.height_raw = _first_text(card, [
                "[class*='height'] .field-value",
                ".sidearm-roster-player-height",
            ])
        if not player.hometown:
            player.hometown = _first_text(card, [
                "[class*='hometown'] .field-value",
                ".sidearm-roster-player-hometown",
            ])

        players.append(player)

    return players


# ── Strategy 2: Classic Sidearm (2015–2019) ───────────────────────────────────

def _parse_classic_sidearm(soup: BeautifulSoup) -> list[RawRosterPlayer]:
    """
    Older Sidearm pages use li.roster-player with nested class-named spans
    for each field (no data-label).
    """
    containers = soup.select("li.roster-player") or soup.select("li.rosterplayer")
    if not containers:
        return []

    players = []
    for card in containers:
        name = _first_text(card, [
            ".sidearm-roster-player-name h3 a",
            ".sidearm-roster-player-name h3",
            ".sidearm-roster-player-name a",
            ".roster_player_name",
            "h3",
        ])
        if not name:
            continue

        player = RawRosterPlayer(name=name.strip())

        player.jersey_number = _first_text(card, [".sidearm-roster-player-jersey-number", ".number"])
        player.position_raw  = _first_text(card, [".sidearm-roster-player-position span", ".sidearm-roster-player-position"])
        player.academic_year_raw = _first_text(card, [".sidearm-roster-player-academic-year span", ".sidearm-roster-player-year span"])
        player.height_raw    = _first_text(card, [".sidearm-roster-player-height span", ".sidearm-roster-player-ht span"])
        player.hometown      = _first_text(card, [".sidearm-roster-player-hometown span", ".sidearm-roster-player-city span"])
        player.high_school   = _first_text(card, [".sidearm-roster-player-highschool span", ".sidearm-roster-player-previous-school span"])

        players.append(player)

    return players


# ── Strategy 4: OAS / Nuxt __NUXT_DATA__ JSON (Stanford, Clemson, Virginia…) ──

def _parse_oas_nuxt_json(html: str) -> list[RawRosterPlayer]:
    """
    OAS (Official Athletics Site) is a Nuxt.js CMS used by ~15% of Power 5
    programs (Stanford, Clemson, Virginia, Wake Forest, etc.).

    The page embeds a flat deduplication array in a <script id="__NUXT_DATA__">
    tag.  Every value appears once; objects store integer indices as field values
    that point back into the array.  This function:
      1. Finds the script tag and parses the JSON array.
      2. Locates the {'players': N, 'meta': M} dict that marks the roster section.
      3. Dereferences each player's fields to produce RawRosterPlayer objects.
    """
    import json, re

    # Extract the flat data array from the <script id="__NUXT_DATA__"> tag.
    script_match = re.search(
        r'id=["\']__NUXT_DATA__["\'][^>]*>(.*?)</script>',
        html, re.DOTALL,
    )
    if not script_match:
        return []

    try:
        data: list = json.loads(script_match.group(1))
    except (json.JSONDecodeError, ValueError):
        return []

    def _val(idx):
        """Resolve one level of indirection (index → value in data array)."""
        if isinstance(idx, int) and 0 <= idx < len(data):
            return data[idx]
        return idx

    players: list[RawRosterPlayer] = []

    # Find the roster section: a dict with {'players': <int>, 'meta': <int>}
    for entry in data:
        if not (isinstance(entry, dict) and 'players' in entry
                and isinstance(entry.get('players'), int)):
            continue

        player_list = _val(entry['players'])
        if not isinstance(player_list, list):
            continue

        for pidx in player_list:
            try:
                # Each index points to a roster entry schema
                roster_entry = _val(pidx)
                if not isinstance(roster_entry, dict):
                    continue

                # The 'player' field points to the master player object
                player_obj = _val(roster_entry.get('player'))
                if not isinstance(player_obj, dict):
                    continue

                fn   = _val(player_obj.get('first_name'))
                ln   = _val(player_obj.get('last_name'))
                name = f"{fn or ''} {ln or ''}".strip()
                if not name:
                    continue

                # Height: integer feet / inches stored as indices
                hf = _val(player_obj.get('height_feet'))
                hi = _val(player_obj.get('height_inches'))
                height_raw = (
                    f"{hf}'{hi}\""
                    if isinstance(hf, int) and isinstance(hi, int) else None
                )

                # Position: {'abbreviation': idx, 'name': idx}
                pos_schema = _val(roster_entry.get('player_position'))
                pos_raw = None
                if isinstance(pos_schema, dict):
                    pos_raw = _val(pos_schema.get('abbreviation') or pos_schema.get('name'))

                # Academic year / class level: {'name': idx, ...}
                cls_schema = _val(roster_entry.get('class_level'))
                year_raw = None
                if isinstance(cls_schema, dict):
                    year_raw = _val(cls_schema.get('name'))

                hometown  = _val(player_obj.get('hometown'))
                hs        = _val(player_obj.get('high_school'))
                jersey    = _val(player_obj.get('jersey_number') or
                                 roster_entry.get('jersey_number'))

                players.append(RawRosterPlayer(
                    name            = name,
                    position_raw    = str(pos_raw)  if pos_raw  else None,
                    academic_year_raw = str(year_raw) if year_raw else None,
                    height_raw      = height_raw,
                    hometown        = str(hometown)  if isinstance(hometown, str) else None,
                    high_school     = str(hs)        if isinstance(hs, str)       else None,
                    jersey_number   = str(jersey)    if jersey is not None         else None,
                ))
            except Exception:
                continue  # skip malformed entries silently

        if players:
            break  # stop after finding the first player section

    return players


# ── Strategy 5: Table-based roster ────────────────────────────────────────────

def _parse_table_roster(soup: BeautifulSoup) -> list[RawRosterPlayer]:  # noqa: E302
    """
    Fallback for table-format roster pages (used by some D3/NAIA programs and
    non-Sidearm platforms).  Reads column headers from <th> to map values.
    """
    players = []

    for table in soup.find_all("table"):
        rows = table.find_all("tr")
        if len(rows) < 3:
            continue  # too small to be a roster table

        # Extract headers from first row
        header_row = rows[0]
        headers = [
            th.get_text(" ", strip=True).lower()
            for th in header_row.find_all(["th", "td"])
        ]

        # Need at least a "name" column to proceed
        has_name_col = any("name" in h or "player" in h for h in headers)
        if not has_name_col:
            continue

        for row in rows[1:]:
            cells = row.find_all(["td", "th"])
            if len(cells) < 2:
                continue

            player = RawRosterPlayer(name="")
            for i, cell in enumerate(cells):
                label = headers[i] if i < len(headers) else ""
                value = cell.get_text(" ", strip=True)
                if any(k in label for k in ("name", "player")):
                    if value and value.lower() not in ("name", "player", "full name"):
                        player.name = value
                else:
                    _assign_field(player, label, value)

            if player.name:
                players.append(player)

        if players:
            return players  # stop after first successful table

    return players


# ── Helpers ───────────────────────────────────────────────────────────────────

def _first_text(element: Tag, selectors: list[str]) -> Optional[str]:
    """Try CSS selectors in order; return first non-empty text found."""
    for selector in selectors:
        el = element.select_one(selector)
        if el:
            text = el.get_text(" ", strip=True)
            if text:
                return text
    return None


def _assign_field(player: RawRosterPlayer, label: str, value: str) -> None:
    """Map a label/value pair onto the appropriate RawRosterPlayer field."""
    if not value or not label:
        return
    label = label.lower().strip()

    if any(k in label for k in ("pos", "position")):
        if not player.position_raw:
            player.position_raw = value

    elif any(k in label for k in ("year", "class", "academic", "eligibility", "yr", "cl")):
        if not player.academic_year_raw:
            player.academic_year_raw = value

    elif label in ("ht", "height") or "height" in label:
        if not player.height_raw:
            player.height_raw = value

    elif any(k in label for k in ("hometown", "home town", "city", "home")):
        if not player.hometown:
            # Strip country if present ("Los Angeles, CA / USA" → "Los Angeles, CA")
            player.hometown = value.split("/")[0].strip()

    elif any(k in label for k in ("high school", "highschool", "school", "prep", "last school", "previous")):
        if not player.high_school:
            player.high_school = value

    elif any(k in label for k in ("#", "no", "num", "number", "jersey", "uniform")):
        if not player.jersey_number:
            # Remove non-digits except hyphen
            player.jersey_number = re.sub(r"[^\d\-]", "", value) or None
