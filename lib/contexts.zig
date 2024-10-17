const enums = @import("enums.zig");
const std = @import("std");
const assert = std.debug.assert;

pub const RootContext = struct {
    const Self = @This();

    ptr: *anyopaque,

    // The followings are only used by SDK internally. See state.zig.
    onVmStart: *const fn (self: *anyopaque, configuration_size: usize) bool,
    onPluginStart: *const fn (self: *anyopaque, configuration_size: usize) bool,
    onPluginDone: *const fn (self: *anyopaque) bool,
    onDelete: *const fn (self: *anyopaque) void,
    newTcpContext: *const fn (self: *anyopaque, context_id: u32) ?*TcpContext,
    newHttpContext: *const fn (self: *anyopaque, context_id: u32) ?*HttpContext,
    onQueueReady: *const fn (self: *anyopaque, quque_id: u32) void,
    onTick: *const fn (self: *anyopaque) void,
    onHttpCalloutResponse: *const fn (self: *anyopaque, callout_id: u32, num_headers: usize, body_size: usize, num_trailers: usize) void,

    pub fn init(pointer: anytype, callbacks: RootCallbacks) RootContext {
        const Ptr = @TypeOf(pointer);
        assert(@typeInfo(Ptr) == .pointer); // Must be a pointer
        assert(@typeInfo(Ptr).pointer.size == .One); // Must be a single-item pointer
        assert(@typeInfo(@typeInfo(Ptr).pointer.child) == .@"struct"); // Must point to a struct
        const gen = struct {
            fn onVmStart(ptr: *anyopaque, configuration_size: usize) bool {
                if (callbacks.onVmStartImpl) |impl| {
                    const self: Ptr = @ptrCast(@alignCast(ptr));
                    return impl(self, configuration_size);
                }
                return true;
            }
            fn onPluginStart(ptr: *anyopaque, configuration_size: usize) bool {
                if (callbacks.onPluginStartImpl) |impl| {
                    const self: Ptr = @ptrCast(@alignCast(ptr));
                    return impl(self, configuration_size);
                }
                return true;
            }
            fn onPluginDone(ptr: *anyopaque) bool {
                if (callbacks.onPluginDoneImpl) |impl| {
                    const self: Ptr = @ptrCast(@alignCast(ptr));
                    return impl(self);
                }
                return true;
            }
            fn onDelete(ptr: *anyopaque) void {
                if (callbacks.onDeleteImpl) |impl| {
                    const self: Ptr = @ptrCast(@alignCast(ptr));
                    return impl(self);
                }
            }
            fn newTcpContext(ptr: *anyopaque, context_id: u32) ?*TcpContext {
                if (callbacks.newTcpContextImpl) |impl| {
                    const self: Ptr = @ptrCast(@alignCast(ptr));
                    return impl(self, context_id);
                }
                return null;
            }
            fn newHttpContext(ptr: *anyopaque, context_id: u32) ?*HttpContext {
                if (callbacks.newHttpContextImpl) |impl| {
                    const self: Ptr = @ptrCast(@alignCast(ptr));
                    return impl(self, context_id);
                }
                return null;
            }
            fn onQueueReady(ptr: *anyopaque, queue_id: u32) void {
                if (callbacks.onQueueReadyImpl) |impl| {
                    const self: Ptr = @ptrCast(@alignCast(ptr));
                    impl(self, queue_id);
                }
            }
            fn onTick(ptr: *anyopaque) void {
                if (callbacks.onTickImpl) |impl| {
                    const self: Ptr = @ptrCast(@alignCast(ptr));
                    impl(self);
                }
            }
            fn onHttpCalloutResponse(ptr: *anyopaque, callout_id: u32, num_headers: usize, body_size: usize, num_trailers: usize) void {
                if (callbacks.onHttpCalloutResponseImpl) |impl| {
                    const self: Ptr = @ptrCast(@alignCast(ptr));
                    impl(self, callout_id, num_headers, body_size, num_trailers);
                }
            }
        };

        return .{
            .ptr = pointer,
            .onVmStart = gen.onVmStart,
            .onPluginStart = gen.onPluginStart,
            .onPluginDone = gen.onPluginDone,
            .onDelete = gen.onDelete,
            .newTcpContext = gen.newTcpContext,
            .newHttpContext = gen.newHttpContext,
            .onQueueReady = gen.onQueueReady,
            .onTick = gen.onTick,
            .onHttpCalloutResponse = gen.onHttpCalloutResponse,
        };
    }
};

