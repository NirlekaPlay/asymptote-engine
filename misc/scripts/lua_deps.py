#!/usr/bin/env python3
"""
lua_deps.py - Traverse require() calls in Lua/Luau files and output a dependency graph.
Supports Rojo project files (default.project.json) to resolve Roblox service paths.

Usage:
	Made by Claude

	python lua_deps.py <entry_file> [--root <repo_root>] [--rojo <project.json>] [--json] [--dot]

Examples:
	python lua_deps.py src/server/world/level/NewLevel.lua
	python lua_deps.py src/server/world/level/NewLevel.lua --rojo default.project.json --json
	python lua_deps.py src/server/world/level/NewLevel.lua --dot > graph.dot

Notes:
	I highly recommend using the dot format and paste it into https://dreampuf.github.io/GraphvizOnline/
"""

import re
import sys
import json
import argparse
from pathlib import Path

# ──────────────────────────────────────────────────────────────────────────────
# Require patterns
# ──────────────────────────────────────────────────────────────────────────────
REQUIRE_PATTERNS = [
	re.compile(r'''require\s*\(\s*["']([^"']+)["']\s*\)'''),   # require("path") / require('path')
	re.compile(r'''require\s*\(\s*([\w][.\w]*)\s*\)'''),        # require(script.Parent.Foo)
]

EXTENSIONS = [".lua", ".luau", ""]


# ──────────────────────────────────────────────────────────────────────────────
# Rojo project.json parser
# Walks the tree and builds a map:
#   Roblox instance path  →  filesystem path
#   e.g. "ServerScriptService.server" → Path("src/server")
# ──────────────────────────────────────────────────────────────────────────────

def load_rojo_mappings(project_file: Path, repo_root: Path) -> dict[str, Path]:
	"""
	Parse a Rojo default.project.json and return a dict mapping
	Roblox dotted paths → filesystem Path objects.

	e.g. {
		"ServerScriptService":        Path("src/server"),   # if service itself has $path
		"ServerScriptService.server": Path("src/server"),   # named child with $path
		"ReplicatedStorage.shared":   Path("src/shared"),
		...
	}
	"""
	mappings: dict[str, Path] = {}

	try:
		data = json.loads(project_file.read_text(encoding="utf-8"))
	except Exception as e:
		print(f"[warn] Could not parse Rojo project file {project_file}: {e}", file=sys.stderr)
		return mappings

	def walk(node: dict, roblox_path: str):
		if not isinstance(node, dict):
			return

		# If this node has a $path, record the mapping
		fs_path_str = node.get("$path")
		if fs_path_str and roblox_path:
			fs_path = (repo_root / fs_path_str).resolve()
			mappings[roblox_path] = fs_path

		# Recurse into children (skip $ keys)
		for key, child in node.items():
			if key.startswith("$") or not isinstance(child, dict):
				continue
			child_path = f"{roblox_path}.{key}" if roblox_path else key
			walk(child, child_path)

	tree = data.get("tree", {})
	walk(tree, "")

	return mappings


def resolve_roblox_path(module_path: str, mappings: dict[str, Path], current_file: Path) -> Path | None:
	"""
	Try to resolve a dotted Roblox path like:
		ServerScriptService.server.world.entity.Entity
		script.Parent.cell.Cell

	Strategy:
	1. Handle script.* relative paths by anchoring to current_file's location.
	2. For absolute service paths, find the longest matching prefix in mappings,
	   then treat the remainder as a filesystem sub-path.
	"""

	parts = module_path.split(".")

	# ── script.* relative paths ──────────────────────────────────────────────
	if parts[0] == "script":
		base = current_file.parent
		remainder = parts[1:]
		for token in remainder:
			if token == "Parent":
				base = base.parent
			else:
				# Try to find the file from here
				candidate = base / token
				result = _try_extensions(candidate)
				if result:
					return result
				# keep descending into directory
				if candidate.is_dir():
					base = candidate
				else:
					break
		return None

	# ── Absolute Roblox service paths ────────────────────────────────────────
	# Find the longest prefix in mappings
	best_prefix_len = 0
	best_fs_root: Path | None = None

	for roblox_prefix, fs_root in mappings.items():
		prefix_parts = roblox_prefix.split(".")
		n = len(prefix_parts)
		if parts[:n] == prefix_parts and n > best_prefix_len:
			best_prefix_len = n
			best_fs_root = fs_root

	if best_fs_root is None:
		return None

	# Remaining path after the matched prefix
	remainder = parts[best_prefix_len:]

	if not remainder:
		# The path points at a directory — try init files
		return _try_extensions(best_fs_root / "init") or (
			best_fs_root if best_fs_root.is_file() else None
		)

	candidate = best_fs_root.joinpath(*remainder)
	return _try_extensions(candidate)


def _try_extensions(base: Path) -> Path | None:
	"""Try appending .lua / .luau / nothing, also try init files."""
	for ext in EXTENSIONS:
		p = Path(str(base) + ext) if ext else base
		if p.is_file():
			return p.resolve()
	# directory init
	for ext in [".lua", ".luau"]:
		p = base / ("init" + ext)
		if p.is_file():
			return p.resolve()
	return None


# ──────────────────────────────────────────────────────────────────────────────
# Standard filesystem require resolution
# ──────────────────────────────────────────────────────────────────────────────

def find_file(module_path: str, base_dir: Path, root_dir: Path) -> Path | None:
	"""Resolve a plain string require path relative to base_dir and root_dir."""
	slash_path = module_path.replace(".", "/")
	candidates = [
		base_dir / module_path,
		base_dir / slash_path,
		root_dir / module_path,
		root_dir / slash_path,
	]
	for c in candidates:
		result = _try_extensions(c)
		if result:
			return result
	return None


