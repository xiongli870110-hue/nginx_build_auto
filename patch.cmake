target_link_libraries(ttyd
  PRIVATE /opt/libwebsockets/lib/libwebsockets.a
  PRIVATE /opt/libuv/lib/libuv.a
  PRIVATE /opt/json-c/lib/libjson-c.a
  PRIVATE /opt/openssl/lib/libssl.a
  PRIVATE /opt/openssl/lib/libcrypto.a
  PRIVATE /usr/lib/x86_64-linux-gnu/libz.a
  PRIVATE pthread)
