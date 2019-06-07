# DHE Groups
Instead of using pre-configured DH groups, or generating their own with "openssl dhparam", 
operators should use the pre-defined DH groups `ffdhe2048`, `ffdhe3072` or `ffdhe4096` recommended by the IETF
in:

[RFC 7919 https://tools.ietf.org/html/rfc7919]

These groups are audited and may be more resistant to attacks than ones randomly generated.

Note: if you must support old Java clients, Dh groups larger than `1024 bits` may block connectivity (see #DHE_and_Java). 

# References 
Mozilla Security :
[https://wiki.mozilla.org/Security/Server_Side_TLS#DHE_handshake_and_dhparam]
