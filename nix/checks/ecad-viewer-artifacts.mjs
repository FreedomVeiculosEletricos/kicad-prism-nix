import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";

const manifest = JSON.parse(readFileSync("public/ecad-viewer.manifest.json", "utf8"));
assert.equal(manifest.adapterCommit, "2cfb9725318322bad9971ca0c0df373b87d0f015");
assert.equal(manifest.dirty, false);
assert.equal(manifest.worktreePatchSha256, createHash("sha256").digest("hex"));

for (const filename of ["ecad-viewer.js", "parser.worker.js", "ecad-renderer.js"]) {
    const digest = createHash("sha256").update(readFileSync(`public/${filename}`)).digest("hex");
    assert.equal(manifest.artifacts[filename], `sha256:${digest}`, `${filename} differs from its manifest`);
}

const viewerDigest = manifest.artifacts["ecad-viewer.js"].slice("sha256:".length);
assert.ok(readFileSync("index.html", "utf8").includes(`/ecad-viewer.js?v=${viewerDigest}`));
assert.ok(readFileSync("dist/index.html", "utf8").includes(`/ecad-viewer.js?v=${viewerDigest}`));
for (const filename of ["ecad-viewer.js", "ecad-viewer.manifest.json", "parser.worker.js", "ecad-renderer.js"]) {
    assert.deepEqual(readFileSync(`dist/${filename}`), readFileSync(`public/${filename}`));
}
console.log("Verified viewer backport provenance, asset hashes, cache key and built artifacts.");
