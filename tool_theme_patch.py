from pathlib import Path

ROOT = Path(r"c:\Users\basha\solectricity_app\lib")
IMPORT = "import '../theme/sol_colors.dart';"
IMPORT_NESTED = "import '../../theme/sol_colors.dart';"

FILES = [
    "views/about_screen.dart",
    "views/license_screen.dart",
    "views/installation_screen.dart",
    "views/maintenance_screen.dart",
    "views/load_selection_screen.dart",
    "views/load_summary_screen.dart",
    "views/appliance_input_screen.dart",
    "views/system_parameters_screen.dart",
    "views/system_calculation_summary_screen.dart",
    "views/system_diagram_screen.dart",
    "views/cost_based_solar_screen.dart",
    "views/capacity_based_solar_screen.dart",
    "views/land_based_solar_screen.dart",
    "views/tools_screen.dart",
]

# Ordered replacements: more specific first.
REPLACEMENTS = [
    ("const Color(0xFFF4F6F9)", "context.sol.scaffold"),
    ("const Color(0xFFF3F6F5)", "context.sol.scaffold"),
    ("const Color(0xFFF4F7F6)", "context.sol.scaffold"),
    ("const Color(0xFFF6F8F7)", "context.sol.scaffold"),
    ("const Color(0xFF0F172A)", "context.sol.scaffold"),
    ("const Color(0xFF0A0F1D)", "context.sol.scaffold"),
    ("Color(0xFF0F172A)", "context.sol.scaffold"),
    ("const Color(0xFF1E293B)", "context.sol.card"),
    ("Color(0xFF1E293B)", "context.sol.card"),
    ("const Color(0xFF131D31)", "context.sol.cardAlt"),
    ("const Color(0xFF090E17)", "context.sol.canvasDeep"),
    ("const Color(0xFF1B6A3B)", "context.sol.primary"),
    ("Color(0xFF1B6A3B)", "context.sol.primary"),
    ("AppColors.primaryGreen", "context.sol.primary"),
    ("const Color(0xFF263238)", "context.sol.onSurface"),
    ("Color(0xFF263238)", "context.sol.onSurface"),
    ("const Color(0xFF37474F)", "context.sol.onSurfaceMuted"),
    ("Color(0xFF37474F)", "context.sol.onSurfaceMuted"),
    ("Colors.white70", "context.sol.onSurfaceMuted"),
    ("Colors.white54", "context.sol.onSurfaceFaint"),
    ("Colors.white38", "context.sol.onSurfaceFaint"),
    ("Colors.white12", "context.sol.border"),
    ("Colors.white24", "context.sol.border"),
    ("Colors.white30", "context.sol.border"),
    ("Colors.cyanAccent", "context.sol.accent"),
    ("Colors.greenAccent", "context.sol.accentGreen"),
    ("Colors.amberAccent", "context.sol.accentAmber"),
    ("Colors.tealAccent", "context.sol.accentTeal"),
    ("Colors.purpleAccent", "context.sol.accentPurple"),
    ("Colors.orangeAccent", "context.sol.accentOrange"),
    ("Colors.indigoAccent", "context.sol.accentIndigo"),
    ("fillColor: const Color(0xFFF3F4F6)", "fillColor: context.sol.inputFill"),
    ("const Color(0xFFF3F4F6)", "context.sol.inputFill"),
    ("Colors.grey.shade100", "context.sol.inputFill"),
    ("Colors.grey.shade300", "context.sol.border"),
    ("Colors.grey.shade700", "context.sol.onSurfaceMuted"),
    ("Colors.grey.shade600", "context.sol.onSurfaceFaint"),
    ("const Color(0xFFE8F5E9)", "context.sol.goalCard"),
    ("const Color(0xFF2E7D32)", "context.sol.goalText"),
]


def ensure_import(text: str, path: Path) -> str:
    if "sol_colors.dart" in text:
        return text
    imp = IMPORT_NESTED if "views/widgets" in str(path).replace("\\", "/") else IMPORT
    # insert after last import
    lines = text.splitlines(True)
    last_import = 0
    for i, line in enumerate(lines):
        if line.startswith("import "):
            last_import = i
    lines.insert(last_import + 1, imp + "\n")
    return "".join(lines)


def strip_const_around_sol(text: str) -> str:
    # Remove const before constructors that now use context.sol
    text = text.replace("const TextStyle(", "TextStyle(")
    text = text.replace("const IconThemeData(", "IconThemeData(")
    text = text.replace("const BoxDecoration(", "BoxDecoration(")
    text = text.replace("const BorderSide(", "BorderSide(")
    text = text.replace("const Divider(", "Divider(")
    text = text.replace("const VerticalDivider(", "VerticalDivider(")
    text = text.replace("const Icon(", "Icon(")
    return text


TECH = {
    "cost_based_solar_screen.dart",
    "capacity_based_solar_screen.dart",
    "land_based_solar_screen.dart",
    "tools_screen.dart",
    "system_diagram_screen.dart",
}

CONTENT = {
    "about_screen.dart",
    "license_screen.dart",
    "installation_screen.dart",
    "maintenance_screen.dart",
    "load_selection_screen.dart",
    "load_summary_screen.dart",
    "appliance_input_screen.dart",
    "system_parameters_screen.dart",
    "system_calculation_summary_screen.dart",
}


def patch(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    original = text
    text = ensure_import(text, path)
    for old, new in REPLACEMENTS:
        text = text.replace(old, new)
    name = path.name
    if name in TECH:
        text = text.replace("color: Colors.white", "color: context.sol.onSurface")
        text = text.replace("Colors.white.withValues", "context.sol.onSurface.withValues")
        text = text.replace("Colors.white.withOpacity", "context.sol.onSurface.withOpacity")
        text = text.replace("foregroundColor: Colors.white", "foregroundColor: context.sol.onSurface")
        text = text.replace("unselectedLabelColor: context.sol.onSurfaceMuted", "unselectedLabelColor: context.sol.onSurfaceFaint")
    if name in CONTENT:
        text = text.replace("color: Colors.white,\n        borderRadius", "color: context.sol.card,\n        borderRadius")
        text = text.replace("color: Colors.white,", "color: context.sol.card,")
        # restore app bar / button foreground whites
        text = text.replace("foregroundColor: context.sol.card", "foregroundColor: Colors.white")
        text = text.replace("color: context.sol.card,\n            fontWeight: FontWeight.bold,\n            fontSize: 19", "color: Colors.white,\n            fontWeight: FontWeight.bold,\n            fontSize: 19")
        text = text.replace("icon: Icon(Icons.arrow_back, color: context.sol.card)", "icon: Icon(Icons.arrow_back, color: Colors.white)")
        text = text.replace("color: context.sol.card,\n            fontWeight: FontWeight.bold,\n            fontSize: 18", "color: Colors.white,\n            fontWeight: FontWeight.bold,\n            fontSize: 18")
        text = text.replace("backgroundColor: context.sol.primary", "backgroundColor: context.sol.appBar")
        text = text.replace("foregroundColor: Colors.white", "foregroundColor: context.sol.onAppBar")
    if "context.sol" in text:
        text = strip_const_around_sol(text)
    if text != original:
        path.write_text(text, encoding="utf-8")
        print("patched", path)
    else:
        print("unchanged", path)


for rel in FILES:
    patch(ROOT / rel)
