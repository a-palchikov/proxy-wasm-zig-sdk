const std = @import("std");
const mecha = @import("mecha");

const KeyValue = struct {
    key: Keys,
    value: []const u8,
};

pub fn parse(allocator: std.mem.Allocator, input: []const u8) ![]KeyValue {
    const result = try cert_header.parse(allocator, input);
    return result.value;
}

const cert_header = key_value.many(.{ .min = 1, .separator = separator_char, .collect = true });

const key_value = mecha.combine(.{ header_key, mecha.ascii.char('=').discard(), header_value }).map(mecha.toStruct(KeyValue));

// Keys
const key_hash = mecha.string("Hash");
const key_cert = mecha.string("Cert");

// TODO: add the rest of XFCC keys
const header_key = mecha.oneOf(.{ key_hash, key_cert }).convert(mecha.toEnum(Keys));

const quote_char = mecha.ascii.char('"').discard();
const separator_char = mecha.ascii.char(';').discard();
// any ascii char except ';' and '"'
const identifier_char = mecha.oneOf(.{
    mecha.ascii.range(32, 33).discard(),
    mecha.ascii.range(35, 58).discard(),
    mecha.ascii.range(60, 126).discard(),
});

const identifier = identifier_char.many(.{ .collect = false, .min = 1 });
const header_value = mecha.oneOf(.{ identifier, quoted_identifier });
const quoted_identifier = mecha.combine(.{ quote_char, identifier, quote_char });

const Keys = enum(u8) {
    Hash,
    By,
    Cert,
    Chain,
    Subject,
    URI,
    DNS,
};
