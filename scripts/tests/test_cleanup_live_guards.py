"""Execute the actual cleanup script against a deterministic GitHub API fake."""
import json
from pathlib import Path
import shutil
import subprocess
import unittest


WORKFLOW = Path(__file__).resolve().parents[2] / ".github/workflows/cleanup-merged-safe-20261027.yml"


@unittest.skipUnless(shutil.which("node"), "Node required for workflow execution tests")
class CleanupLiveGuardTests(unittest.TestCase):
    def run_cleanup(self, scenario):
        yaml = WORKFLOW.read_text()
        script = "\n".join(line[12:] for line in yaml.split("          script: |\n", 1)[1].splitlines())
        harness = r"""
const scenario = JSON.parse(process.argv[1]);
const deleted = [], archived = [];
let pullReads = 0;
const sha = 'a'.repeat(40), mainSha = 'b'.repeat(40);
const context = {repo: {owner: 'ManuEtt', repo: 'Dnd'}, eventName: 'workflow_run',
  payload: {workflow_run: {head_sha: mainSha}}};
const core = {info() {}, warning() {}};
const pulls = async () => ({data: []});
const branches = async () => ({data: []});
const github = {
  paginate: async method => {
    if (method === branches) return [{name: 'feature', protected: false, commit: {sha}}];
    pullReads++;
    if (pullReads > 1 && ['head', 'base'].includes(scenario)) return [{
      base: {ref: scenario === 'base' ? 'feature' : 'main'},
      head: {ref: scenario === 'head' ? 'feature' : 'other', repo: {full_name: 'ManuEtt/Dnd'}}
    }];
    return [];
  },
  rest: {
    pulls: {list: pulls},
    repos: {
      listBranches: branches,
      compareCommits: async () => ({data: {behind_by: scenario === 'diverged' ? 1 : 0, status: 'ahead'}}),
      getBranch: async () => ({data: {protected: scenario === 'protected',
        commit: {sha: scenario === 'moved' ? 'c'.repeat(40) : sha}}})
    },
    git: {
      getRef: async ({ref}) => {
        if (ref.startsWith('tags/')) {
          if (scenario === 'archive-mismatch') return {data: {object: {sha: 'c'.repeat(40)}}};
          throw Object.assign(new Error('missing'), {status: 404});
        }
        return {data: {object: {sha: ref === 'heads/main' ? mainSha : sha}}};
      },
      createRef: async value => { archived.push(value); },
      deleteRef: async value => { deleted.push(value); }
    }
  }
};
const run = new (Object.getPrototypeOf(async function(){}).constructor)(
  'github', 'context', 'core', JSON.parse(process.argv[2]));
run(github, context, core).then(() => console.log(JSON.stringify({deleted, archived})))
  .catch(error => {console.error(error);process.exitCode = 1;});
"""
        completed = subprocess.run(
            ["node", "-e", harness, json.dumps(scenario), json.dumps(script)],
            check=True, text=True, capture_output=True,
        )
        return json.loads(completed.stdout)

    def test_unchanged_integrated_branch_is_archived_before_deletion(self):
        result = self.run_cleanup("valid")
        self.assertEqual(len(result["archived"]), 1)
        self.assertEqual(result["deleted"], [{"owner": "ManuEtt", "repo": "Dnd", "ref": "heads/feature"}])
        self.assertEqual(result["archived"][0]["sha"], "a" * 40)

    def test_new_pr_reference_protection_or_head_change_prevents_deletion(self):
        for scenario in ("head", "base", "protected", "moved", "diverged", "archive-mismatch"):
            with self.subTest(scenario=scenario):
                self.assertEqual(self.run_cleanup(scenario)["deleted"], [])
