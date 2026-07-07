#!/usr/bin/env python3
"""
Lanista Roster Scraper
======================
Scrapes college soccer rosters from Sidearm Sports athletic websites and
uploads the normalized data to the Lanista Supabase database.

Usage:
  python scraper.py                         # scrape all schools in schools.json
  python scraper.py --school "Stanford"     # scrape one school (substring match)
  python scraper.py --season 2026           # specify season year (default: 2025)
  python scraper.py --dry-run               # parse + print, don't write to DB
  python scraper.py --gender women          # women's soccer (when URLs configured)

Setup:
  pip install -r requirements.txt
  cp .env.example .env                      # fill in SUPABASE_URL + SUPABASE_SERVICE_KEY
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from pathlib import Path
from typing import Optional

import httpx
from dotenv import load_dotenv

from sidearm_parser import parse_sidearm_roster
from normalizer import (
    normalize_position,
    normalize_height_cm,
    normalize_academic_year,
    compute_graduation_year,
    NormalizedPlayer,
)

# ── Config ────────────────────────────────────────────────────────────────────

load_dotenv()

SUPABASE_URL = os.environ.get("SUPABASE_URL", "")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_KEY", "")  # service_role bypasses RLS
SCRIPT_DIR   = Path(__file__).parent

# Polite crawl delay between schools (seconds)
CRAWL_DELAY = 2.5

# HTTP timeout per request
HTTP_TIMEOUT = 25

# Max players per school (sanity check — rosters > 60 are probably parse errors)
MAX_PLAYERS = 60

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (compatible; LanistaBot/1.0; educational research; "
        "contact: icaro@lanista.app)"
    ),
    "Accept": "text/html,application/xhtml+xml",
    "Accept-Language": "en-US,en;q=0.9",
}


# ── School registry ───────────────────────────────────────────────────────────

def load_schools(gender: str = "men") -> list[dict]:
    path = SCRIPT_DIR / "schools.json"
    with open(path, encoding="utf-8") as f:
        all_schools: list[dict] = json.load(f)
    return [s for s in all_schools if s.get("gender", "men") == gender]


# ── HTTP helpers ──────────────────────────────────────────────────────────────

def fetch_html(url: str) -> Optional[str]:
    """Fetch a URL and return the response body, or None on error."""
    try:
        resp = httpx.get(
            url,
            headers=HEADERS,
            timeout=HTTP_TIMEOUT,
            follow_redirects=True,
        )
        resp.raise_for_status()
        return resp.text
    except httpx.HTTPStatusError as e:
        print(f"  ⚠  HTTP {e.response.status_code}: {url}")
    except httpx.RequestError as e:
        print(f"  ⚠  Request error: {e}")
    return None


# ── Supabase helpers ──────────────────────────────────────────────────────────

def _sb_headers() -> dict[str, str]:
    return {
        "apikey":        SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type":  "application/json",
        "Prefer":        "return=minimal",
    }


def get_coach_id(school_name: str) -> Optional[str]:
    """Return the Lanista coach.id for a given school_name, or None."""
    resp = httpx.get(
        f"{SUPABASE_URL}/rest/v1/coaches",
        params={
            "school_name": f"eq.{school_name}",
            "select":      "id",
            "limit":       "1",
        },
        headers=_sb_headers(),
        timeout=10,
    )
    data = resp.json()
    if isinstance(data, list) and data:
        return data[0].get("id")
    return None


def delete_existing(coach_id: str, season_year: int) -> None:
    """Remove previously scraped players for this coach+season before re-inserting."""
    httpx.delete(
        f"{SUPABASE_URL}/rest/v1/college_roster_players",
        params={
            "coach_id":    f"eq.{coach_id}",
            "season_year": f"eq.{season_year}",
        },
        headers=_sb_headers(),
        timeout=10,
    )


def insert_players(rows: list[dict]) -> bool:
    """Upload player rows in batches of 100. Returns True on success."""
    for i in range(0, len(rows), 100):
        batch = rows[i : i + 100]
        resp = httpx.post(
            f"{SUPABASE_URL}/rest/v1/college_roster_players",
            json=batch,
            headers=_sb_headers(),
            timeout=15,
        )
        if resp.status_code not in (200, 201):
            print(f"  ✗  Upload error {resp.status_code}: {resp.text[:200]}")
            return False
    return True


def log_scrape(coach_id: str, season_year: int, url: str, status: str,
               count: int, error: Optional[str] = None) -> None:
    httpx.post(
        f"{SUPABASE_URL}/rest/v1/roster_scrape_log",
        json={
            "coach_id":    coach_id,
            "season_year": season_year,
            "roster_url":  url,
            "status":      status,
            "player_count": count,
            "error_detail": error,
        },
        headers=_sb_headers(),
        timeout=10,
    )


# ── Core scrape logic ─────────────────────────────────────────────────────────

def scrape_school(school: dict, season_year: int, dry_run: bool) -> dict:
    """
    Scrape one school, normalize, and optionally upload.
    Returns a result dict: {school, status, count}.
    """
    name = school["school_name"]
    url  = school["roster_url"]
    platform = school.get("platform", "sidearm")

    print(f"\n→ {name}  [{school.get('division', '?')}]")
    print(f"  {url}")

    # ── Fetch HTML
    html = fetch_html(url)
    if not html:
        return {"school": name, "status": "failed", "count": 0}

    # ── Parse
    raw_players = parse_sidearm_roster(html)

    if not raw_players:
        print(
            f"  ⚠  No players parsed — site may use a non-Sidearm structure.\n"
            f"     Open {url} in a browser and inspect the HTML.\n"
            f"     The parser supports: li.roster-player, s-person-card, table rows."
        )
        return {"school": name, "status": "failed", "count": 0}

    if len(raw_players) > MAX_PLAYERS:
        print(f"  ⚠  {len(raw_players)} players parsed — suspiciously high. Capping at {MAX_PLAYERS}.")
        raw_players = raw_players[:MAX_PLAYERS]

    # ── Normalize
    normalized: list[NormalizedPlayer] = []
    for rp in raw_players:
        acad = normalize_academic_year(rp.academic_year_raw)
        normalized.append(NormalizedPlayer(
            name           = rp.name,
            position_raw   = rp.position_raw,
            position_key   = normalize_position(rp.position_raw),
            academic_year  = acad,
            graduation_year= compute_graduation_year(acad, season_year),
            height_cm      = normalize_height_cm(rp.height_raw),
            hometown       = rp.hometown,
            high_school    = rp.high_school,
            jersey_number  = rp.jersey_number,
        ))

    print(f"  ✓  {len(normalized)} players parsed")

    # Position coverage stats
    with_pos = sum(1 for p in normalized if p.position_key)
    with_ht  = sum(1 for p in normalized if p.height_cm)
    print(
        f"     position: {with_pos}/{len(normalized)}  "
        f"height: {with_ht}/{len(normalized)}"
    )

    # ── Dry run: print sample and exit
    if dry_run:
        print("  [DRY RUN] Sample output:")
        for p in normalized[:5]:
            h = f"{p.height_cm}cm" if p.height_cm else "—"
            print(
                f"    #{p.jersey_number or '?':>2}  {p.name:<22}  "
                f"{p.position_raw or '—':>10} → {p.position_key or '?':>4}  "
                f"{h:>6}  {p.academic_year or '—':>4}  {p.graduation_year or '—'}"
            )
        if len(normalized) > 5:
            print(f"    … and {len(normalized) - 5} more")
        return {"school": name, "status": "dry_run", "count": len(normalized)}

    # ── DB write
    coach_id = get_coach_id(name)
    if not coach_id:
        print(f"  ⚠  No coach in DB for '{name}' — run after seeding coaches.")
        return {"school": name, "status": "no_coach", "count": len(normalized)}

    delete_existing(coach_id, season_year)

    rows = [
        {
            "coach_id":       coach_id,
            "season_year":    season_year,
            "jersey_number":  p.jersey_number,
            "player_name":    p.name,
            "position_raw":   p.position_raw,
            "position_key":   p.position_key,
            "academic_year":  p.academic_year,
            "graduation_year":p.graduation_year,
            "height_cm":      p.height_cm,
            "hometown":       p.hometown,
            "high_school":    p.high_school,
            "source_url":     url,
        }
        for p in normalized
    ]

    success = insert_players(rows)
    if success:
        log_scrape(coach_id, season_year, url, "success", len(rows))
        print(f"  ✅ Uploaded {len(rows)} players")
        return {"school": name, "status": "success", "count": len(rows)}
    else:
        log_scrape(coach_id, season_year, url, "failed", 0, "insert error")
        return {"school": name, "status": "failed", "count": 0}


# ── CLI ───────────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Scrape college soccer rosters → Lanista DB",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("--school",  help="Scrape only schools whose name contains this string")
    parser.add_argument("--season",  type=int, default=2025, help="Season year (default: 2025)")
    parser.add_argument("--gender",  choices=["men", "women"], default="men")
    parser.add_argument("--dry-run", action="store_true", help="Parse but don't write to DB")
    args = parser.parse_args()

    # Validate env
    if not args.dry_run and (not SUPABASE_URL or not SUPABASE_KEY):
        print("ERROR: Set SUPABASE_URL and SUPABASE_SERVICE_KEY in .env")
        sys.exit(1)

    schools = load_schools(args.gender)
    if args.school:
        schools = [s for s in schools if args.school.lower() in s["school_name"].lower()]
        if not schools:
            print(f"No school matching '{args.school}' in schools.json")
            sys.exit(1)

    print("=" * 60)
    print(f"Lanista Roster Scraper — {args.season} season  ({args.gender}'s soccer)")
    print(f"Mode: {'DRY RUN (no DB writes)' if args.dry_run else 'LIVE'}")
    print(f"Schools: {len(schools)}")
    print("=" * 60)

    results = []
    for i, school in enumerate(schools):
        result = scrape_school(school, args.season, args.dry_run)
        results.append(result)
        if i < len(schools) - 1:
            time.sleep(CRAWL_DELAY)  # polite delay

    # ── Summary
    success  = [r for r in results if r["status"] in ("success", "dry_run")]
    failed   = [r for r in results if r["status"] == "failed"]
    no_coach = [r for r in results if r["status"] == "no_coach"]
    total    = sum(r["count"] for r in results)

    print("\n" + "=" * 60)
    print("SUMMARY")
    print(f"  ✅ Parsed OK : {len(success)} schools")
    print(f"  ❌ Failed    : {len(failed)} schools")
    if no_coach:
        print(f"  ⚠  No coach  : {len(no_coach)} schools")
    print(f"  👥 Total players: {total}")

    if failed:
        print("\nFailed schools (check HTML structure manually):")
        for r in failed:
            print(f"  - {r['school']}")

    if no_coach:
        print("\nSchools with no matching coach in DB:")
        for r in no_coach:
            print(f"  - {r['school']}")


if __name__ == "__main__":
    main()