pub const TcpContext = struct {
    const Self = @This();

    ptr: *anyopaque,

    // The followings are only used by SDK internally. See state.zig.
    onDownstreamData: *const fn (self: *anyopaque, data_size: usize, end_of_stream: bool) enums.Action,
    onDownstreamClose: *const fn (self: *anyopaque, peer_type: enums.PeerType) void,
    onNewConnection: *const fn (self: *anyopaque) enums.Action,
    onUpstreamData: *const fn (self: *anyopaque, data_size: usize, end_of_stream: bool) enums.Action,
    onUpstreamClose: *const fn (self: *anyopaque, peer_type: enums.PeerType) void,
    onLog: *const fn (self: *anyopaque) void,
    onHttpCalloutResponse: *const fn (self: *anyopaque, callout_id: u32, num_headers: usize, body_size: usize, num_trailers: usize) void,
    onDelete: *const fn (self: *anyopaque) void,

    pub fn init(pointer: anytype, callbacks: TcpCallbacks) TcpContext {
        const Ptr = @TypeOf(pointer);
        assert(@typeInfo(Ptr) == .pointer); // Must be a pointer
        assert(@typeInfo(Ptr).pointer.size == .One); // Must be a single-item pointer
        assert(@typeInfo(@typeInfo(Ptr).pointer.child) == .@"struct"); // Must point to a struct
        const gen = struct {
            fn onDownstreamData(ptr: *anyopaque, data_size: usize, end_of_stream: bool) enums.Action {
                if (callbacks.onDownstreamDataImpl) |impl| {
                    const self: Ptr = @ptrCast(@alignCast(ptr));
                    return impl(self, data_size, end_of_stream);
                }
                return enums.Action.Continue;
            }
            fn onDownstreamClose(ptr: *anyopaque, peer_type: enums.PeerType) void {
                if (callbacks.onDownstreamCloseImpl) |impl| {
                    const self: Ptr = @ptrCast(@alignCast(ptr));
                    impl(self, peer_type);
                }
            }
            fn onNewConnection(ptr: *anyopaque) enums.Action {
                if (callbacks.onNewConnectionImpl) |impl| {
                    const self: Ptr = @ptrCast(@alignCast(ptr));
                    return impl(self);
                }
                return enums.Action.Continue;
            }
            fn onUpstreamData(ptr: *anyopaque, data_size: usize, end_of_stream: bool) enums.Action {
                if (callbacks.onDownstreamDataImpl) |impl| {
                    const self: Ptr = @ptrCast(@alignCast(ptr));
                    return impl(self, data_size, end_of_stream);
                }
                return enums.Action.Continue;
            }
            fn onUpstreamClose(ptr: *anyopaque, peer_type: enums.PeerType) void {
                if (callbacks.onUpstreamCloseImpl) |impl| {
                    const self: Ptr = @ptrCast(@alignCast(ptr));
                    impl(self, peer_type);
                }
            }
            fn onLog(ptr: *anyopaque) void {
                if (callbacks.onLogImpl) |impl| {
                    const self: Ptr = @ptrCast(@alignCast(ptr));
                    impl(self);
                }
            }
            fn onHttpCalloutResponse(ptr: *anyopaque, callout_id: u32, num_headers: usize, body_size: usize, num_trailers: usize) void {
                if (callbacks.onHttpCalloutResponseImpl) |impl| {
                    const self: Ptr = @ptrCast(@alignCast(ptr));
                    impl(self, callout_id, num_headers, body_size, num_trailers);
                }
            }
            fn onDelete(ptr: *anyopaque) void {
                if (callbacks.onDeleteImpl) |impl| {
                    const self: Ptr = @ptrCast(@alignCast(ptr));
                    impl(self);
                }
            }
        };

        return .{
            .ptr = pointer,
            .onDownstreamData = gen.onDownstreamData,
            .onDownstreamClose = gen.onDownstreamClose,
            .onNewConnection = gen.onNewConnection,
            .onUpstreamData = gen.onUpstreamData,
            .onUpstreamClose = gen.onUpstreamClose,
            .onLog = gen.onLog,
            .onHttpCalloutResponse = gen.onHttpCalloutResponse,
            .onDelete = gen.onDelete,
        };
    }
};

