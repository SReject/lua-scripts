# sreject.* Lua-Scripts
A repository containing my release-ready libraries

[array](./src/array) - An array(list) library inspired by JS's array interface (read: methods and call chaining);

[better-errors](./src/better-errors) - A library to create more informative errors

[expect](./src/expect) - A validation library

[LUT](./src/lut) - A unit-test library modelled after JS testing conventions



## Format
All scripts provided here return a table containing their exports.

For scripts that return a singular item, it is keyed by the script's name
eg `require('array').Array`