#!/usr/bin/env bash
# ====================================================================
# hooks/session-start.sh · AI 协作启动包 · 会话启动注入器
# ====================================================================
# 为什么存在：CLAUDE.md 只是"自愿式路由"——指望模型自己去读规则文件，
# 新开窗口经常不照做。SessionStart hook 由 Claude Code 强制执行，
# 不依赖模型自觉，是唯一 100% 可靠的注入通道。
#
# 每次会话开始（startup | clear | compact）把两份文件直接注入上下文：
#   - distill/one-pager.md   你的画像（你是谁、怎么协作最舒服）
#   - distill/top-rules.md   规则速查 + 按需触发表（命中才读 rules/ 细则）
#
# 跨机器：包根目录从脚本自身位置推导，不写死任何路径。
# 容错：任一源文件缺失不中断，改注入"降级提示"，绝不静默为空
#      （空输出会被判成 hook 成功，正是最贵的那种失败）。
# ====================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

emit_degraded() {
  cat <<JSON
{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"<memo-charter-context>\n⚠️ 注入降级：$1。请手动读 ${PACK_ROOT}/distill/one-pager.md 与 distill/top-rules.md 后再开始工作。\n</memo-charter-context>"}}
JSON
}

# macOS / Linux 通常是 python3；Windows(Git Bash) 多半只有 python 或 py。
PY_BIN=""
for c in python3 python py; do
  if command -v "$c" >/dev/null 2>&1; then PY_BIN="$c"; break; fi
done
if [ -z "$PY_BIN" ]; then
  emit_degraded "本机找不到 Python 解释器（已试 python3 / python / py）"
  exit 0
fi

# 中文 Windows 上 Python stdout 默认 GBK，emoji 会抛 UnicodeEncodeError 导致整个注入为空
OUT="$(PYTHONIOENCODING=utf-8 "$PY_BIN" - "$PACK_ROOT" <<'PY'
import json, os, re, sys

root = sys.argv[1]

def read(rel):
    try:
        with open(os.path.join(root, rel), encoding="utf-8") as f:
            return f.read()
    except OSError:
        return None

def strip_meta(text):
    # frontmatter 与 HTML 注释是给维护者看的，注入只花 token 不产出
    text = re.sub(r"\A---\n.*?\n---\n", "", text, flags=re.S)
    text = re.sub(r"<!--.*?-->\n?", "", text, flags=re.S)
    return text.strip()

missing, parts = [], []
for rel, title in (("distill/one-pager.md", "用户画像"), ("distill/top-rules.md", "规则速查 + 按需触发表")):
    t = read(rel)
    if t:
        parts.append(f"## {title}（源：{rel}）\n\n" + strip_meta(t))
    else:
        missing.append(rel)

parts.append(f"""## 指针层（命中才读，不预读）
- 用户说"记一下 / 记住 / 存进规则" → 先读 {root}/distill/self-update-protocol.md，走 5 段审查，草稿写到 .staging/，不直接改 rules/
- 上文触发表里的相对路径都基于 {root}/rules/
- 回复语言：中文；代码、命令、技术术语保留英文""")

if missing:
    parts.append("⚠️ 注入降级：以下文件读取失败，请手动补读：" + "、".join(missing))

ctx = f"""<memo-charter-context>
以下是 AI 协作启动包（{root}）经 SessionStart hook 自动注入的内容。
- 启动必读已含于此，不必再读其他入口文件（除非下方声明降级）。
- rules/ 细则按"按需触发表"命中即读，不预读。

""" + "\n\n---\n\n".join(parts) + "\n</memo-charter-context>"
print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": ctx}}, ensure_ascii=False))
PY
)"

if [ -n "$OUT" ]; then
  printf '%s\n' "$OUT"
else
  emit_degraded "解释器 $PY_BIN 执行失败或无输出"
fi
exit 0
