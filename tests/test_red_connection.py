"""Conexion RedWork <-> red-system (y cualquier orquestador que lance los flujos).

Lo que estas pruebas protegen, descubierto en una prueba real (2026-11-15):
- /flow-bugfix corrido headless se salto impact-prevalidator y code-explorer: los agentes del
  pipeline no estaban en el registro de subagentes (~/.claude/agents), solo en ~/.claude/redwork.
- /flow-new-project nombraba agentes con numeros equivocados (10-Backend-Development-Agent) y el
  test de integridad no lo veia porque solo miraba nombres en minusculas.
"""

import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

import install  # noqa: E402
from tests.conftest import FRAMEWORK_ROOT  # noqa: E402

AGENTS_DIR = FRAMEWORK_ROOT / "agents"
COMMANDS_DIR = FRAMEWORK_ROOT / "commands"
NUMBERED_REF = re.compile(r"\b(\d{2}b?)-([A-Za-z][A-Za-z0-9]*(?:-[A-Za-z0-9]+)*)")


def _flow(name: str) -> str:
    return (COMMANDS_DIR / f"{name}.md").read_text(encoding="utf-8")


def _agent_stem_for(number: str):
    matches = sorted(p.stem for p in AGENTS_DIR.glob(f"{number}-*.md"))
    return matches[0] if len(matches) == 1 else None


class TestNumberedReferences:
    """Toda referencia NN-nombre en un flujo coincide con el archivo real de ese numero."""

    def test_numbered_references_match_agent_files(self):
        wrong = []
        for flow in COMMANDS_DIR.glob("flow-*.md"):
            for m in NUMBERED_REF.finditer(flow.read_text(encoding="utf-8")):
                number, name = m.group(1), m.group(2).lower()
                name = re.sub(r"-agent$", "", name)
                stem = _agent_stem_for(number)
                if stem is None:
                    continue  # no es un agente (p. ej. un nombre de archivo de outputs)
                if f"{number}-{name}" != stem:
                    wrong.append(f"{flow.name}: '{m.group(0)}' no es {stem}")
        assert not wrong, "Referencias a agentes con nombre equivocado:\n" + "\n".join(wrong)

    def test_detector_catches_a_wrong_number(self):
        """Control positivo: el detector encuentra el error que dejo pasar el test anterior."""
        m = NUMBERED_REF.search("Wave 3b - 10-Backend-Development-Agent (TDD Green)")
        assert m and _agent_stem_for(m.group(1)) == "10-api-specification"


class TestNewProjectSequence:
    """flow-new-project sigue la secuencia oficial (AGENT_SEQUENCE.md / CLAUDE.md)."""

    def test_includes_security_and_design_gates(self):
        flow = _flow("flow-new-project")
        assert "04b-security-by-design" in flow
        assert "05b-technical-design-validator" in flow

    def test_includes_api_contract_before_the_gate(self):
        flow = _flow("flow-new-project")
        gate = flow.index("## Gates")
        for agent in ("10-api-specification", "11-implementation-contract"):
            assert agent in flow[:gate], f"{agent} debe correr antes del gate humano"

    def test_documents_agent_25_as_alternative_entry(self):
        assert "25-development-orchestrator" in _flow("flow-new-project")


