# sreject.* Lua-Scripts
A repository containing my release-ready libraries

[array.lua](./src/array) - An array(list) library inspired by JS's array interface (read: methods and call chaining);

[Lua Unit Tests](./src/lut) - A unit-test library modelled after JS testing conventions

## Format
All scripts provided here return a table containing their exports.

For scripts that return a singular item, it is keyed by the script's name
eg `require('array').Array`