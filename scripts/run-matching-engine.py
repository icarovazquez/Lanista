#!/usr/bin/env python3
"""
Run the Lanista matching engine for all players (or a specific player).
Usage:
  python3 run-matching-engine.py              # all players
  python3 run-matching-engine.py <user_id>    # single player
"""

import sys
import time
from pathlib import Path
import requests

# Load env from scraper directory
env_path = Path(__file__).parent / 'scrape-rosters' / '.env'
env = {}
for line in env_path.read_text().splitlines():
    if '=' in line and not line.startswith('#'):
        k, v = line.split('=', 1)
        env[k.strip()] = v.strip()

SUPABASE_URL = env['SUPABASE_URL']
SERVICE_KEY  = env['SUPABASE_SERVICE_KEY']
FUNCTION_URL = f"{SUPABASE_URL}/functions/v1/match-players"

HEADERS = {
    'Content-Type': 'application/json',
    'Authorization': f'Bearer {SERVICE_KEY}',
    'apikey': SERVICE_KEY,
}


def get_all_player_user_ids():
    url = f"{SUPABASE_URL}/rest/v1/players?select=user_id&is_discoverable=eq.true"
    resp = requests.get(url, headers=HEADERS)
    resp.raise_for_status()
    return [r['user_id'] for r in resp.json()]


def run_engine_for(user_id: str) -> dict:
    try:
        resp = requests.post(FUNCTION_URL, json={'player_id': user_id},
                             headers=HEADERS, timeout=30)
        if resp.ok:
            return {'ok': True, 'data': resp.json()}
        return {'ok': False, 'status': resp.status_code, 'error': resp.text}
    except Exception as ex:
        return {'ok': False, 'error': str(ex)}


def main():
    if len(sys.argv) > 1:
        user_ids = [sys.argv[1]]
        print(f"Running matching engine for 1 player: {user_ids[0]}")
    else:
        print("Fetching all discoverable players…")
        user_ids = get_all_player_user_ids()
        print(f"Found {len(user_ids)} players")

    ok_count = 0
    fail_count = 0

    for i, uid in enumerate(user_ids, 1):
        result = run_engine_for(uid)
        if result['ok']:
            data = result.get('data', {})
            n = data.get('matches_computed', '?')
            top = data.get('top_score', '?')
            print(f"  [{i}/{len(user_ids)}] ✅  {uid[:8]}… → {n} matches (top {top}%)")
            ok_count += 1
        else:
            print(f"  [{i}/{len(user_ids)}] ❌  {uid[:8]}… → {result.get('error', result.get('status'))}")
            fail_count += 1
        # Small delay to avoid hammering the edge function
        if i < len(user_ids):
            time.sleep(0.5)

    print(f"\n{'='*50}")
    print(f"Done: {ok_count} succeeded, {fail_count} failed")


if __name__ == '__main__':
    main()
