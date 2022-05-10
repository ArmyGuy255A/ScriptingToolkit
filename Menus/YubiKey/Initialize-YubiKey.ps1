cd 'C:\Program Files\Yubico\Yubico PIV Tool\bin'

.$pivTool -a verify-pin -P 32165498
.$pivTool -a verify-pin -P 32165498
.$pivTool -a verify-pin -P 32165498
.$pivTool -a change-puk -P 12345679 -N 32165498
.$pivTool -a change-puk -P 12345679 -N 32165498
.$pivTool -a change-puk -P 12345679 -N 32165498
.$pivTool -a reset
.$pivTool -a set-chuid
.$pivTool -a set-ccc
.$pivTool -a set-mgm-key -n 020203040506070801020304050607080102030405060708
.$pivTool -a change-puk -P 12345678 
.$pivTool -a change-pin -P 123456
