"""El frontmatter de cada agente es YAML valido.

Claude Code ignora en silencio un agente cuyo frontmatter no parsea, y su correccion
automatica (citar el valor) no funciona en archivos con CRLF. Un `description` sin
comillas que contiene ": " deja al agente fuera del registro y los flujos que lo
nombran corren incompletos.
"""
import re

import pytest
import yaml

from tests.conftest import FRAMEWORK_ROOT

FRONTMATTER = re.compile(r"\A---\r?\n(.*?)\r?\n---(\r?\n|\Z)", re.S)
AGENT_FILES = sorted(
    p for p in (FRAMEWORK_ROOT / "agents").rglob("*.md") if p.name != "README.md"
)


def parse_frontmatter(text):
    match = FRONTMATTER.match(text)
    assert match, "sin frontmatter"
    return yaml.safe_load(match.group(1))


@pytest.mark.parametrize("path", AGENT_FILES, ids=lambda p: str(p.relative_to(FRAMEWORK_ROOT)))
def test_frontmatter_is_valid_yaml(path):
    data = parse_frontmatter(path.read_text(encoding="utf-8"))
    assert isinstance(data, dict)
    assert data.get("name"), "falta name"
    assert isinstance(data.get("description"), str) and data["description"], "falta description"


@pytest.mark.parametrize("path", AGENT_FILES, ids=lambda p: str(p.relative_to(FRAMEWORK_ROOT)))
def test_frontmatter_is_valid_yaml_with_crlf(path):
    """Asi queda el archivo en Windows cuando git o un editor lo convierte."""
    text = path.read_text(encoding="utf-8").replace("\r\n", "\n").replace("\n", "\r\n")
    data = parse_frontmatter(text)
    assert isinstance(data, dict) and data.get("name")


def test_detector_rejects_unquoted_colon():
    """Control positivo: el mismo parser rechaza el caso que dejo a Red fuera del registro."""
    with pytest.raises(yaml.YAMLError):
        parse_frontmatter("---\nname: x\ndescription: Es el agente: el que falla\n---\n")
