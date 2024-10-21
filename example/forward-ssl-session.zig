const std = @import("std");
const proxywasm = @import("proxy-wasm-zig-sdk");
const tls13 = @import("tls13");
const allocator = proxywasm.allocator;
const contexts = proxywasm.contexts;
const enums = proxywasm.enums;
const hostcalls = proxywasm.hostcalls;
const xfcc = proxywasm.xfcc;
const percent_decoder = proxywasm.percent_decoder;
const x509 = tls13.x509;
const cert = tls13.cert;

extern fn __wasm_call_ctors() void;

const vm_id = "ziglang_vm";

pub fn main() void {
    // Set up the global RootContext function.
    proxywasm.setNewRootContextFunc(newRootContext);
}

// newRootContext is used for creating root contexts for
// each plugin configuration (i.e. config.configuration field in envoy.yaml).
fn newRootContext(_: usize) *contexts.RootContext {
    var context: *Root = allocator.create(Root) catch unreachable;
    context.init();
    return &context.root_context;
}

// PluginConfiguration is a schema of the configuration.
// We parse a given configuration in json to this.
const PluginConfiguration = struct {
    root: []const u8,
    http: []const u8,
    tcp: []const u8,
};

// We implement interfaces defined in contexts.RootContext (the fields suffixed with "Impl")
// for this "Root" type. See https://www.nmichaels.org/zig/interfaces.html for detail.
const Root = struct {
    const Self = @This();

    // Store the "implemented" contexts.RootContext.
    root_context: contexts.RootContext = undefined,

    // Store the parsed plugin configuration in onPluginStart.
    plugin_configuration: *const Managed(PluginConfiguration),

    // Initialize root_context.
    fn init(self: *Self) void {
        // TODO: If we inline this initialization as a part of default value of root_context,
        // we have "Uncaught RuntimeError: table index is out of bounds" on proxy_on_vm_start.
        // Needs investigation.
        const callbacks = contexts.RootCallbacks(*Self){
            .onVmStartImpl = null,
            .onPluginStartImpl = onPluginStart,
            .onPluginDoneImpl = onPluginDone,
            .onDeleteImpl = onDelete,
            .newHttpContextImpl = newHttpContext,
            .newTcpContextImpl = null,
            .onQueueReadyImpl = null,
            .onTickImpl = null,
        };
        self.root_context = contexts.RootContext.init(self, callbacks);
    }

    // Implement contexts.RootContext.onPluginStart.
    fn onPluginStart(self: *Self, configuration_size: usize) bool {
        // Get plugin configuration data.
        std.debug.assert(configuration_size > 0);
        var plugin_config_data = hostcalls.getBufferBytes(enums.BufferType.PluginConfiguration, 0, configuration_size) catch unreachable;
        defer plugin_config_data.deinit();

        self.plugin_configuration = parsePluginConfig(plugin_config_data.raw_data) catch unreachable;

        // Log the given and parsed configuration.
        const message = std.fmt.allocPrint(
            allocator,
            "plugin configuration: root=\"{s}\", http=\"{s}\", stream=\"{s}\"",
            .{
                self.plugin_configuration.value.root,
                self.plugin_configuration.value.http,
                self.plugin_configuration.value.tcp,
            },
        ) catch unreachable;
        defer allocator.free(message);
        hostcalls.log(enums.LogLevel.Info, message) catch unreachable;

        if (std.mem.eql(u8, self.plugin_configuration.value.root, "singleton")) {
            // Set tick if the "root" configuration is set to "singleton".
            //hostcalls.setTickPeriod(5000);
        }
        return true;
    }

    // Implement contexts.RootContext.onPluginDone.
    fn onPluginDone(self: *Self) bool {
        // Log the given and parsed configuration.
        const message = std.fmt.allocPrint(
            allocator,
            "shutting down the plugin with configuration: root=\"{s}\", http=\"{s}\", stream=\"{s}\"",
            .{
                self.plugin_configuration.value.root,
                self.plugin_configuration.value.http,
                self.plugin_configuration.value.tcp,
            },
        ) catch unreachable;
        defer allocator.free(message);
        hostcalls.log(enums.LogLevel.Info, message) catch unreachable;
        return true;
    }

    // Implement contexts.RootContext.onDelete.
    fn onDelete(self: *Self) void {
        // Destory the configuration allocated during json parsing.
        self.plugin_configuration.deinit();
        // Destroy myself.
        allocator.destroy(self);
    }

    // Implement contexts.RootContext.newHttpContext.
    fn newHttpContext(_: *Self, context_id: u32) ?*contexts.HttpContext {
        var context: *ForwardSslSession = allocator.create(ForwardSslSession) catch unreachable;
        context.init(context_id);
        return &context.http_context;
    }

    fn parsePluginConfig(raw_data: []const u8) !*const Managed(PluginConfiguration) {
        // When in WASM context, this needs to on heap - otherwise it will be created on stack
        // and deallocated upon return
        const parsed = try std.json.parseFromSlice(PluginConfiguration, allocator, raw_data, .{ .allocate = .alloc_always });
        const config = try allocator.create(Managed(PluginConfiguration));
        config.* = Managed(PluginConfiguration).fromJson(parsed);
        return config;
    }
};