pub const HttpContext = struct {
    const Self = @This();

    ptr: *anyopaque,

    // The followings are only used by SDK internally. See state.zig.
    onHttpRequestHeaders: *const fn (self: *Self, num_headers: usize, end_of_stream: bool) enums.Action,
    onHttpRequestBody: *const fn (self: *Self, body_size: usize, end_of_stream: bool) enums.Action,
    onHttpRequestTrailers: *const fn (self: *Self, num_trailers: usize) enums.Action,
    onHttpResponseHeaders: *const fn (self: *Self, num_headers: usize, end_of_stream: bool) enums.Action,
    onHttpResponseBody: *const fn (self: *Self, body_size: usize, end_of_stream: bool) enums.Action,
    onHttpResponseTrailers: *const fn (self: *Self, num_trailers: usize) enums.Action,
    onLog: *const fn (self: *Self) void,
    onHttpCalloutResponse: *const fn (self: *Self, callout_id: u32, num_headers: usize, body_size: usize, num_trailers: usize) void,
    onDelete: *const fn (self: *Self) void,

    pub fn init(pointer: anytype, callbacks: HttpCallbacks(@TypeOf(pointer))) HttpContext {
        const Ptr = @TypeOf(pointer);
        assert(@typeInfo(Ptr) == .pointer); // Must be a pointer
        assert(@typeInfo(Ptr).pointer.size == .One); // Must be a single-item pointer
        assert(@typeInfo(@typeInfo(Ptr).pointer.child) == .@"struct"); // Must point to a struct
        const gen = struct {
            fn onHttpRequestHeaders(ptr: *anyopaque, num_headers: usize, end_of_stream: bool) enums.Action {
                if (callbacks.onHttpRequestHeadersImpl) |impl| {
                    const self: Ptr = @ptrCast(@alignCast(ptr));
                    return impl(self, num_headers, end_of_stream);
                }
                return enums.Action.Continue;
            }
            fn onHttpRequestBody(ptr: *anyopaque, body_size: usize, end_of_stream: bool) enums.Action {
                if (callbacks.onHttpRequestBodyImpl) |impl| {
                    const self: Ptr = @ptrCast(@alignCast(ptr));
                    return impl(self, body_size, end_of_stream);
                }
                return enums.Action.Continue;
            }
            fn onHttpRequestTrailers(ptr: *anyopaque, num_trailers: usize) enums.Action {
                if (callbacks.onHttpRequestTrailersImpl) |impl| {
                    const self: Ptr = @ptrCast(@alignCast(ptr));
                    return impl(self, num_trailers);
                }
                return enums.Action.Continue;
            }
            fn onHttpResponseHeaders(ptr: *anyopaque, num_headers: usize, end_of_stream: bool) enums.Action {
                if (callbacks.onHttpResponseHeadersImpl) |impl| {
                    const self: Ptr = @ptrCast(@alignCast(ptr));
                    return impl(self, num_headers, end_of_stream);
                }
                return enums.Action.Continue;
            }
            fn onHttpResponseBody(ptr: *anyopaque, body_size: usize, end_of_stream: bool) enums.Action {
                if (callbacks.onHttpResponseBodyImpl) |impl| {
                    const self: Ptr = @ptrCast(@alignCast(ptr));
                    return impl(self, body_size, end_of_stream);
                }
                return enums.Action.Continue;
            }
            fn onHttpResponseTrailers(ptr: *anyopaque, num_trailers: usize) enums.Action {
                if (callbacks.onHttpResponseTrailersImpl) |impl| {
                    const self: Ptr = @ptrCast(@alignCast(ptr));
                    return impl(self, num_trailers);
                }
                return enums.Action.Continue;
            }
            fn onLog(ptr: *anyopaque) void {
                if (callbacks.onLogImpl) |impl| {
                    const self: Ptr = @ptrCast(@alignCast(ptr));
                    impl(self);
                }
            }
            fn onHttpCalloutResponse(ptr: *anyopaque, callout_id: u32, num_headers: usize, body_size: usize, num_trailers: usize) void {
                if (callbacks.onHttpCalloutResponseImpl) |impl| {
                    const self: Ptr = @ptrCast(@alignCast(ptr));
                    impl(self, callout_id, num_headers, body_size, num_trailers);
                }
            }
            fn onDelete(ptr: *anyopaque) void {
                if (callbacks.onDeleteImpl) |impl| {
                    const self: Ptr = @ptrCast(@alignCast(ptr));
                    impl(self);
                }
            }
        };

        return .{
            .ptr = pointer,
            .onHttpRequestHeaders = gen.onHttpRequestHeaders,
            .onHttpRequestBody = gen.onHttpRequestBody,
            .onHttpRequestTrailers = gen.onHttpRequestTrailers,
            .onHttpResponseHeaders = gen.onHttpResponseHeaders,
            .onHttpResponseBody = gen.onHttpResponseBody,
            .onHttpResponseTrailers = gen.onHttpResponseTrailers,
            .onLog = gen.onLog,
            .onHttpCalloutResponse = gen.onHttpCalloutResponse,
            .onDelete = gen.onDelete,
        };
    }
};