class TestAgentRegistry:
    """El instalador registra los agentes del pipeline en el registro de subagentes."""

    def _tree(self, tmp_path):
        src = tmp_path / "src"
        (src / "ambient").mkdir(parents=True)
        (src / "13-backend-test.md").write_text("---\nname: 13-backend-test\n---\nv1\n", encoding="utf-8")
        (src / "impact-prevalidator.md").write_text("---\nname: impact-prevalidator\n---\nv1\n", encoding="utf-8")
        (src / "README.md").write_text("no es un agente", encoding="utf-8")
        (src / "ambient" / "tdd-guide.md").write_text("---\nname: tdd-guide\n---\nv1\n", encoding="utf-8")
        dest = tmp_path / "registry"
        dest.mkdir()
        return src, dest

    def test_registers_pipeline_and_ambient_agents(self, tmp_path):
        src, dest = self._tree(tmp_path)
        registered = install._register_agents(src, dest, previously=[])
        assert sorted(registered) == ["13-backend-test.md", "impact-prevalidator.md", "tdd-guide.md"]
        assert not (dest / "README.md").exists()

    def test_never_clobbers_a_user_copy(self, tmp_path):
        src, dest = self._tree(tmp_path)
        (dest / "tdd-guide.md").write_text("version del usuario", encoding="utf-8")
        registered = install._register_agents(src, dest, previously=[])
        assert "tdd-guide.md" not in registered
        assert (dest / "tdd-guide.md").read_text(encoding="utf-8") == "version del usuario"

    def test_updates_its_own_registered_copy(self, tmp_path):
        src, dest = self._tree(tmp_path)
        install._register_agents(src, dest, previously=[])
        (src / "13-backend-test.md").write_text("---\nname: 13-backend-test\n---\nv2\n", encoding="utf-8")
        registered = install._register_agents(src, dest, previously=["13-backend-test.md"])
        assert "13-backend-test.md" in registered
        assert "v2" in (dest / "13-backend-test.md").read_text(encoding="utf-8")

    def test_unregister_removes_only_unmodified_own_copies(self, tmp_path):
        src, dest = self._tree(tmp_path)
        registered = install._register_agents(src, dest, previously=[])
        (dest / "impact-prevalidator.md").write_text("editado por el usuario", encoding="utf-8")
        removed = install._unregister_agents(src, dest, registered)
        assert sorted(removed) == ["13-backend-test.md", "tdd-guide.md"]
        assert (dest / "impact-prevalidator.md").exists()

    def test_install_registers_into_the_task_registry(self):
        content = (FRAMEWORK_ROOT / "install.py").read_text(encoding="utf-8")
        assert "_register_agents(" in content and "agents_registered" in content


class TestGateScriptsAndDocs:
    def test_flows_fall_back_to_the_global_impact_gate(self):
        for name in ("flow-update", "flow-bugfix", "flow-new-project"):
            assert "$HOME/.claude/redwork/scripts/workflow/validate-impact-analysis.sh" in _flow(name), name

    def test_slice_gate_stays_project_local(self):
        """slice-gate asume la plantilla FastAPI (paquete app, cobertura 100): no hay fallback global."""
        for name in ("flow-update", "flow-bugfix"):
            assert "$HOME/.claude/redwork/scripts/workflow/slice-gate.sh" not in _flow(name), name

    def test_flows_sync_protocol_docs(self):
        for name in ("flow-update", "flow-bugfix"):
            flow = _flow(name)
            assert "**doc-updater**" in flow and "CLAUDE.local.md" in flow, name

    def test_doc_updater_vendored(self):
        assert (AGENTS_DIR / "ambient" / "doc-updater.md").exists()

    def test_smoke_test_keeps_its_script(self):
        smoke = (AGENTS_DIR / "19-smoke-test.md").read_text(encoding="utf-8")
        assert "outputs/smoke/" in smoke


class TestSettingsEncoding:
    """El instalador no debe danar settings.json con caracteres no ASCII (Windows lee cp1252 por defecto).

    Hallazgo real (2026-11-16): `install.py update` convirtio un em dash del autoMode del usuario en
    mojibake al leer settings.json sin encoding y reescribirlo.
    """

    def test_merge_preserves_non_ascii_text(self, tmp_path):
        src = tmp_path / "redwork-settings.json"
        dst = tmp_path / "settings.json"
        src.write_text('{"hooks": {"Stop": [{"command": "bash x.sh"}]}}', encoding="utf-8")
        original = {"autoMode": {"soft_deny": ["Bash(deploy:*) — produccion"]}, "nota": "año"}
        dst.write_text(json.dumps(original, ensure_ascii=False, indent=2), encoding="utf-8")
        install._merge_settings(src, dst)
        merged = json.loads(dst.read_text(encoding="utf-8"))
        assert merged["autoMode"] == original["autoMode"]
        assert merged["nota"] == "año"
        assert merged["hooks"]["Stop"] == [{"command": "bash x.sh"}]

    def test_merge_does_not_duplicate_hooks(self, tmp_path):
        src = tmp_path / "redwork-settings.json"
        dst = tmp_path / "settings.json"
        src.write_text('{"hooks": {"Stop": [{"command": "bash x.sh"}]}}', encoding="utf-8")
        dst.write_text('{"hooks": {"Stop": [{"command": "bash x.sh"}, {"command": "mio"}]}}', encoding="utf-8")
        install._merge_settings(src, dst)
        assert len(json.loads(dst.read_text(encoding="utf-8"))["hooks"]["Stop"]) == 2
