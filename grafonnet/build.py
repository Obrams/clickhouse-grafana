#!/usr/bin/env python3
"""
Python-based build script for Grafonnet dashboards.
Alternative to build.sh for cross-platform compatibility.
"""

import os
import sys
import json
import subprocess
from pathlib import Path


def compile_jsonnet(input_file, output_file, lib_dirs):
    """Compile jsonnet file to JSON."""
    print(f"Compiling {input_file}...")
    
    # Build jsonnet command
    cmd = ['jsonnet']
    for lib_dir in lib_dirs:
        cmd.extend(['-J', lib_dir])
    cmd.append(input_file)
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        
        # Parse and pretty-print JSON
        dashboard_json = json.loads(result.stdout)
        
        # Write to output file
        with open(output_file, 'w') as f:
            json.dump(dashboard_json, f, indent=2)
        
        print(f"✓ Successfully compiled to {output_file}")
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"✗ Error compiling {input_file}:")
        print(e.stderr)
        return False
    except json.JSONDecodeError as e:
        print(f"✗ Invalid JSON output from jsonnet:")
        print(e)
        return False


def main():
    print("=== Grafonnet Build Script (Python) ===\n")
    
    # Check if jsonnet is installed
    try:
        subprocess.run(['jsonnet', '--version'], capture_output=True, check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("Error: jsonnet not found.")
        print("Installing via pip...")
        try:
            subprocess.run([sys.executable, '-m', 'pip', 'install', 'jsonnet'], check=True)
            print("✓ jsonnet installed successfully\n")
        except subprocess.CalledProcessError:
            print("✗ Failed to install jsonnet")
            return 1
    
    # Setup paths
    script_dir = Path(__file__).parent
    dashboards_dir = script_dir / 'dashboards'
    lib_dir = script_dir / 'lib'
    output_dir = script_dir.parent / 'grafana' / 'dashboards'
    
    # Create output directory
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Compile dashboards
    success = True
    
    # User Sessions dashboard
    input_file = dashboards_dir / 'user_sessions.jsonnet'
    output_file = output_dir / 'user_sessions_grafonnet.json'
    
    if input_file.exists():
        if not compile_jsonnet(str(input_file), str(output_file), [str(lib_dir)]):
            success = False
    else:
        print(f"Warning: {input_file} not found, skipping...")
    
    print()
    if success:
        print("✓ All dashboards compiled successfully!")
        print(f"\nOutput directory: {output_dir}")
        print("\nDashboards will be automatically loaded by Grafana provisioning.")
        print("Restart Grafana to see the changes:")
        print("  docker-compose restart grafana")
        return 0
    else:
        print("✗ Some dashboards failed to compile")
        return 1


if __name__ == '__main__':
    sys.exit(main())

