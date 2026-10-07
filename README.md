# Envora

Envora helps you manage environment variables and add executable directories to your `PATH` without editing shell configuration files manually.

## How to Use

### Environment Variables

Use **Environment Variables** when an application or tool needs a named configuration value.

For example, if you installed a JDK at:

`/home/username/java/jdk-21`

you can add:

| Name        | Value                        |
| ----------- | ---------------------------- |
| `JAVA_HOME` | `/home/username/java/jdk-21` |

Programs can then read the `JAVA_HOME` variable to locate your JDK.

---

### Persistent PATH

Use **Persistent PATH** when you want to run a program from the terminal without typing its full path.

For example, if your JDK contains:

```text
/home/username/java/jdk-21/
└── bin/
    ├── java
    ├── javac
    └── jar
```

Add this directory to **Persistent PATH**:

```text
/home/username/java/jdk-21/bin
```

After the environment is loaded again, you can run:

```bash
javac Main.java
```

instead of:

```bash
/home/username/java/jdk-21/bin/javac Main.java
```

### Example: Java JDK

For a manually installed JDK, you may configure both:

- Environment Variable: `JAVA_HOME=/home/username/java/jdk-21`
- Persistent PATH: `/home/username/java/jdk-21/bin`

This gives you both:

- `JAVA_HOME` → tells applications where the JDK is located.
- `PATH` → allows commands such as `java` and `javac` to be executed directly from the terminal.

---

### Current PATH vs Persistent PATH

- **Current PATH** shows the directories currently available to Envora's environment.
- **Persistent PATH** contains directories that Envora manages and will add to your `PATH` when your environment is loaded.

Persistent PATH is useful for tools installed outside the system's standard directories.

---

### Applying Changes

Changes made in Envora are staged first.

- **Apply** — save the changes to your environment configuration.
- **Discard** — discard changes that have not been applied.

New environment changes may require a new terminal or application session before they become available.
