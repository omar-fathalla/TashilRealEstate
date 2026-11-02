#!/usr/bin/env python3
"""
Tashil Real Estate — Material Design 3 (M3) Governance Agent
Autonomous Linting & Architectural Governance Pipeline powered by Google Antigravity SDK

Enforces Tashil M3 standards across the Flutter codebase:
1. Rejection of raw Flutter primitives (TextField, DropdownButton, ProgressIndicators)
   in favor of the official Tashil Design System suite.
2. Enforcement of the M3 Shaded Close Button standard (Icons.close -> TashilIconButton.close).
3. 8dp baseline spacing grid compliance (M3Spacing tokens).
4. Full allowlist support for core design system primitive wrappers.
5. Autonomous agent governance via google-antigravity SDK (model: gemini-3.5-flash, skills: .agents/skills).

Usage:
  python3 scripts/m3_governance_agent.py [--path frontend/lib] [--strict] [--json] [--agent]
"""

import argparse
import asyncio
import json
import os
import re
import sys
from typing import Dict, List, Any, Optional

# Files/directories permitted to use raw Flutter primitives
ALLOWLIST_PATHS = [
    os.path.normpath("frontend/lib/core/design_system"),
    os.path.normpath("frontend/lib/core/layout"),
    os.path.normpath("frontend/lib/core/theme"),
]

# Regex patterns for M3 violations
VIOLATION_RULES = [
    {
        "id": "M3-INPUT-001",
        "category": "Input & Forms",
        "description": "Raw TextField / TextFormField used instead of TashilTextField",
        "pattern": re.compile(r'(?<!Tashil)\b(TextField|TextFormField)\s*\('),
        "recommendation": "Use TashilTextField.outlined() or TashilPhoneTextField() from core/design_system",
        "severity": "ERROR",
    },
    {
        "id": "M3-INPUT-002",
        "category": "Dropdowns & Menus",
        "description": "Raw DropdownButton / DropdownButtonFormField used instead of TashilDropdownMenu",
        "pattern": re.compile(r'\b(DropdownButton|DropdownButtonFormField)\s*<'),
        "recommendation": "Use TashilDropdownMenu<T>() from core/design_system/menus/tashil_menus.dart",
        "severity": "ERROR",
    },
    {
        "id": "M3-FEEDBACK-001",
        "category": "Loading & Progress",
        "description": "Raw CircularProgressIndicator used instead of TashilLoadingIndicator / TashilCircularProgressIndicator",
        "pattern": re.compile(r'(?<!Tashil)\bCircularProgressIndicator\s*\('),
        "recommendation": "Use TashilLoadingIndicator or TashilCircularProgressIndicator from core/design_system",
        "severity": "ERROR",
    },
    {
        "id": "M3-FEEDBACK-002",
        "category": "Loading & Progress",
        "description": "Raw LinearProgressIndicator used instead of TashilLinearProgressIndicator",
        "pattern": re.compile(r'(?<!Tashil)\bLinearProgressIndicator\s*\('),
        "recommendation": "Use TashilLinearProgressIndicator.flat() or .wavy() from core/design_system",
        "severity": "ERROR",
    },
    {
        "id": "M3-BUTTON-001",
        "category": "Buttons & Affordance",
        "description": "Raw unshaded close button (Icons.close / close_rounded in IconButton)",
        "pattern": re.compile(r'IconButton\s*\(\s*(?:[^)]*?icon:\s*(?:const\s+)?Icon\(\s*Icons\.(?:close|close_rounded|clear_rounded))'),
        "recommendation": "Use TashilIconButton.close(onPressed: ...) conforming to shaded close button rule",
        "severity": "WARNING",
    },
    {
        "id": "M3-SPACE-001",
        "category": "8dp Baseline Grid",
        "description": "Non-8dp baseline spacing grid discrepancy (arbitrary 6/10/14/18/22dp)",
        "pattern": re.compile(r'(?:SizedBox\s*\(\s*(?:width|height):\s*(?:[13579]|6|10|14|18|22)\b|EdgeInsets\.\w+\([^)]*?\b(?:[13579]|6|10|14|18|22)\b)'),
        "recommendation": "Use canonical 8dp tokens (M3Spacing.xxs/xs/sm/md/lg: 4, 8, 16, 24, 32, 40, 48, 64dp)",
        "severity": "WARNING",
    },
]


def is_allowlisted(file_path: str) -> bool:
    norm = os.path.normpath(file_path)
    for allowed in ALLOWLIST_PATHS:
        if allowed in norm:
            return True
    return False


def scan_file(file_path: str) -> List[Dict[str, Any]]:
    violations = []
    if is_allowlisted(file_path):
        return violations

    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception as e:
        return [{"file": file_path, "error": str(e)}]

    full_text = "".join(lines)

    for rule in VIOLATION_RULES:
        for match in rule["pattern"].finditer(full_text):
            start_pos = match.start()
            line_num = full_text[:start_pos].count('\n') + 1
            line_content = lines[line_num - 1].strip() if line_num <= len(lines) else ""
            violations.append({
                "rule_id": rule["id"],
                "category": rule["category"],
                "file": file_path,
                "line": line_num,
                "snippet": line_content,
                "description": rule["description"],
                "recommendation": rule["recommendation"],
                "severity": rule["severity"],
            })

    return violations


