# AGENTS.md

This file provides guidance to AI coding agents (Claude Code, Cursor, Copilot, etc.) when working with code in this repository.

## Repository Overview

A collection of skills for AI coding agents working with **Java** and its ecosystem — Spring Boot, Jakarta EE, Hibernate, Reactive, Microservices, and more. Skills are packaged instructions and scripts that extend agent capabilities.

## Project Structure

```
skills/
  {skill-name}/               # kebab-case directory name
    SKILL.md                   # Required: skill definition
    scripts/                   # Optional: executable scripts
      {script-name}.sh         # Bash scripts (preferred)
    references/                # Optional: detailed reference docs
      {topic}.md               # Markdown reference files
    assets/                    # Optional: templates, examples
```

## Naming Conventions

- **Skill directory**: kebab-case (e.g., `spring-boot-guidelines`, `jpa-hibernate-patterns`)
- **SKILL.md**: Always uppercase, always this exact filename
- **Scripts**: kebab-case.sh (e.g., `dependency-check.sh`, `generate-pom.sh`)
- **References**: kebab-case.md (e.g., `entity-mapping.md`, `circuit-breaker-guide.md`)

## SKILL.md Format

```yaml
---
name: {skill-name}
description: >
  {One sentence describing when to use this skill.
  Include trigger phrases like "Review my Spring Boot app",
  "Optimize JPA queries", etc.}
---

# {Skill Title}

{Brief description of what the skill does.}

## How It Works
{N-step explanation of the skill workflow}

## Rules
{Categorized rules, prioritized by impact}
```

## Guidelines for Modifications

### Adding a New Skill

1. Create a new directory under `skills/` with a kebab-case name
2. Add a `SKILL.md` with valid YAML frontmatter (`name` and `description` required)
3. Keep `SKILL.md` under **500 lines** — put detailed reference material in `references/`
4. Write specific descriptions — helps the agent know exactly when to activate
5. Use progressive disclosure — reference supporting files read only when needed
6. Add scripts for repeatable automation tasks

### Script Requirements

- Use `#!/bin/bash` shebang
- Use `set -e` for fail-fast behavior
- Write status messages to stderr: `echo "Message" >&2`
- Write machine-readable output (JSON) to stdout
- Include a cleanup trap for temp files
- Reference script paths as: `skills/{skill-name}/scripts/{script}.sh`

### Context Budget

To minimize context usage:
- **Keep SKILL.md under 500 lines**
- **Write specific descriptions** — helps the agent know exactly when to activate
- **Use progressive disclosure** — reference supporting files read only when needed
- **Prefer scripts over inline code** — script execution doesn't consume context
- **File references work one level deep** — link directly from SKILL.md to supporting files

## Java-Specific Standards

- Target **Java 17+** (LTS) as baseline; mark Java 21+ features clearly
- Target **Spring Boot 3.2+** and **Spring Framework 6.1+**
- Use **JUnit 5** for all test examples
- Use **Maven** or **Gradle (Kotlin DSL)** for build examples
- Follow Google Java Style Guide conventions
- All code examples must compile with `javac` and pass `spotbugs`
- Prefer standard library over third-party when functionality is equivalent