pub const RootCallbacks = struct {
    // Implementations used by interfaces.
    // Note that these are optional so we can have the "default" (nop) implementation.

    /// onVmStart is called after the VM is created and _initialize is called.
    /// During this call, hostcalls.getVmConfiguration is available and can be used to
    /// retrieve the configuration set at vm_config.configuration in envoy.yaml
    /// Note that only one RootContext is called on this function;
    /// There's Wasm VM: RootContext = 1: N correspondence, and
    /// each RootContext corresponds to each config.configuration, not vm_config.configuration.
    onVmStartImpl: ?*const fn (self: *anyopaque, configuration_size: usize) bool = null,

    /// onPluginStart is called after onVmStart and for each different plugin configurations.
    /// During this call, hostcalls.getPluginConfiguration is available and can be used to
    /// retrieve the configuration set at config.configuration in envoy.yaml
    onPluginStartImpl: ?*const fn (self: *anyopaque, configuration_size: usize) bool = null,

    /// onPluginDone is called right before deinit is called.
    /// Return false to indicate it's in a pending state to do some more work left,
    /// And must call hostcalls.done after the work is done to invoke deinit and other
    /// cleanup in the host implementation.
    onPluginDoneImpl: ?*const fn (self: *anyopaque) bool = null,

    /// onDelete is called when the host is deleting this context.
    onDeleteImpl: ?*const fn (self: *anyopaque) void = null,

    /// newHttpContext is used for creating HttpContext for http filters.
    /// Return null to indicate this RootContext is not for HTTP streams.
    /// Deallocation of contexts created here should only be performed in HttpContext.onDelete.
    newHttpContextImpl: ?*const fn (self: *anyopaque, context_id: u32) ?*HttpContext = null,

    /// newTcpContext is used for creating TcpContext for tcp filters.
    /// Return null to indicate this RootContext is not for TCP streams.
    /// Deallocation of contexts created here should only be performed in TcpContext.onDelete.
    newTcpContextImpl: ?*const fn (self: *anyopaque, context_id: u32) ?*TcpContext = null,

    /// onQueueReady is called when the queue is ready after calling hostcalls.RegisterQueue.
    /// Note that the queue is dequeued by another VM running in another thread, so possibly
    /// the queue is empty during onQueueReady.
    onQueueReadyImpl: ?*const fn (self: *anyopaque, quque_id: u32) void = null,

    /// onTick is called when the queue is called when SetTickPeriod hostcall
    /// is called by this root context.
    onTickImpl: ?*const fn (self: *anyopaque) void = null,

    /// onHttpCalloutResponse is called when a dispatched http call by hostcalls.dispatchHttpCall
    /// has received a response.
    onHttpCalloutResponseImpl: ?*const fn (self: *anyopaque, callout_id: u32, num_headers: usize, body_size: usize, num_trailers: usize) void = null,
};

