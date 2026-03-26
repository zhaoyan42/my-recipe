#!/usr/bin/env python3
"""Classify a cooking rescue situation into a deterministic first-pass category.

The classifier intentionally handles only the first layer of reasoning:
identify the dominant failure mode, then let the skill or the rescue guide
expand into specific repair options.
"""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from typing import Iterable


@dataclass(frozen=True)
class Rule:
    category: str
    keywords: tuple[str, ...]
    priority: int
    first_reaction: str
    recommended_direction: str
    taboo: str


RULES: tuple[Rule, ...] = (
    Rule(
        category="burnt_bottom",
        keywords=("锅底黑", "锅底糊", "糊了", "焦", "烧糊", "糊底"),
        priority=100,
        first_reaction="立刻止火",
        recommended_direction="转移未糊部分、掩盖轻微焦味、必要时止损重做",
        taboo="不要刮锅底",
    ),
    Rule(
        category="too_salty",
        keywords=("太咸", "咸了", "盐放多", "过咸"),
        priority=90,
        first_reaction="先判断还能否稀释",
        recommended_direction="物理吸附、味觉对冲、加量稀释",
        taboo="不要继续猛加盐",
    ),
    Rule(
        category="too_spicy",
        keywords=("太辣", "辣爆", "辣过头", "辣了"),
        priority=80,
        first_reaction="先判断有没有乳制品或酸甜材料",
        recommended_direction="乳制品中和、酸甜平衡、加量稀释",
        taboo="不要只靠再加辣",
    ),
    Rule(
        category="too_sweet",
        keywords=("太甜", "甜了", "糖放多"),
        priority=70,
        first_reaction="先看酸度",
        recommended_direction="增加酸味、少量咸味对冲",
        taboo="不要继续加糖",
    ),
    Rule(
        category="thick_clumpy",
        keywords=("太稠", "太厚", "结块", "勾芡过头"),
        priority=60,
        first_reaction="先降粘度",
        recommended_direction="分次加温水或高汤",
        taboo="不要一次加太多水",
    ),
    Rule(
        category="thin_runny",
        keywords=("太稀", "太薄", "没挂住", "勾芡太稀"),
        priority=50,
        first_reaction="先补浓度",
        recommended_direction="重新调水淀粉、回锅增稠",
        taboo="不要干等收干",
    ),
    Rule(
        category="tough_meat",
        keywords=("太老", "太柴", "咬不动", "咬不烂"),
        priority=40,
        first_reaction="先判断还能否继续软化",
        recommended_direction="继续炖煮、加酸性辅助、延长时间",
        taboo="不要过早出锅",
    ),
)


def normalize(text: str) -> str:
    return text.lower().strip()


def score_rule(text: str, rule: Rule) -> int:
    return sum(1 for keyword in rule.keywords if keyword in text)


def classify(text: str) -> dict[str, object]:
    normalized = normalize(text)
    scored: list[tuple[int, int, Rule]] = []
    for rule in RULES:
        matches = score_rule(normalized, rule)
        if matches:
            scored.append((matches, rule.priority, rule))

    if not scored:
        return {
            "category": "unknown",
            "first_reaction": "先冷静判断问题类型",
            "recommended_direction": "让用户补充更具体的症状",
            "taboo": "不要急着给单一路线",
            "matched_keywords": [],
            "confidence": 0.0,
        }

    matches, _, rule = sorted(scored, key=lambda item: (item[0], item[1]), reverse=True)[0]
    confidence = min(0.99, 0.45 + 0.18 * matches)
    return {
        "category": rule.category,
        "first_reaction": rule.first_reaction,
        "recommended_direction": rule.recommended_direction,
        "taboo": rule.taboo,
        "matched_keywords": [keyword for keyword in rule.keywords if keyword in normalized],
        "confidence": round(confidence, 2),
    }


def read_input(argv: Iterable[str]) -> str:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("text", nargs="*", help="Rescue description text")
    args = parser.parse_args(list(argv))

    if args.text:
        return " ".join(args.text)

    data = sys.stdin.read().strip()
    return data


def main() -> int:
    text = read_input(sys.argv[1:])
    if not text:
        print(json.dumps({"error": "no input provided"}, ensure_ascii=False))
        return 1

    result = classify(text)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