const ForwardSslSession = struct {
    const Self = @This();
    // Store the "implemented" contexts.HttoContext.
    http_context: contexts.HttpContext = undefined,

    context_id: usize = 0,
    cert: x509.Certificate = undefined,
    cert_pem: ?[]u8 = null,

    // Initialize this context.
    fn init(self: *Self, context_id: usize) void {
        self.context_id = context_id;
        self.cert_pem = null;
        const callbacks = contexts.HttpCallbacks(*Self){
            .onHttpRequestHeadersImpl = onHttpRequestHeaders,
            .onHttpRequestBodyImpl = null,
            .onHttpRequestTrailersImpl = onHttpRequestTrailers,
            .onHttpResponseHeadersImpl = onHttpResponseHeaders,
            .onHttpResponseBodyImpl = null,
            .onHttpResponseTrailersImpl = onHttpResponseTrailers,
            .onHttpCalloutResponseImpl = null,
            .onLogImpl = null,
            .onDeleteImpl = onDelete,
        };

        self.http_context = contexts.HttpContext.init(self, callbacks);

        const message = std.fmt.allocPrint(
            allocator,
            "HttpHeaderOperation context created: {d}",
            .{self.context_id},
        ) catch unreachable;
        defer allocator.free(message);
        hostcalls.log(enums.LogLevel.Info, message) catch unreachable;
    }

    // Implement contexts.HttpContext.onHttpRequestHeaders.
    fn onHttpRequestHeaders(self: *Self, _: usize, _: bool) enums.Action {
        // Get request headers.
        {
            var headers: hostcalls.HeaderMap = hostcalls.getHeaderMap(enums.MapType.HttpRequestHeaders) catch unreachable;
            defer headers.deinit();

            // Log request headers.
            var iter = headers.map.iterator();
            while (iter.next()) |entry| {
                const message = std.fmt.allocPrint(
                    allocator,
                    "request header: --> key: {s}, value: {s} ",
                    .{ entry.key_ptr.*, entry.value_ptr.* },
                ) catch unreachable;
                defer allocator.free(message);
                hostcalls.log(enums.LogLevel.Info, message) catch unreachable;
            }
        }

        var xfcc_headers = hostcalls.getHeaderMapValue(enums.MapType.HttpRequestHeaders, "x-forwarded-client-cert") catch unreachable;
        defer xfcc_headers.deinit();
        const headers = xfcc.parse(allocator, xfcc_headers.raw_data) catch unreachable;
        for (headers) |header| {
            switch (header.key) {
                .Cert => {
                    const cert_header = allocator.alloc(u8, header.value.len) catch unreachable;
                    defer allocator.free(cert_header);
                    const decoded_cert = std.Uri.percentDecodeBackwards(cert_header, header.value);
                    const certs = cert.convertPEMsToDERs(decoded_cert, "CERTIFICATE", allocator) catch unreachable;
                    defer certs.deinit();
                    self.cert_pem = allocator.dupe(u8, header.value) catch unreachable;
                    std.debug.assert(certs.items.len > 0);
                    var stream = std.io.fixedBufferStream(certs.items[0]);
                    self.cert = x509.Certificate.decode(stream.reader(), allocator) catch unreachable;
                    self.cert.tbs_certificate.print(std.debug.print, "");
                },
                else => {},
            }
        }

        return enums.Action.Continue;
    }

    // Implement contexts.HttpContext.onHttpRequestTrailers.
    fn onHttpRequestTrailers(_: *Self, _: usize) enums.Action {
        // Log request trailers.
        var headers: hostcalls.HeaderMap = hostcalls.getHeaderMap(enums.MapType.HttpRequestTrailers) catch unreachable;
        defer headers.deinit();
        var iter = headers.map.iterator();
        while (iter.next()) |entry| {
            const message = std.fmt.allocPrint(
                allocator,
                "request trailer: --> key: {s}, value: {s} ",
                .{ entry.key_ptr.*, entry.value_ptr.* },
            ) catch unreachable;
            defer allocator.free(message);
            hostcalls.log(enums.LogLevel.Info, message) catch unreachable;
        }
        return enums.Action.Continue;
    }

    // Implement contexts.HttpContext.onHttpResponseHeaders.
    fn onHttpResponseHeaders(self: *Self, _: usize, _: bool) enums.Action {
        // Get response headers.
        var headers: hostcalls.HeaderMap = hostcalls.getHeaderMap(enums.MapType.HttpResponseHeaders) catch unreachable;
        defer headers.deinit();

        // Log response headers.
        var iter = headers.map.iterator();
        while (iter.next()) |entry| {
            const message = std.fmt.allocPrint(
                allocator,
                "response header: <-- key: {s}, value: {s} ",
                .{ entry.key_ptr.*, entry.value_ptr.* },
            ) catch unreachable;
            defer allocator.free(message);
            hostcalls.log(enums.LogLevel.Info, message) catch unreachable;
        }

        // Set x-ssl headers
        if (self.cert_pem) |cert_pem| {
            headers.map.put("x-ssl-client-cert", cert_pem) catch unreachable;
            var issuer = self.cert.tbs_certificate.issuer.toString(allocator) catch unreachable;
            defer issuer.deinit();
            const iss = issuer.toOwnedSlice() catch unreachable;
            headers.map.put("x-ssl-issuer", iss) catch unreachable;
            //headers.map.put("x-ssl-serial", self.cert.tbs_certificate.serial_number.serial.slice()) catch unreachable;
            hostcalls.replaceHeaderMap(enums.MapType.HttpResponseHeaders, headers.map) catch unreachable;
        }

        return enums.Action.Continue;
    }

    // Implement contexts.HttpContext.onHttpResponseTrailers.
    fn onHttpResponseTrailers(_: *Self, _: usize) enums.Action {
        // Log response trailers.
        var headers: hostcalls.HeaderMap = hostcalls.getHeaderMap(enums.MapType.HttpResponseTrailers) catch unreachable;
        defer headers.deinit();
        var iter = headers.map.iterator();
        while (iter.next()) |entry| {
            const message = std.fmt.allocPrint(
                allocator,
                "response trailer: <--- key: {s}, value: {s} ",
                .{ entry.key_ptr.*, entry.value_ptr.* },
            ) catch unreachable;
            defer allocator.free(message);
            hostcalls.log(enums.LogLevel.Info, message) catch unreachable;
        }
        return enums.Action.Continue;
    }

    // Implement contexts.HttpContext.onDelete.
    fn onDelete(self: *Self) void {
        self.cert.deinit();
        //if (self.cert_header) |hdr| {
        //    allocator.destroy(hdr);
        //}
        //self.cert_header.deinit();
        allocator.destroy(self);
    }
};

pub fn Managed(comptime T: type) type {
    return struct {
        value: T,
        arena: *std.heap.ArenaAllocator,

        const Self = @This();

        pub fn fromJson(parsed: std.json.Parsed(T)) Self {
            return .{
                .arena = parsed.arena,
                .value = parsed.value,
            };
        }

        pub fn deinit(self: Self) void {
            const arena = self.arena;
            const alloc = arena.child_allocator;
            arena.deinit();
            alloc.destroy(arena);
        }
    };
}
