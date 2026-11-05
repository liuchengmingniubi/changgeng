#!/usr/bin/env bash
# 长庚·东沙旧事 —— 无头回归测试批量执行器
# 用法: bash tests/run_headless.sh [测试文件名关键字]
#
# 说明:
#  1) 本机安全策略只允许 Godot 进程写入主工程目录树内，写外部路径会段错误。
#     故把 APPDATA 指到主工程的 _userdata/，user:// 才落得下来。
#     worktree（changgeng-chatgpt 等）在工程之外，改用
#     <主工程>/_userdata/<worktree 名>，互不覆盖存档。
#     需要自定义时设 CHANGGENG_USER_DIR。
#  2) 每个用例独立进程运行，超时 180s。判定标准: 输出含 "PASS" 且无 SCRIPT ERROR。

set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

ENGINE="./engine/Godot_v4.3-stable_win64_console.exe"
[ -f "$ENGINE" ] || ENGINE="./engine/Godot_v4.3-stable_win64.exe"
[ -f "$ENGINE" ] || { echo "找不到 Godot 引擎：请在主工程建 engine/ 目录联接，或解压完整包"; exit 1; }

# 主 worktree 就是 `git worktree list` 的第一项
MAIN_ROOT="$(git -C "$ROOT" worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p' | head -1)"
[ -n "$MAIN_ROOT" ] || MAIN_ROOT="$ROOT"
MAIN_ROOT="${MAIN_ROOT//\\//}"

if [ -n "${CHANGGENG_USER_DIR:-}" ]; then
	USER_DIR="$CHANGGENG_USER_DIR"
elif [ "$ROOT" = "$MAIN_ROOT" ]; then
	USER_DIR="$ROOT/_userdata"
else
	USER_DIR="$MAIN_ROOT/_userdata/$(basename "$ROOT")"
fi

export APPDATA="$USER_DIR"
mkdir -p "$USER_DIR" 2>/dev/null
LOGDIR="$ROOT/tests/_logs"
mkdir -p "$LOGDIR"

FILTER="${1:-}"
PASS=0; FAIL=0; FAILED_LIST=()

for f in tests/*.gd; do
	base="$(basename "$f")"
	case "$base" in _*|*.import) continue ;; esac
	[ -n "$FILTER" ] && case "$base" in *"$FILTER"*) ;; *) continue ;; esac

	out=$(timeout 180 "$ENGINE" --headless --path . --script "res://$f" 2>&1)
	code=$?
	echo "$out" > "$LOGDIR/${base%.gd}.log"

	if [ $code -eq 0 ] && echo "$out" | grep -q "PASS" && ! echo "$out" | grep -qE "SCRIPT ERROR|Assertion failed|signal 11"; then
		PASS=$((PASS+1))
		printf "  [OK]   %-28s %s\n" "$base" "$(echo "$out" | grep -m1 'PASS' | cut -c1-90)"
	else
		FAIL=$((FAIL+1))
		FAILED_LIST+=("$base")
		printf "  [FAIL] %-28s exit=%s\n" "$base" "$code"
		echo "$out" | grep -E "SCRIPT ERROR|Assertion failed|Parse Error|signal 11|ERROR" | head -3 | sed 's/^/         /'
	fi
done

echo "---------------------------------------------"
echo "通过 $PASS / 失败 $FAIL"
if [ ${#FAILED_LIST[@]} -gt 0 ]; then
	printf "失败用例: %s\n" "${FAILED_LIST[*]}"
	echo "详细日志: tests/_logs/"
	exit 1
fi
exit 0
