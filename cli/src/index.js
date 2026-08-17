#!/usr/bin/env node
/**
 * keyframe-tools CLI
 *
 * Offline helpers for .rbxm / .rbxmx animation packs.
 * Studio-side refine/preview lives in the plugin — this CLI is for listing
 * and exporting sequence metadata without opening Studio.
 *
 * Usage:
 *   keyframe-tools list <file.rbxm>
 *   keyframe-tools inspect <file.rbxm> [SequenceName]
 *   keyframe-tools export-json <file.rbxm> [out.json]
 */

import fs from "node:fs";
import path from "node:path";
import { readFile } from "rbx-reader";

function prop(inst, name) {
	if (!inst) return undefined;
	if (inst.Properties && inst.Properties[name] !== undefined) {
		const p = inst.Properties[name];
		return p && p.value !== undefined ? p.value : p;
	}
	if (inst[name] !== undefined) {
		const p = inst[name];
		return p && typeof p === "object" && p.value !== undefined ? p.value : p;
	}
	return undefined;
}

function walk(inst, visit) {
	visit(inst);
	for (const c of inst.Children || []) walk(c, visit);
}

function loadRoot(filePath) {
	const data = readFile(filePath);
	const roots = data.result;
	if (!roots || !roots[0]) {
		throw new Error("No root instance in file");
	}
	return roots[0];
}

function collectSequences(root) {
	const list = [];
	walk(root, (inst) => {
		if (inst.ClassName === "KeyframeSequence") {
			const kfs = (inst.Children || []).filter((c) => c.ClassName === "Keyframe");
			const times = kfs.map((k) => prop(k, "Time") || 0);
			times.sort((a, b) => a - b);
			list.push({
				name: prop(inst, "Name") || inst.Name || "?",
				keys: kfs.length,
				duration: times.length ? times[times.length - 1] : 0,
				loop: prop(inst, "Loop"),
				priority: prop(inst, "Priority"),
				path: instPath(inst),
			});
		}
	});
	list.sort((a, b) => a.name.localeCompare(b.name));
	return list;
}

function instPath(inst) {
	const parts = [];
	let cur = inst;
	while (cur) {
		parts.unshift(prop(cur, "Name") || cur.Name || cur.ClassName);
		cur = cur.Parent && cur.Parent.value ? cur.Parent.value : cur.Parent;
		// rbx-reader Parent may be object
		if (cur && cur.value) cur = cur.value;
		if (parts.length > 32) break;
	}
	return parts.join(".");
}

function findSequence(root, name) {
	let found = null;
	walk(root, (inst) => {
		if (inst.ClassName === "KeyframeSequence" && (prop(inst, "Name") || inst.Name) === name) {
			found = inst;
		}
	});
	return found;
}

function exportSequenceJson(seq) {
	const kfs = (seq.Children || []).filter((c) => c.ClassName === "Keyframe");
	kfs.sort((a, b) => (prop(a, "Time") || 0) - (prop(b, "Time") || 0));

	function collectPoses(poseNode, map = {}) {
		const name = prop(poseNode, "Name") || poseNode.Name;
		const cf = prop(poseNode, "CFrame");
		map[name] = {
			cframe: cf,
			weight: prop(poseNode, "Weight"),
			easingStyle: prop(poseNode, "EasingStyle"),
			easingDirection: prop(poseNode, "EasingDirection"),
		};
		for (const c of poseNode.Children || []) {
			if (c.ClassName === "Pose") collectPoses(c, map);
		}
		return map;
	}

	const frames = kfs.map((kf) => {
		const t = prop(kf, "Time") || 0;
		const poses = {};
		for (const c of kf.Children || []) {
			if (c.ClassName === "Pose") collectPoses(c, poses);
		}
		return { t, poses };
	});

	return {
		name: prop(seq, "Name") || seq.Name,
		loop: prop(seq, "Loop"),
		priority: prop(seq, "Priority"),
		frames,
	};
}

function usage() {
	console.log(`Keyframe Tools CLI

Usage:
  keyframe-tools list <file.rbxm|rbxmx>
  keyframe-tools inspect <file.rbxm> [SequenceName]
  keyframe-tools export-json <file.rbxm> [SequenceName] [out.json]

Examples:
  keyframe-tools list ./movement-animations.rbxm
  keyframe-tools inspect ./movement-animations.rbxm Walk
  keyframe-tools export-json ./pack.rbxm Walk ./walk.json
`);
}

function main(argv) {
	const [cmd, file, arg2, arg3] = argv;
	if (!cmd || cmd === "-h" || cmd === "--help") {
		usage();
		process.exit(0);
	}
	if (!file) {
		usage();
		process.exit(1);
	}
	const abs = path.resolve(file);
	if (!fs.existsSync(abs)) {
		console.error("File not found:", abs);
		process.exit(1);
	}

	if (cmd === "list") {
		const root = loadRoot(abs);
		const seqs = collectSequences(root);
		if (seqs.length === 0) {
			console.log("No KeyframeSequences found.");
			return;
		}
		console.log(`Found ${seqs.length} KeyframeSequence(s) in ${path.basename(abs)}:\n`);
		for (const s of seqs) {
			console.log(
				`  ${s.name.padEnd(24)} keys=${String(s.keys).padStart(3)}  dur=${s.duration.toFixed(3)}s  loop=${s.loop}`
			);
		}
		return;
	}

	if (cmd === "inspect") {
		const root = loadRoot(abs);
		const seqs = collectSequences(root);
		const name = arg2;
		const targets = name ? seqs.filter((s) => s.name === name) : seqs;
		if (targets.length === 0) {
			console.error(name ? `Sequence not found: ${name}` : "No sequences.");
			process.exit(1);
		}
		for (const s of targets) {
			console.log(JSON.stringify(s, null, 2));
		}
		return;
	}

	if (cmd === "export-json") {
		const root = loadRoot(abs);
		const seqName = arg2;
		const outPath = arg3 || (seqName ? `${seqName}.json` : "sequences.json");
		if (!seqName) {
			// export all names only
			const seqs = collectSequences(root);
			fs.writeFileSync(outPath, JSON.stringify(seqs, null, 2));
			console.log("Wrote", outPath);
			return;
		}
		const seq = findSequence(root, seqName);
		if (!seq) {
			console.error("Sequence not found:", seqName);
			process.exit(1);
		}
		const json = exportSequenceJson(seq);
		fs.writeFileSync(outPath, JSON.stringify(json, null, 2));
		console.log(`Wrote ${outPath} (${json.frames.length} frames)`);
		return;
	}

	console.error("Unknown command:", cmd);
	usage();
	process.exit(1);
}

main(process.argv.slice(2));