# ──────────────────────────────────────────────────────────────────────────────
# Source parsing
# ──────────────────────────────────────────────────────────────────────────────

def extract_requires(file_path: Path) -> list[str]:
	try:
		source = file_path.read_text(encoding="utf-8", errors="replace")
	except OSError as e:
		print(f"[warn] Cannot read {file_path}: {e}", file=sys.stderr)
		return []

	# Strip single-line comments
	source = re.sub(r'--(?!\[).*', '', source)

	found, seen = [], set()
	for pattern in REQUIRE_PATTERNS:
		for match in pattern.finditer(source):
			token = match.group(1)
			if token not in seen:
				seen.add(token)
				found.append(token)
	return found


# ──────────────────────────────────────────────────────────────────────────────
# Graph builder
# ──────────────────────────────────────────────────────────────────────────────

def build_graph(
	entry: Path,
	root_dir: Path,
	rojo_mappings: dict[str, Path],
	max_depth: int = -1,
	recurse: bool = True,
) -> dict:
	nodes: dict[str, dict] = {}
	edges: list[dict] = []
	visited: set[str] = set()

	def node_id(path: Path) -> str:
		try:
			return str(path.relative_to(root_dir))
		except ValueError:
			return str(path)

	def visit(file: Path, depth: int):
		nid = node_id(file)
		if nid in visited:
			return
		visited.add(nid)
		nodes[nid] = {"id": nid, "label": file.stem, "path": str(file), "external": False}

		if (max_depth >= 0 and depth >= max_depth) or (not recurse and depth > 0):
			return

		base_dir = file.parent
		for req in extract_requires(file):
			# 1. Try standard filesystem resolution first
			resolved = find_file(req, base_dir, root_dir)

			# 2. Fall back to Rojo-aware resolution
			if resolved is None and rojo_mappings:
				resolved = resolve_roblox_path(req, rojo_mappings, file)

			if resolved:
				rid = node_id(resolved)
				edges.append({"from": nid, "to": rid, "label": req})
				visit(resolved, depth + 1)
			else:
				# Truly unresolved — surface as external node
				rid = f"<{req}>"
				if rid not in nodes:
					# Use the last segment as a short label
					short = req.split(".")[-1]
					nodes[rid] = {"id": rid, "label": short, "path": None, "external": True}
				edges.append({"from": nid, "to": rid, "label": req})

	visit(entry.resolve(), 0)
	return {"entry": node_id(entry.resolve()), "nodes": list(nodes.values()), "edges": edges}


# ──────────────────────────────────────────────────────────────────────────────
# DOT output
# ──────────────────────────────────────────────────────────────────────────────

def to_dot(graph: dict) -> str:
	lines = ["digraph lua_deps {", "  rankdir=LR;",
			 '  node [shape=box, style=filled, fontname="Helvetica"];']
	for node in graph["nodes"]:
		nid   = node["id"].replace('"', '\\"')
		label = node["label"].replace('"', '\\"')
		color = ('#90ee90' if node["id"] == graph["entry"]
				 else '#ffd700' if node.get("external") else '#d0e8ff')
		lines.append(f'  "{nid}" [label="{label}", fillcolor="{color}"];')
	for edge in graph["edges"]:
		lines.append(f'  "{edge["from"]}" -> "{edge["to"]}";')
	lines.append("}")
	return "\n".join(lines)


# ──────────────────────────────────────────────────────────────────────────────
# CLI
# ──────────────────────────────────────────────────────────────────────────────

def main():
	parser = argparse.ArgumentParser(
		description="Lua/Luau dependency graph extractor with Rojo support"
	)
	parser.add_argument("entry", help="Entry Lua/Luau file")
	parser.add_argument("--root", default=None,
						help="Repo root for resolving paths (default: cwd)")
	parser.add_argument("--rojo", default=None,
						help="Path to Rojo project JSON (default: auto-detect default.project.json)")
	fmt = parser.add_mutually_exclusive_group()
	fmt.add_argument("--json", dest="fmt", action="store_const", const="json", default="json")
	fmt.add_argument("--dot",  dest="fmt", action="store_const", const="dot")
	parser.add_argument("--depth", type=int, default=-1,
						help="Max traversal depth (-1 = unlimited)")
	parser.add_argument("--no-recurse", action="store_true",
						help="Only parse the entry file")
	args = parser.parse_args()

	entry = Path(args.entry)
	if not entry.is_file():
		print(f"Error: '{entry}' is not a file.", file=sys.stderr)
		sys.exit(1)

	# Repo root: explicit --root, or cwd
	repo_root = Path(args.root).resolve() if args.root else Path.cwd()

	# Auto-detect Rojo project file
	rojo_file: Path | None = None
	if args.rojo:
		rojo_file = Path(args.rojo)
	else:
		# Walk up from entry looking for default.project.json
		candidate = entry.resolve().parent
		while True:
			p = candidate / "default.project.json"
			if p.is_file():
				rojo_file = p
				break
			if candidate == candidate.parent:
				break
			candidate = candidate.parent

	rojo_mappings: dict[str, Path] = {}
	if rojo_file and rojo_file.is_file():
		rojo_mappings = load_rojo_mappings(rojo_file, repo_root)
		print(f"[info] Loaded Rojo mappings from {rojo_file} ({len(rojo_mappings)} paths)",
			  file=sys.stderr)
		for k, v in rojo_mappings.items():
			print(f"  {k} → {v}", file=sys.stderr)
	else:
		print("[info] No Rojo project file found; using filesystem resolution only.",
			  file=sys.stderr)

	graph = build_graph(entry, repo_root, rojo_mappings, args.depth, not args.no_recurse)
	print(to_dot(graph) if args.fmt == "dot" else json.dumps(graph, indent=2))


if __name__ == "__main__":
	main()