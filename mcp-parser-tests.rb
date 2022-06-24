require('./mcp-parser.rb')

TESTS = [
  "\x00\x00\x00\x14\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0b\x67\x00\x0d\x00\x00\x00\x0c\x0c\x17\x00\x0d\x00\x00\x00\x02\x00\x00\x00\x00",
  "\x00\x00\x00\x44\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0b\x68\x00\x0d\x00\x00\x00\x3c\x0c\x17\x00\x0d\x00\x00\x00\x32\x0c\x18\x00\x05\x00\x00\x00\x05\x19\xeb\x00\x05\x00\x00\x00\x0a\x77\xce\x00\x05\x00\x00\x00\x01\x77\xcf\x00\x05\x00\x00\x00\x00\x78\x8c\x00\x05\x00\x00\x00\x00\x7b\x76\x00\x05\x00\x00\x00\x01\x00\x00\x00\x00",
  "\x00\x00\x00\x14\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0b\x65\x00\x0d\x00\x00\x00\x0c\x02\xa7\x00\x0d\x00\x00\x00\x02\x00\x00\x00\x00",
  "\x00\x00\x02\xb3\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x09\x00\x0d\x00\x00\x00\x1c\x10\x0a\x00\x0e\x00\x00\x00\x12\x00\x0f\x00\x00\x00\x01\x00\x00\x00\x08\x00\x06\x5b\x4e\x6f\x6e\x65\x5d\x00\x00\x0b\x68\x00\x0d\x00\x00\x02\x87\x02\xa7\x00\x0d\x00\x00\x02\x7d\x02\xa8\x00\x0f\x00\x00\x00\x06\x00\x04\x5a\x31\x30\x30\x50\xe0\x00\x05\x00\x00\x00\x2d\x76\x8d\x00\x05\x00\x00\x00\x00\x74\xd6\x00\x05\x00\x00\x00\x00\x74\xd5\x00\x05\x00\x00\x00\x00\x74\xd4\x00\x05\x00\x00\x00\x00\x1b\x58\x00\x03\x00\x00\x1b\x57\x00\x03\x00\x00\x81\x18\x00\x0f\x00\x00\x00\x02\x00\x00\x81\x17\x00\x0f\x00\x00\x00\x19\x00\x17\x56\x4d\x77\x61\x72\x65\x20\x56\x69\x72\x74\x75\x61\x6c\x20\x50\x6c\x61\x74\x66\x6f\x72\x6d\x12\x00\x00\x0f\x00\x00\x00\x02\x00\x00\x0d\x69\x00\x0f\x00\x00\x00\x02\x00\x00\x61\xa9\x00\x05\x00\x00\x00\x00\x18\x23\x00\x05\x00\x00\x00\x00\x23\xc6\x00\x05\x00\x00\x00\x00\x23\xc5\x00\x05\x00\x00\x00\x00\x96\x83\x00\x05\x00\x00\x00\x00\x76\x59\x00\x05\x00\x00\x00\x00\x96\x82\x00\x05\x00\x00\x00\x00\x81\x16\x00\x05\x00\x00\x00\x01\x81\x15\x00\x05\x00\x00\x00\x01\x6d\x68\x00\x05\x00\x00\x00\x00\x6d\x54\x00\x05\x00\x00\x00\x00\x6d\x53\x00\x05\x00\x00\x00\x00\x61\xa8\x00\x05\x00\x00\x00\x00\x74\xd3\x00\x05\x00\x00\x00\x00\x5a\x1e\x00\x05\x00\x00\x00\x00\x91\xc6\x00\x05\x00\x00\x00\x00\x4b\xdc\x00\x05\x00\x00\x00\x01\x3a\xb3\x00\x05\x00\x00\x00\x00\x76\xba\x00\x05\x00\x00\x00\x00\x76\xb9\x00\x05\x00\x00\x00\x00\x0d\x68\x00\x05\x00\x00\x00\x00\xa2\x01\x00\x05\x00\x00\x00\x00\x6d\xc8\x00\x05\x00\x00\x00\x00\x6d\xc7\x00\x05\x00\x00\x00\x00\x56\xec\x00\x05\x00\x00\x00\x00\x17\xe4\x00\x05\x00\x00\x00\x00\x0f\x36\x00\x05\x00\x00\x00\x00\x0f\x2b\x00\x05\x00\x00\x00\x00\x02\xb0\x00\x05\x00\x00\x00\x00\x0f\x17\x00\x05\x00\x00\x00\x00\x0f\x16\x00\x05\x00\x00\x00\x00\x61\xa7\x00\x05\x00\x00\x00\x00\x56\xeb\x00\x05\x00\x00\x00\x08\x0c\x32\x00\x05\x00\x00\x00\x00\x0c\x31\x00\x05\x00\x00\x01\x00\x02\xaf\x00\x05\x00\x00\x00\x01\x76\x58\x00\x03\x06\x68\x36\x13\x00\x05\x00\x00\x00\x08\x23\xc2\x00\x05\x00\x00\x00\x01\x02\xae\x00\x05\x00\x00\x00\x20\x4b\xdb\x00\x05\x00\x00\x00\x01\x11\xe0\x00\x05\x00\x00\x00\x01\x02\xad\x00\x05\x00\x00\x0f\xfe\x34\x30\x00\x03\x00\x00\x02\xac\x00\x03\x00\x03\x02\xab\x00\x03\x00\x01\x28\xe4\x00\x05\x00\x00\x00\x01\x14\x76\x00\x06\x00\x00\x00\x00\x00\x00\x1c\x00\x02\xaa\x00\x09\x00\x0c\x29\x00\xb6\xb7\x11\xe8\x00\x0f\x00\x00\x00\x02\x00\x00\x13\xbb\x00\x0f\x00\x00\x00\x02\x00\x00\x23\xc1\x00\x03\x00\x00\x3d\x6e\x00\x03\x00\x00\x11\xc8\x00\x03\x00\x00\x02\xa9\x00\x05\xc0\x00\x00\x71\x13\x1f\x00\x0f\x00\x00\x00\x18\x00\x16\x42\x49\x47\x2d\x49\x50\x20\x56\x69\x72\x74\x75\x61\x6c\x20\x45\x64\x69\x74\x69\x6f\x6e\x02\xb3\x00\x05\x00\x00\x34\x5d\x0f\x7c\x00\x0e\x00\x00\x00\x16\x00\x05\x00\x00\x00\x04\x00\x00\x25\x80\x00\x00\x4b\x00\x00\x00\xe1\x00\x00\x01\xc2\x00\x00\x00\x00\x00",
  "\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0b\x65\x00\x0d\x00\x00\x00\x38\x08\x4a\x00\x0d\x00\x00\x00\x2e\x08\x4b\x00\x0f\x00\x00\x00\x24\x00\x22\x70\x6c\x61\x74\x66\x6f\x72\x6d\x2e\x63\x70\x75\x2e\x74\x65\x6d\x70\x65\x72\x61\x74\x75\x72\x65\x2e\x74\x68\x72\x65\x73\x68\x6f\x6c\x64\x00\x00\x00\x00",
  "\x00\x00\x01\x19\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x09\x00\x0d\x00\x00\x00\x1c\x10\x0a\x00\x0e\x00\x00\x00\x12\x00\x0f\x00\x00\x00\x01\x00\x00\x00\x08\x00\x06\x5b\x4e\x6f\x6e\x65\x5d\x00\x00\x0b\x68\x00\x0d\x00\x00\x00\xed\x08\x4a\x00\x0d\x00\x00\x00\xe3\x08\x4b\x00\x0f\x00\x00\x00\x24\x00\x22\x70\x6c\x61\x74\x66\x6f\x72\x6d\x2e\x63\x70\x75\x2e\x74\x65\x6d\x70\x65\x72\x61\x74\x75\x72\x65\x2e\x74\x68\x72\x65\x73\x68\x6f\x6c\x64\x11\x8f\x00\x05\x00\x00\x00\x27\x28\x74\x00\x0f\x00\x00\x00\x07\x00\x05\x66\x61\x6c\x73\x65\x08\x52\x00\x0f\x00\x00\x00\x07\x00\x05\x36\x35\x35\x33\x35\x08\x51\x00\x0f\x00\x00\x00\x03\x00\x01\x30\x08\x50\x00\x0f\x00\x00\x00\x09\x00\x07\x49\x6e\x74\x65\x67\x65\x72\x08\x4f\x00\x0f\x00\x00\x00\x12\x00\x10\x70\x72\x69\x76\x61\x74\x65\x5f\x69\x6e\x74\x65\x72\x6e\x61\x6c\x08\x4e\x00\x0f\x00\x00\x00\x03\x00\x01\x30\x08\x4d\x00\x0f\x00\x00\x00\x04\x00\x02\x37\x35\x08\x4c\x00\x0f\x00\x00\x00\x24\x00\x22\x70\x6c\x61\x74\x66\x6f\x72\x6d\x2e\x63\x70\x75\x2e\x74\x65\x6d\x70\x65\x72\x61\x74\x75\x72\x65\x2e\x74\x68\x72\x65\x73\x68\x6f\x6c\x64\x08\x56\x00\x05\x00\x00\x30\x3c\x08\x53\x00\x0e\x00\x00\x00\x06\x00\x0f\x00\x00\x00\x00\x00\x00\x00\x00",
  "\x00\x00\x00\x3d\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0b\x65\x00\x0d\x00\x00\x00\x35\x08\x4a\x00\x0d\x00\x00\x00\x2b\x08\x4b\x00\x0f\x00\x00\x00\x21\x00\x1f\x70\x6c\x61\x74\x66\x6f\x72\x6d\x2e\x63\x70\x75\x2e\x66\x61\x6e\x73\x70\x65\x65\x64\x2e\x74\x68\x72\x65\x73\x68\x6f\x6c\x64\x00\x00\x00\x00",
  "\x00\x00\x01\x15\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x09\x00\x0d\x00\x00\x00\x1c\x10\x0a\x00\x0e\x00\x00\x00\x12\x00\x0f\x00\x00\x00\x01\x00\x00\x00\x08\x00\x06\x5b\x4e\x6f\x6e\x65\x5d\x00\x00\x0b\x68\x00\x0d\x00\x00\x00\xe9\x08\x4a\x00\x0d\x00\x00\x00\xdf\x08\x4b\x00\x0f\x00\x00\x00\x21\x00\x1f\x70\x6c\x61\x74\x66\x6f\x72\x6d\x2e\x63\x70\x75\x2e\x66\x61\x6e\x73\x70\x65\x65\x64\x2e\x74\x68\x72\x65\x73\x68\x6f\x6c\x64\x11\x8f\x00\x05\x00\x00\x00\x28\x28\x74\x00\x0f\x00\x00\x00\x07\x00\x05\x66\x61\x6c\x73\x65\x08\x52\x00\x0f\x00\x00\x00\x07\x00\x05\x36\x35\x35\x33\x35\x08\x51\x00\x0f\x00\x00\x00\x03\x00\x01\x30\x08\x50\x00\x0f\x00\x00\x00\x09\x00\x07\x49\x6e\x74\x65\x67\x65\x72\x08\x4f\x00\x0f\x00\x00\x00\x12\x00\x10\x70\x72\x69\x76\x61\x74\x65\x5f\x69\x6e\x74\x65\x72\x6e\x61\x6c\x08\x4e\x00\x0f\x00\x00\x00\x03\x00\x01\x30\x08\x4d\x00\x0f\x00\x00\x00\x06\x00\x04\x33\x30\x30\x30\x08\x4c\x00\x0f\x00\x00\x00\x21\x00\x1f\x70\x6c\x61\x74\x66\x6f\x72\x6d\x2e\x63\x70\x75\x2e\x66\x61\x6e\x73\x70\x65\x65\x64\x2e\x74\x68\x72\x65\x73\x68\x6f\x6c\x64\x08\x56\x00\x05\x00\x00\x30\x3b\x08\x53\x00\x0e\x00\x00\x00\x06\x00\x0f\x00\x00\x00\x00\x00\x00\x00\x00",
  "\x00\x00\x00\x14\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0b\x67\x00\x0d\x00\x00\x00\x0c\x0b\x21\x00\x0d\x00\x00\x00\x02\x00\x00\x00\x00",
  "\x00\x00\x00\x0a\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0b\x68\x00\x0d\x00\x00\x00\x02\x00\x00",
  "\x00\x00\x00\x14\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0b\x67\x00\x0d\x00\x00\x00\x0c\x0b\x25\x00\x0d\x00\x00\x00\x02\x00\x00\x00\x00",
  "\x00\x00\x00\x0a\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0b\x68\x00\x0d\x00\x00\x00\x02\x00\x00",
  "\x00\x00\x00\x14\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0b\x67\x00\x0d\x00\x00\x00\x0c\x13\xab\x00\x0d\x00\x00\x00\x02\x00\x00\x00\x00",
  "\x00\x00\x00\x0a\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0b\x68\x00\x0d\x00\x00\x00\x02\x00\x00",
  "\x00\x00\x00\x14\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0b\x67\x00\x0d\x00\x00\x00\x0c\x0b\x28\x00\x0d\x00\x00\x00\x02\x00\x00\x00\x00",
  "\x00\x00\x00\x0a\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0b\x68\x00\x0d\x00\x00\x00\x02\x00\x00",
  "\x00\x00\x00\x14\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0b\x67\x00\x0d\x00\x00\x00\x0c\x0b\x2b\x00\x0d\x00\x00\x00\x02\x00\x00\x00\x00",
  "\x00\x00\x00\x0a\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0b\x68\x00\x0d\x00\x00\x00\x02\x00\x00",
  "\x00\x00\x00\x30\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0b\x65\x00\x0d\x00\x00\x00\x28\x08\x4a\x00\x0d\x00\x00\x00\x1e\x08\x4b\x00\x0f\x00\x00\x00\x14\x00\x12\x70\x72\x6f\x76\x69\x73\x69\x6f\x6e\x2e\x63\x70\x75\x2e\x76\x63\x6d\x70\x00\x00\x00\x00",
  "\x00\x00\x00\xf2\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x09\x00\x0d\x00\x00\x00\x1c\x10\x0a\x00\x0e\x00\x00\x00\x12\x00\x0f\x00\x00\x00\x01\x00\x00\x00\x08\x00\x06\x5b\x4e\x6f\x6e\x65\x5d\x00\x00\x0b\x68\x00\x0d\x00\x00\x00\xc6\x08\x4a\x00\x0d\x00\x00\x00\xbc\x08\x4b\x00\x0f\x00\x00\x00\x14\x00\x12\x70\x72\x6f\x76\x69\x73\x69\x6f\x6e\x2e\x63\x70\x75\x2e\x76\x63\x6d\x70\x11\x8f\x00\x05\x00\x00\x00\x01\x28\x74\x00\x0f\x00\x00\x00\x07\x00\x05\x66\x61\x6c\x73\x65\x08\x52\x00\x0f\x00\x00\x00\x05\x00\x03\x31\x30\x30\x08\x51\x00\x0f\x00\x00\x00\x03\x00\x01\x30\x08\x50\x00\x0f\x00\x00\x00\x09\x00\x07\x69\x6e\x74\x65\x67\x65\x72\x08\x4f\x00\x0f\x00\x00\x00\x0f\x00\x0d\x70\x72\x69\x76\x61\x74\x65\x5f\x6c\x6f\x63\x61\x6c\x08\x4e\x00\x0f\x00\x00\x00\x03\x00\x01\x30\x08\x4d\x00\x0f\x00\x00\x00\x02\x00\x00\x08\x4c\x00\x0f\x00\x00\x00\x14\x00\x12\x50\x72\x6f\x76\x69\x73\x69\x6f\x6e\x2e\x43\x50\x55\x2e\x56\x43\x4d\x50\x08\x56\x00\x05\x00\x00\x30\x5f\x08\x53\x00\x0e\x00\x00\x00\x06\x00\x0f\x00\x00\x00\x00\x00\x00\x00\x00",
  "\x00\x00\x00\x33\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0b\x65\x00\x0d\x00\x00\x00\x2b\x08\x4a\x00\x0d\x00\x00\x00\x21\x08\x4b\x00\x0f\x00\x00\x00\x17\x00\x15\x63\x6c\x75\x73\x74\x65\x72\x65\x64\x2e\x65\x6e\x76\x69\x72\x6f\x6e\x6d\x65\x6e\x74\x00\x00\x00\x00",
  "\x00\x00\x01\x0f\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x09\x00\x0d\x00\x00\x00\x1c\x10\x0a\x00\x0e\x00\x00\x00\x12\x00\x0f\x00\x00\x00\x01\x00\x00\x00\x08\x00\x06\x5b\x4e\x6f\x6e\x65\x5d\x00\x00\x0b\x68\x00\x0d\x00\x00\x00\xe3\x08\x4a\x00\x0d\x00\x00\x00\xd9\x08\x4b\x00\x0f\x00\x00\x00\x17\x00\x15\x63\x6c\x75\x73\x74\x65\x72\x65\x64\x2e\x65\x6e\x76\x69\x72\x6f\x6e\x6d\x65\x6e\x74\x11\x8f\x00\x05\x00\x00\x00\x01\x28\x74\x00\x0f\x00\x00\x00\x07\x00\x05\x66\x61\x6c\x73\x65\x08\x52\x00\x0f\x00\x00\x00\x02\x00\x00\x08\x51\x00\x0f\x00\x00\x00\x02\x00\x00\x08\x50\x00\x0f\x00\x00\x00\x06\x00\x04\x65\x6e\x75\x6d\x08\x4f\x00\x0f\x00\x00\x00\x0f\x00\x0d\x70\x72\x69\x76\x61\x74\x65\x5f\x6c\x6f\x63\x61\x6c\x08\x4e\x00\x0f\x00\x00\x00\x07\x00\x05\x66\x61\x6c\x73\x65\x08\x4d\x00\x0f\x00\x00\x00\x07\x00\x05\x66\x61\x6c\x73\x65\x08\x4c\x00\x0f\x00\x00\x00\x17\x00\x15\x43\x6c\x75\x73\x74\x65\x72\x65\x64\x2e\x45\x6e\x76\x69\x72\x6f\x6e\x6d\x65\x6e\x74\x08\x56\x00\x05\x00\x00\x2c\x9d\x08\x53\x00\x0e\x00\x00\x00\x1b\x00\x0f\x00\x00\x00\x02\x00\x00\x00\x06\x00\x04\x74\x72\x75\x65\x00\x00\x00\x07\x00\x05\x66\x61\x6c\x73\x65\x00\x00\x00\x00",
]

TESTS.each do |t|
  parse_stream(t)
  puts ''
end
