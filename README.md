# memo-charter · AI 协作启动包（开源精简版）

> 让 Claude Code 每次开窗都"认识你"：画像 + 红线，由 SessionStart hook **强制注入**，不靠模型自觉。

## 为什么不是 CLAUDE.md

CLAUDE.md 里写"请先读 rules/xxx.md"是**自愿式路由**，模型经常不照做。
Claude Code 的 `SessionStart` hook 由 harness 强制执行，每次会话开始（startup / clear / compact）都会跑，是唯一 100% 可靠的注入通道。

本仓库给你：

```
memo-charter/
├── distill/
│   ├── one-pager.md     ← 你的画像（模板，5 分钟填完）
│   └── top-rules.md     ← 红线速查 + 按需触发表（每次会话注入）
├── rules/principles/    ← 3 条示例规则：P0 安全 / 显式失败 / 优先级仲裁
├── hooks/session-start.sh
└── docs/安装手册.md      ← 10 分钟接入
```

## 3 步上手

1. clone 到固定位置（例：`~/memo-charter`），填 `distill/one-pager.md`
2. 按 [docs/安装手册.md](docs/安装手册.md) 把 hook 接进 `~/.claude/settings.json`
3. 新开一个 Claude Code 会话，问它"你知道我是谁吗"

## 规则怎么写才有用：写判据，不写清单

「禁止 `--no-verify`」挡不住 `--no-sandbox`；「不用关掉安全机制换跑通」两个都挡住。
破坏性操作不列命令清单，列四问：别处有没有第二份？撤销需要什么？爆炸半径真是你说的范围吗？有没有已经发出去？
详见 [rules/principles/p0-safety.md](rules/principles/p0-safety.md)。

## 完整版

完整版另含 10 条编码 / UI / 原则规则、"记一下"5 段自更新审查协议（防规则膨胀）、
隐私分级导出脚本（public / team / self 自动脱敏）、扩展手册：【爱发电链接】，39 元。

## 许可

本仓库内容 MIT。
