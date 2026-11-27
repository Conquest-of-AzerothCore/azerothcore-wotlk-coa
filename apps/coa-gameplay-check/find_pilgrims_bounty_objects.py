#!/usr/bin/env python3
"""Find Pilgrim's Bounty gameobject IDs at Light's Hope Chapel."""

import argparse
import json
import sqlite3
from pathlib import Path

def find_pilgrims_bounty_objects(db_path: Path, x: float, y: float, radius: float = 50.0):
    """Find Pilgrims Bounty objects near the given coordinates."""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Query gameobjects with names matching Pilgrim's Bounty and within radius
    query = """
    SELECT gameobject.id, gameobject.spawnId, gameobject.guid, gameobject.id, gameobject.position_x, 
           gameobject.position_y, gameobject.position_z, gameobject.rotation0, gameobject.rotation1,
           gameobject.rotation2, gameobject.rotation3, gameobject_template.name 
    FROM gameobject 
    JOIN gameobject_template ON gameobject.id = gameobject_template.entry
    WHERE gameobject_template.name LIKE '%Pilgrim%' OR gameobject_template.name LIKE '%Bounty%'
    AND ((gameobject.position_x - ?) * (gameobject.position_x - ?) + 
         (gameobject.position_y - ?) * (gameobject.position_y - ?)) <= ? * ?
    """
    
    cursor.execute(query, (x, x, y, y, radius, radius))
    results = cursor.fetchall()
    
    conn.close()
    
    return results

def main():
    parser = argparse.ArgumentParser(description='Find Pilgrim\'s Bounty gameobjects')
    parser.add_argument('--db', type=Path, required=True, help='Path to world database')
    parser.add_argument('--x', type=float, required=True, help='X coordinate')
    parser.add_argument('--y', type=float, required=True, help='Y coordinate')
    parser.add_argument('--radius', type=float, default=50.0, help='Search radius')
    
    args = parser.parse_args()
    
    if not args.db.exists():
        print(f"Database file not found: {args.db}")
        return
    
    results = find_pilgrims_bounty_objects(args.db, args.x, args.y, args.radius)
    
    if not results:
        print("No Pilgrim's Bounty objects found near the specified coordinates.")
        return
    
    print("Found Pilgrim's Bounty objects:")
    for row in results:
        print(f"ID: {row[0]}, GUID: {row[2]}, Name: {row[10]}, Position: ({row[4]:.2f}, {row[5]:.2f}, {row[6]:.2f})")
    
    # Save results to JSON for later use
    output_file = Path("pilgrims_bounty_objects.json")
    with open(output_file, 'w') as f:
        json.dump(results, f, indent=2)
    print(f"\nResults saved to {output_file}")

if __name__ == '__main__':
    main()