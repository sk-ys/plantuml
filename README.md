# PlantUML Redmine plugin

This plugin will allow adding [PlantUML](http://plantuml.sourceforge.net/) diagrams into Redmine.

## Requirements

- Java
- PlantUML binary or HTTP Server

## Installation

- STEP1: preparing PlantUML service using a binary or HTTP server
- STEP2: copy this plugin into the Redmine plugins directory

### Installation for binary
- create a shell script in `/usr/bin/plantuml`

```
#!/bin/bash
/usr/bin/java -Djava.io.tmpdir=/var/tmp -Djava.awt.headless=true -jar /PATH_TO_YOUR_plantuml_path/plantuml.jar ${@}
```

## Usage

- go to the plugin settings page (example: http://localhost:3000/settings/plugin/plantuml) and add the *PlantUML binary / URL* path as follow:
    - `/usr/bin/plantuml`
    - `http://www.plantuml.com/plantuml/`
- PlantUML diagrams can be added as follow:

```
{{plantuml(png)
  Bob -> Alice : hello
}}
```

```
{{plantuml(svg)
  Bob -> Alice : hello
}}
```

- you can choose between PNG or SVG images by setting the `plantuml` macro argument to either `png` or `svg`

## using !include params (only binary mode)

Since all files are written out to the system, there is no safe way to prevent editors from using the `!include` command inside the code block.
Therefore every input will be sanitited before writing out the .pu files for further interpretation. You can overcome this by activating the `Setting.plugin_plantuml['allow_includes']`
**Attention**: this is dangerous, since all files will become accessible on the host system.

## Known issues

- PlantUML diagrams are not rendered inside a PDF export, see https://github.com/dkd/plantuml/issues/1

## TODO

- add image caching
