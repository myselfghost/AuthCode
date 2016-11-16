# a symmetric encryption function for ngx_lua


It supports setting the expiration time

## Synopsis

local AuthCode = require("AuthCode")

local r = AuthCode("test","ENCODE","AKey",2)

local r = AuthCode(r,"DECODE","AKey")

