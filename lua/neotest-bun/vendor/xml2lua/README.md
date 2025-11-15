# Vendored Dependency: xml2lua

This directory contains a vendored copy of xml2lua, an XML parser written entirely in Lua.

## Source

- **Repository:** https://github.com/manoelcampos/xml2lua
- **Version:** v1.6-2
- **License:** MIT (see LICENSE file)
- **Author:** Manoel Campos da Silva Filho

## Included Files

- `xml2lua.lua` - Main XML parser module
- `XmlParser.lua` - XML parsing implementation
- `xmlhandler/tree.lua` - Tree handler for converting XML to Lua tables

## Why Vendored?

This dependency is vendored to provide a zero-dependency installation experience for neotest-bun users. Users can install the plugin through their plugin manager without needing to separately install luarocks dependencies.

## Updates

To update this vendored dependency:

1. Clone the upstream repository: `git clone https://github.com/manoelcampos/xml2lua.git`
2. Copy the required files from the desired version/tag
3. Update this README with the new version number
