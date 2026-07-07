#!/usr/bin/env python3
"""
Lanista Coach Staff Scraper
============================
Scrapes head coach + assistant coach emails from college athletic staff pages
and generates a SQL migration to update the Lanista database.

Usage:
  python3 scrape_coaches.py               # scrape all schools, write migration
  python3 scrape_coaches.py --dry-run     # print results, no files written
  python3 scrape_coaches.py --school "Wake Forest"  # one school only

Output:
  staff_data.json                         # raw scraped data
  ../../supabase/migrations/085_real_coach_emails.sql   # migration file

Setup:
  pip3 install httpx beautifulsoup4 lxml python-dotenv
  cp .env.example .env   # fill in SUPABASE_URL + SUPABASE_SERVICE_KEY
"""

from __future__ import annotations

import argparse
import json
import re
import time
from pathlib import Path

import httpx
from bs4 import BeautifulSoup

SCRIPT_DIR = Path(__file__).parent
CRAWL_DELAY = 2.0
HTTP_TIMEOUT = 20

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (compatible; LanistaBot/1.0; educational research; "
        "contact: icaro@lanista.app)"
    ),
    "Accept": "text/html,application/xhtml+xml",
}

# Titles we keep — coaching staff only
COACHING_KEYWORDS = [
    "head coach", "assistant coach", "associate head coach",
    "director of recruiting", "recruiting coordinator",
    "goalkeeper coach", "goalkeeping", "director of coaching",
    "volunteer assistant",
]

# Titles we explicitly skip
SKIP_KEYWORDS = [
    "trainer", "athletic trainer", "therapist", "counselor", "advisor",
    "administrator", "director of operations", "video coordinator",
    "equipment", "strength", "performance", "nutritionist", "manager",
    "sports information", "communications",
]


def is_coaching_staff(title: str) -> bool:
    t = title.lower()
    if any(k in t for k in SKIP_KEYWORDS):
        return False
    if any(k in t for k in COACHING_KEYWORDS):
        return True
    # Catch generic "coach" not already handled
    if "coach" in t:
        return True
    return False


def derive_staff_url(roster_url: str) -> str:
    """Turn a roster URL into a staff/coaches URL."""
    return re.sub(r"/(roster|schedule|news).*$", "/coaches", roster_url)


def fetch_staff(url: str) -> list[dict]:
    """Fetch a staff page and return list of {name, title, email}."""
    try:
        r = httpx.get(url, headers=HEADERS, timeout=HTTP_TIMEOUT, follow_redirects=True)
        r.raise_for_status()
    except Exception as e:
        print(f"  ⚠  Fetch error: {e}")
        return []

    soup = BeautifulSoup(r.text, "lxml")
    staff = []

    # Strategy 1: HTML table rows (most Sidearm sites)
    for row in soup.select("tr"):
        cells = [td.get_text(strip=True) for td in row.select("td")]
        emails = [a["href"].replace("mailto:", "").strip().lower()
                  for a in row.select("a[href^=mailto]")]
        if emails and len(cells) >= 2:
            name = cells[0]
            title = cells[1] if len(cells) > 1 else ""
            email = emails[0]
            if name and "@" in email:
                staff.append({"name": name, "title": title, "email": email})

    # Strategy 2: s-person-card structure (newer Sidearm)
    if not staff:
        for card in soup.select("s-person-card, .s-person-card, [data-card-type]"):
            name_el = card.select_one("[data-name], .s-person-details__name, h3, h4")
            title_el = card.select_one("[data-title], .s-person-details__title, .staff_title")
            email_link = card.select_one("a[href^=mailto]")
            if name_el and email_link:
                staff.append({
                    "name": name_el.get_text(strip=True),
                    "title": title_el.get_text(strip=True) if title_el else "",
                    "email": email_link["href"].replace("mailto:", "").strip().lower(),
                })

    # Strategy 3: simple mailto scan with nearby name heuristic
    if not staff:
        for a in soup.select("a[href^=mailto]"):
            email = a["href"].replace("mailto:", "").strip().lower()
            # Walk up to find a container with a name
            parent = a.find_parent(["tr", "li", "div", "article"])
            name = a.get_text(strip=True)
            title = ""
            if parent:
                texts = [t.strip() for t in parent.stripped_strings if t.strip() and "@" not in t]
                if texts:
                    name = texts[0]
                    title = texts[1] if len(texts) > 1 else ""
            if "@" in email and name:
                staff.append({"name": name, "title": title, "email": email})

    return staff


def scrape_school(school: dict, dry_run: bool) -> dict:
    name = school["school_name"]
    roster_url = school["roster_url"]

    print(f"\n→ {name}  ({school.get('division', '?')})")

    # Use pre-verified manual staff if provided (staff directory doesn't filter by sport)
    if "manual_staff" in school:
        print(f"  [manual data]")
        coaching = school["manual_staff"]
        coaching.sort(key=lambda s: 0 if "head coach" in s["title"].lower() else 1)
        for s in coaching:
            role = "HC" if "head coach" in s["title"].lower() else "AC"
            print(f"  [{role}] {s['name']} — {s['title']}")
            print(f"         {s['email']}")
        return {"school_name": name, "staff": coaching, "staff_url": "[manual]"}

    staff_url = school.get("staff_url") or derive_staff_url(roster_url)
    print(f"  {staff_url}")

    raw_staff = fetch_staff(staff_url)
    # Check both title and name fields — some sites put the role in cells[0] (inverted tables)
    coaching = [s for s in raw_staff if is_coaching_staff(s["title"]) or is_coaching_staff(s["name"])]

    if not coaching:
        print(f"  ⚠  No coaching staff found ({len(raw_staff)} total staff scraped)")
        return {"school_name": name, "staff": [], "staff_url": staff_url}

    def _is_head_coach(s: dict) -> bool:
        combined = (s.get("title", "") + " " + s.get("name", "")).lower()
        return (
            re.search(r"\bhead\b", combined) is not None
            and re.search(r"\bcoach\b", combined) is not None
            and "associate" not in combined
            and "assistant" not in combined
            and "graduate" not in combined
        )

    # Sort: head coach first
    def sort_key(s):
        if _is_head_coach(s):
            return 0
        if "associate head" in (s["title"] + " " + s["name"]).lower():
            return 1
        return 2

    coaching.sort(key=sort_key)

    for s in coaching:
        role = "HC" if _is_head_coach(s) else "AC"
        print(f"  [{role}] {s['name']} — {s['title']}")
        print(f"         {s['email']}")

    return {"school_name": name, "staff": coaching, "staff_url": staff_url}


