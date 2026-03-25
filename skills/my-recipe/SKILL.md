---
name: my-recipe
description: "My Recipe 技能树的入口。只用于查看和维护子技能树结构、理解分支分工、或处理技能路由问题；不要把它当作具体烹饪执行技能。"
---

# My Recipe 技能树

这是整个烹饪技能树的入口。它只负责展示分工和边界，而不是直接处理具体烹饪任务。

## 技能树

- `my-recipe-shopping-list`: 起手澄清、食谱构建、冰箱清空建议
- `my-recipe-inventory`: 采购核销、已有物品同步、清单回写
- `my-recipe-equipment`: 模具缩放、器具替代、单位换算
- `my-recipe-multidish`: 多菜统筹、步骤编排、出锅对齐
- `my-recipe-rescue`: 翻车急救、失误补救、火候和口味修正

## 路由原则

- 如果用户是在问具体做菜、清单、缩放、统筹或急救，优先让对应叶子技能处理，不要把这些任务留在入口层。

## 统一约束

- 任何步骤里提到的食材，都必须带数量和单位。
- 清单状态只使用 `[ ]` 和 `[x]`。
- 默认单位遵循 `references/standard_units.md`。
- 需要判断设备或补救时，分别参考 `references/equipment_essentials.md` 和 `references/rescue_guide.md`。
- 输出应尽量短、直接、可执行。

## 何时保留这个入口

- 当你需要先判断用户应该走哪条子技能树时，读这个文件。
- 当你在维护子技能，想确认整体风格和边界时，读这个文件。
- 如果任务已经很明确，直接读对应叶子技能，不必经过入口。