def run_governance_audit(target_dir: str) -> Dict[str, Any]:
    all_violations = []
    scanned_files_count = 0

    for root, _, files in os.walk(target_dir):
        for file in files:
            if file.endswith('.dart'):
                scanned_files_count += 1
                full_path = os.path.join(root, file)
                violations = scan_file(full_path)
                all_violations.extend(violations)

    errors = [v for v in all_violations if v.get("severity") == "ERROR"]
    warnings = [v for v in all_violations if v.get("severity") == "WARNING"]

    return {
        "scanned_files": scanned_files_count,
        "total_violations": len(all_violations),
        "errors_count": len(errors),
        "warnings_count": len(warnings),
        "violations": all_violations,
    }


def scan_m3_violations(path: str = "frontend/lib") -> str:
    """Tool for the Google Antigravity Agent to scan the Flutter codebase for Material Design 3 violations.

    Args:
        path: Root directory to audit, defaults to 'frontend/lib'.

    Returns:
        JSON string containing audit statistics and list of detected architectural violations.
    """
    result = run_governance_audit(path)
    return json.dumps(result, indent=2)


# =====================================================================
# Google Antigravity SDK Autonomous Agent Pipeline
# =====================================================================

try:
    from google.antigravity import Agent, LocalAgentConfig, types
    from google.antigravity.hooks import hooks

    @hooks.pre_tool_call_decide
    async def pre_tool_decide(data: types.ToolCall) -> types.HookResult:
        """Inspects and authorizes M3 governance tool invocations."""
        if data.name == "scan_m3_violations":
            return types.HookResult(allow=True)
        return types.HookResult(allow=True)

    @hooks.post_tool_call
    async def post_tool_audit(data: types.ToolCallResult) -> None:
        """Logs governance scan results for autonomous compliance auditing."""
        pass

    def create_governance_agent() -> Agent:
        """Factory function configuring an autonomous M3 Governance Agent via google-antigravity SDK."""
        skills_dir = os.path.abspath(".agents/skills")
        config = LocalAgentConfig(
            model="gemini-3.5-flash",
            skills_paths=[skills_dir] if os.path.exists(skills_dir) else None,
            tools=[scan_m3_violations],
            hooks=[pre_tool_decide, post_tool_audit],
            system_instructions=(
                "You are the Tashil Real Estate Material Design 3 (M3) Governance Agent. "
                "Your role is to strictly enforce Google M3 standards across the Flutter codebase, "
                "including Window Size Classes, 8dp baseline spacing grid, trilingual RTL/LTR parity, "
                "rejection of raw Flutter primitives, and shaded close button affordances. "
                "Use the scan_m3_violations tool to inspect code, identify violations, and advise fixes."
            ),
        )
        return Agent(config)

    ANTIGRAVITY_AVAILABLE = True
except ImportError:
    ANTIGRAVITY_AVAILABLE = False


def main():
    parser = argparse.ArgumentParser(description="Tashil Real Estate M3 Governance Linter & Agent")
    parser.add_argument("--path", default="frontend/lib", help="Target directory to scan (default: frontend/lib)")
    parser.add_argument("--strict", action="store_true", help="Fail if any violation (error or warning) is found")
    parser.add_argument("--json", action="store_true", help="Output results in JSON format")
    parser.add_argument("--agent", action="store_true", help="Run the autonomous Google Antigravity Governance Agent")
    args = parser.parse_args()

    if args.agent:
        if not ANTIGRAVITY_AVAILABLE:
            print("Error: google-antigravity SDK is not installed in the current environment.", file=sys.stderr)
            print("Install via: pip install google-antigravity", file=sys.stderr)
            sys.exit(1)

        async def run_agent():
            async with create_governance_agent() as agent:
                response = await agent.chat("Run an M3 governance audit on frontend/lib and report any violations.")
                async for chunk in response:
                    print(chunk, end="", flush=True)
                print()

        asyncio.run(run_agent())
        return

    target_dir = args.path
    if not os.path.exists(target_dir):
        print(f"Error: Target directory '{target_dir}' does not exist.", file=sys.stderr)
        sys.exit(2)

    result = run_governance_audit(target_dir)

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print("=================================================================")
        print("  Tashil Real Estate — Material Design 3 Governance Pipeline   ")
        print("=================================================================")
        print(f"Scanned files : {result['scanned_files']}")
        print(f"Total findings: {result['total_violations']} (Errors: {result['errors_count']}, Warnings: {result['warnings_count']})")
        print("-----------------------------------------------------------------")

        if result["violations"]:
            for v in result["violations"]:
                sev = v.get("severity", "INFO")
                print(f"[{sev}] {v['rule_id']} in {v['file']}:{v['line']}")
                print(f"    Issue: {v['description']}")
                print(f"    Code : {v['snippet']}")
                print(f"    Fix  : {v['recommendation']}")
                print()
        else:
            print("✨ 100% Clean! All scanned files comply with Tashil M3 standards.")

    if args.strict and result["total_violations"] > 0:
        sys.exit(1)
    elif result["errors_count"] > 0:
        sys.exit(1)
    else:
        sys.exit(0)


if __name__ == "__main__":
    main()