def generate_migration(results: list[dict]) -> str:
    """Generate SQL migration that updates coach emails and stores assistant staff."""
    lines = [
        "-- Migration 085: Real coach emails from official athletic staff pages",
        "-- Generated by scrape_coaches.py",
        "--",
        "-- Updates:",
        "--   1. users.email for each head coach (looked up via coaches.school_name)",
        "--   2. coaches.assistant_staff JSONB with assistant coaches",
        "",
        "-- Add assistant_staff column if it doesn't exist",
        "ALTER TABLE coaches ADD COLUMN IF NOT EXISTS",
        "  assistant_staff JSONB NOT NULL DEFAULT '[]'::jsonb;",
        "",
    ]

    for result in results:
        school = result["school_name"]
        staff = result["staff"]
        if not staff:
            lines.append(f"-- ⚠  No staff scraped for {school}")
            continue

        def _is_hc(s):
            c = (s.get("title", "") + " " + s.get("name", "")).lower()
            return (re.search(r"\bhead\b", c) and re.search(r"\bcoach\b", c)
                    and "associate" not in c and "assistant" not in c and "graduate" not in c)

        head_coaches = [s for s in staff if _is_hc(s)]
        assistants = [s for s in staff if not _is_hc(s)]

        esc = school.replace("'", "''")
        lines.append(f"-- ── {school} ──────────────────────────────────────────")

        # Update head coach email in users table
        if head_coaches:
            hc = head_coaches[0]
            email_esc = hc["email"].replace("'", "''")
            # Only update name when it's a real person name, not a role string like "Head Coach"
            name_looks_like_role = is_coaching_staff(hc["name"])
            if name_looks_like_role:
                lines.append(
                    f"UPDATE public.users SET email = '{email_esc}'"
                    f" WHERE id = ("
                    f"   SELECT user_id FROM coaches WHERE school_name = '{esc}' LIMIT 1"
                    f");"
                )
            else:
                name_parts = hc["name"].split(" ", 1)
                first = name_parts[0].replace("'", "''")
                last = (name_parts[1] if len(name_parts) > 1 else "").replace("'", "''")
                lines.append(
                    f"UPDATE public.users SET"
                    f" email = '{email_esc}',"
                    f" first_name = '{first}',"
                    f" last_name = '{last}'"
                    f" WHERE id = ("
                    f"   SELECT user_id FROM coaches WHERE school_name = '{esc}' LIMIT 1"
                    f");"
                )

        # Store all coaching staff (including head coach) in assistant_staff JSONB
        staff_json = json.dumps(staff, ensure_ascii=False).replace("'", "''")
        lines.append(
            f"UPDATE coaches SET assistant_staff = '{staff_json}'::jsonb"
            f" WHERE school_name = '{esc}';"
        )
        lines.append("")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Scrape coach staff emails")
    parser.add_argument("--school", help="Filter by school name substring")
    parser.add_argument("--dry-run", action="store_true", help="Don't write files")
    args = parser.parse_args()

    with open(SCRIPT_DIR / "schools.json", encoding="utf-8") as f:
        schools = json.load(f)
    # Filter out the _note entry
    schools = [s for s in schools if "school_name" in s]

    if args.school:
        schools = [s for s in schools if args.school.lower() in s["school_name"].lower()]
        if not schools:
            print(f"No school matching '{args.school}'")
            return

    print("=" * 60)
    print(f"Lanista Coach Staff Scraper — {len(schools)} schools")
    print(f"Mode: {'DRY RUN' if args.dry_run else 'LIVE'}")
    print("=" * 60)

    results = []
    for i, school in enumerate(schools):
        result = scrape_school(school, args.dry_run)
        results.append(result)
        if i < len(schools) - 1:
            time.sleep(CRAWL_DELAY)

    # Summary
    success = [r for r in results if r["staff"]]
    failed  = [r for r in results if not r["staff"]]
    total_staff = sum(len(r["staff"]) for r in results)

    print("\n" + "=" * 60)
    print("SUMMARY")
    print(f"  ✅ Schools with staff: {len(success)}")
    print(f"  ❌ No staff found:     {len(failed)}")
    print(f"  👥 Total coaches:      {total_staff}")
    if failed:
        print("\nFailed (check staff URL manually):")
        for r in failed:
            print(f"  - {r['school_name']}  {r['staff_url']}")

    if args.dry_run:
        return

    # Write JSON
    json_path = SCRIPT_DIR / "staff_data.json"
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    print(f"\n✅ Wrote {json_path}")

    # Write migration
    migration = generate_migration(results)
    migration_path = SCRIPT_DIR / "../../supabase/migrations/085_real_coach_emails.sql"
    migration_path = migration_path.resolve()
    with open(migration_path, "w", encoding="utf-8") as f:
        f.write(migration)
    print(f"✅ Wrote {migration_path}")
    print("\nNext step: run  supabase db push  from the lanista project root")


if __name__ == "__main__":
    main()
