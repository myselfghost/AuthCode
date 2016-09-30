local _M = {}
function _M.AuthCode(str, operation,key, expiry)
    local bit = require "bit"
    local operation = operation or "DECODE"
    local key = key or ngx.null
    local expiry = expiry or 0

	
    local md5 = ngx.md5
    local strtoupper = string.upper
    local substr = string.sub
    local strlen= string.len
    local ord = string.byte
    local chr = string.char
    local time = ngx.time
    local base64_encode = ngx.encode_base64
    local base64_decode = ngx.decode_base64
    local str_replace = string.gsub
    local microtime = ngx.now
    local sprintf = string.format
	local tonumber = tonumber

-- lua 的sub 起始点是1， php substr 是0；数组也是如此

    key = md5(key)
    operation=strtoupper(operation)
    local ckey_length = 4 -- 随机密钥长度 取值 0-32
    local keya = md5 ( substr ( key, 1, 16 ) )
    local keyb = md5 ( substr ( key, 17, 32 ) )
    local keyc

    if ckey_length then
        if operation == 'DECODE' then
            keyc = substr ( str, 1, ckey_length )
        else
            keyc = substr ( md5 ( microtime () ), -ckey_length )
			
        end
    else
        keyc = ''
    end

    local cryptkey = keya .. md5 ( keya .. keyc )

    local key_length = strlen ( cryptkey )

    if operation == 'DECODE' then
      str = base64_decode ( substr ( str, ckey_length + 1 ) )

    else
        if expiry and tonumber(expiry) > 0 then
            expiry = tonumber(expiry) + time ()
        else
            expiry = 0
        end
		
        str = sprintf ( '%010d',expiry ) .. substr ( md5 ( str .. keyb ), 1, 16 ) .. str
    end


    local str_length = strlen ( str )
    local result = ""
    --local box = range ( 0, 255 )
    local box = {}
    for index = 0, 255 do
        box[#box+1] = index
    end

    local rndkey = {}
	
    for i = 0, 255,1 do
	
        rndkey [#rndkey+1] = ord ( substr(cryptkey, (i % key_length) + 1 , (i % key_length) + 1) )
    end

    local j = 0
    for i = 0, 255,1 do
        j = (j + box [i+1] + rndkey [i+1]) % 256
        local tmp = box [i+1]
        box [i+1] = box [j+1]
        box [j+1] = tmp
    end
	
    local a,j = 0,0
    for i = 0, (str_length - 1),1 do
        a = (a + 1) % 256
        j = (j + box [a+1]) % 256
        local tmp = box [a+1]
        box [a+1] = box [j+1]
        box [j+1] = tmp
        r = bit.bxor( box [(box [a+1] + box [j+1]) % 256 +1] , ord ( substr(str, i+1,i+1 ) ))
        
        result =  result .. chr ( r )
    end
	
    
    if operation == 'DECODE' then
        if ( tonumber(substr ( result, 1, 10 )) == 0 or tonumber( substr ( result, 1, 10 )) - time () > 0) and substr ( result, 11, 26 ) == substr ( md5 ( substr ( result, 27 ) .. keyb ), 1, 16 ) then
            return substr ( result, 27 )
        else
            return ''
        end
    else
        return keyc .. str_replace ( base64_encode ( result ),'=', '')
		
    end
	
end
return  _M.AuthCode