pub const TcpCallbacks = struct {
    // Implementations used by interfaces.
    // Note that these types are optional so we can have the "default" (nop) implementation.

    /// onNewConnection is called when the tcp connection is established between Down and Upstreams.
    onNewConnectionImpl: ?*const fn (self: *anyopaque) enums.Action = null,

    /// onDownstreamData is called when the data fram arrives from the downstream connection.
    onDownstreamDataImpl: ?*const fn (self: *anyopaque, data_size: usize, end_of_stream: bool) enums.Action = null,

    /// onDownstreamClose is called when the downstream connection is closed.
    onDownstreamCloseImpl: ?*const fn (self: *anyopaque, peer_type: enums.PeerType) void = null,

    /// onUpstreamData is called when the data fram arrives from the upstream connection.
    onUpstreamDataImpl: ?*const fn (self: *anyopaque, data_size: usize, end_of_stream: bool) enums.Action = null,

    /// onUpstreamClose is called when the upstream connection is closed.
    onUpstreamCloseImpl: ?*const fn (self: *anyopaque, peer_type: enums.PeerType) void = null,

    /// onUpstreamClose is called before the host calls onDelete.
    /// You can retreive the stream information (such as remote addesses, etc.) during this calls
    /// Can be used for implementing logging feature.
    onLogImpl: ?*const fn (self: *anyopaque) void = null,

    /// onDelete is called when the host is deleting this context.
    onDeleteImpl: ?*const fn (self: *anyopaque) void = null,

    /// onHttpCalloutResponse is called when a dispatched http call by hostcalls.dispatchHttpCall
    /// has received a response.
    onHttpCalloutResponseImpl: ?*const fn (self: *anyopaque, callout_id: u32, num_headers: usize, body_size: usize, num_trailers: usize) void = null,
};

pub const HttpCallbacks = struct {
    // Implementations used by interfaces.
    // Note that these types are optional so we can have the "default" (nop) implementation.

    /// onHttpRequestHeaders is called when request headers arrives.
    onHttpRequestHeadersImpl: ?*const fn (self: *anyopaque, num_headers: usize, end_of_stream: bool) enums.Action = null,

    /// onHttpRequestHeaders is called when a request body *frame* arrives.
    /// Note that this is possibly called multiple times until we see end_of_stream = true,
    onHttpRequestBodyImpl: ?*const fn (self: *anyopaque, body_size: usize, end_of_stream: bool) enums.Action = null,

    /// onHttpRequestTrailers is called when request trailers arrives.
    onHttpRequestTrailersImpl: ?*const fn (self: *anyopaque, num_trailers: usize) enums.Action = null,

    /// onHttpResponseHeaders is called when response headers arrives.
    onHttpResponseHeadersImpl: ?*const fn (self: *anyopaque, num_headers: usize, end_of_stream: bool) enums.Action = null,

    /// onHttpResponseBody is called when a response body *frame* arrives.
    /// Note that this is possibly called multiple times until we see end_of_stream = true,
    onHttpResponseBodyImpl: ?*const fn (self: *anyopaque, body_size: usize, end_of_stream: bool) enums.Action = null,

    /// onHttpResponseTrailers is called when response trailers arrives.
    onHttpResponseTrailersImpl: ?*const fn (self: *anyopaque, num_trailers: usize) enums.Action = null,

    /// onUpstreamClose is called before the host calls onDelete.
    /// You can retreive the HTTP request/response information (such headers, etc.) during this calls
    /// Can be used for implementing logging feature.
    onLogImpl: ?*const fn (self: *anyopaque) void = null,

    /// onDelete is called when the host is deleting this context.
    onDeleteImpl: ?*const fn (self: *anyopaque) void = null,

    /// onHttpCalloutResponse is called when a dispatched http call by hostcalls.dispatchHttpCall
    /// has received a response.
    onHttpCalloutResponseImpl: ?*const fn (self: *anyopaque, callout_id: u32, num_headers: usize, body_size: usize, num_trailers: usize) void = null,
};
