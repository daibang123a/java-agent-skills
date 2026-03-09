# Contributing to Java Agent Skills

Thank you for your interest in contributing! This guide will help you get started.

## How to Contribute

### Adding a New Skill

1. **Fork the repository** and create a new branch
2. **Create a skill directory** under `skills/` with a kebab-case name
3. **Write the `SKILL.md`** with proper YAML frontmatter
4. **Add supporting files** (scripts, references, assets) as needed
5. **Update the root `README.md`** with your skill's entry
6. **Submit a pull request**

### Skill Requirements

Every skill must have a `SKILL.md` file with valid YAML frontmatter containing `name` (kebab-case identifier) and `description` (trigger-rich text explaining when to use). Rules should be categorized, prioritized by impact (Critical, High, Medium, Low), and include compilable Java code examples targeting Java 17+.

### Quality Checklist

- [ ] `SKILL.md` has valid YAML frontmatter with `name` and `description`
- [ ] Description includes trigger phrases
- [ ] Rules are categorized and prioritized
- [ ] Code examples compile with `javac` and follow Google Java Style Guide
- [ ] `SKILL.md` is under 500 lines
- [ ] Scripts use `#!/bin/bash`, `set -e`, and output JSON to stdout
- [ ] Framework-specific code targets correct versions (Spring Boot 3.2+, etc.)
- [ ] Java 21+ features are clearly marked

### Script Guidelines

Scripts should use `#!/bin/bash` shebang and `set -e` for fail-fast, write progress to stderr, output JSON to stdout, include cleanup traps, accept project path as the first argument, and work on macOS and Linux.

### Reference Files

Put detailed documentation in `references/`, link from `SKILL.md`, keep each reference focused on one topic, and include runnable code examples.

## Development

### Validating Skills

```bash
# Check SKILL.md frontmatter
for f in skills/*/SKILL.md; do
    head -1 "$f" | grep -q "^---$" || echo "Missing frontmatter: $f"
done

# Shellcheck all scripts
find skills/ -name "*.sh" -exec shellcheck {} \;

# Line count check
for f in skills/*/SKILL.md; do
    lines=$(wc -l < "$f")
    [ "$lines" -gt 500 ] && echo "WARNING: $f has $lines lines"
done
```

## Code of Conduct

Be respectful, constructive, and focused on improving skills for the Java community.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
