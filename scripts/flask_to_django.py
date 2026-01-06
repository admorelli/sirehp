#!/usr/bin/env python3
"""
Best-effort converter: SQLAlchemy models -> Django models skeleton.

Usage:
  python scripts/flask_to_django.py --source kerkoapp/models.py --out kerkoapp_dj/models.py

This script is intentionally conservative: it generates Django model classes
with field names and guessed field types. You must review the output and
fix relationships, options, indexes, and other details manually.
"""
import ast
import argparse
import textwrap

TYPE_MAP = {
    'Integer': 'models.IntegerField',
    'SmallInteger': 'models.SmallIntegerField',
    'BigInteger': 'models.BigIntegerField',
    'String': 'models.CharField',
    'Text': 'models.TextField',
    'Boolean': 'models.BooleanField',
    'DateTime': 'models.DateTimeField',
    'Date': 'models.DateField',
    'Float': 'models.FloatField',
    'Numeric': 'models.DecimalField',
    # SQLAlchemy ForeignKey handled separately
}

def guess_field(node):
    # node is ast.Call representing Column(...)
    # Look at the first arg or keywords to guess type/name
    field_type = 'models.TextField'
    args = node.args
    if args:
        first = args[0]
        if isinstance(first, ast.Call) and isinstance(first.func, ast.Name):
            tname = first.func.id
            field_type = TYPE_MAP.get(tname, field_type)
        elif isinstance(first, ast.Attribute):
            tname = first.attr
            field_type = TYPE_MAP.get(tname, field_type)
    for kw in node.keywords:
        if kw.arg == 'primary_key' and isinstance(kw.value, ast.Constant) and kw.value.value is True:
            return 'models.AutoField(primary_key=True)'
        if kw.arg == 'nullable' and isinstance(kw.value, ast.Constant) and kw.value.value is False:
            # we'll add null=False later if needed
            pass
    # default fallback
    if field_type == 'models.CharField':
        return "models.CharField(max_length=255, blank=True, null=True)"
    return f"{field_type}(blank=True, null=True)"

class ModelVisitor(ast.NodeVisitor):
    def __init__(self):
        self.models = []

    def visit_ClassDef(self, node):
        bases = [b.id if isinstance(b, ast.Name) else None for b in node.bases]
        # naive detection: inherit from Base or db.Model
        if any(b and ('Model' in b or 'Base' in b) for b in bases):
            fields = []
            for stmt in node.body:
                if isinstance(stmt, ast.Assign):
                    if isinstance(stmt.value, ast.Call) and getattr(stmt.value.func, 'id', '') == 'Column':
                        name = stmt.targets[0].id if isinstance(stmt.targets[0], ast.Name) else 'field'
                        field_def = guess_field(stmt.value)
                        fields.append((name, field_def))
            self.models.append((node.name, fields))

def render_models(models):
    out = []
    out.append("from django.db import models\n\n")
    for name, fields in models:
        out.append(f"class {name}(models.Model):")
        if not fields:
            out.append(textwrap.indent("pass\n", '    '))
            continue
        for fname, fdef in fields:
            out.append(textwrap.indent(f"{fname} = {fdef}", '    '))
        out.append("\n    def __str__(self):\n        return f\"<{name} {{self.pk}}>\"")
        out.append("\n\n")
    return "\n".join(out)

def main():
    p = argparse.ArgumentParser()
    p.add_argument('--source', required=True)
    p.add_argument('--out', required=True)
    args = p.parse_args()

    src = open(args.source).read()
    tree = ast.parse(src)
    v = ModelVisitor()
    v.visit(tree)
    models_code = render_models(v.models)
    with open(args.out, 'w') as f:
        f.write(models_code)
    print(f"Generated {args.out} with {len(v.models)} model(s). Review carefully!")

if __name__ == '__main__':
    main()
