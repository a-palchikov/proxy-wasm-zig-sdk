const enums = @import("enums.zig");
const std = @import("std");
const assert = std.debug.assert;

pub const RootContext = struct {
    const Self = @This();

    ptr: *anyopaque,

    // The followings are only used by SDK internally. See state.zig.
    onVmStartImpl: *const fn (self: *anyopaque, configuration_size: usize) bool,
    onPluginStartImpl: *const fn (self: *anyopaque, configuration_size: usize) bool,
    onPluginDoneImpl: *const fn (self: *anyopaque) bool,
    onDeleteImpl: *const fn (self: *anyopaque) void,
    newTcpContextImpl: *const fn (self: *anyopaque, context_id: u32) ?*TcpContext,
    newHttpContextImpl: *const fn (self: *anyopaque, context_id: u32) ?*HttpContext,
    onQueueReadyImpl: *const fn (self: *anyopaque, quque_id: u32) void,
    onTickImpl: *const fn (self: *anyopaque) void,
    onHttpCalloutResponseImpl: *const fn (self: *anyopaque, callout_id: u32, num_headers: usize, body_size: usize, num_trailers: usize) void,

    pub fn init(pointer: anytype, comptime callbacks: RootCallbacks(@TypeOf(pointer))) RootContext {
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
            .onVmStartImpl = gen.onVmStart,
            .onPluginStartImpl = gen.onPluginStart,
            .onPluginDoneImpl = gen.onPluginDone,
            .onDeleteImpl = gen.onDelete,
            .newTcpContextImpl = gen.newTcpContext,
            .newHttpContextImpl = gen.newHttpContext,
            .onQueueReadyImpl = gen.onQueueReady,
            .onTickImpl = gen.onTick,
            .onHttpCalloutResponseImpl = gen.onHttpCalloutResponse,
        };
    }

    pub fn onVmStart(self: *Self, configuration_size: usize) bool {
        return self.onVmStartImpl(self.ptr, configuration_size);
    }

    pub fn onPluginStart(self: *Self, configuration_size: usize) bool {
        return self.onPluginStartImpl(self.ptr, configuration_size);
    }

    pub fn onPluginDone(self: *Self) bool {
        return self.onPluginDoneImpl(self.ptr);
    }

    pub fn onDelete(self: *Self) void {
        self.onDeleteImpl(self.ptr);
    }

    pub fn newTcpContext(self: *Self, context_id: u32) ?*TcpContext {
        return self.newTcpContextImpl(self.ptr, context_id);
    }

    pub fn newHttpContext(self: *Self, context_id: u32) ?*HttpContext {
        return self.newHttpContextImpl(self.ptr, context_id);
    }

    pub fn onQueueReady(self: *Self, quque_id: u32) void {
        self.onQueueReadyImpl(self.ptr, quque_id);
    }

    pub fn onTick(self: *Self) void {
        self.onTickImpl(self.ptr);
    }

    pub fn onHttpCalloutResponse(self: *Self, callout_id: u32, num_headers: usize, body_size: usize, num_trailers: usize) void {
        self.onHttpCalloutResponseImpl(self.ptr, callout_id, num_headers, body_size, num_trailers);
    }
};

pub const TcpContext = struct {
    const Self = @This();

    ptr: *anyopaque,

    // The followings are only used by SDK internally. See state.zig.
    onDownstreamDataImpl: *const fn (self: *anyopaque, data_size: usize, end_of_stream: bool) enums.Action,
    onDownstreamCloseImpl: *const fn (self: *anyopaque, peer_type: enums.PeerType) void,
    onNewConnectionImpl: *const fn (self: *anyopaque) enums.Action,
    onUpstreamDataImpl: *const fn (self: *anyopaque, data_size: usize, end_of_stream: bool) enums.Action,
    onUpstreamCloseImpl: *const fn (self: *anyopaque, peer_type: enums.PeerType) void,
    onLogImpl: *const fn (self: *anyopaque) void,
    onHttpCalloutResponseImpl: *const fn (self: *anyopaque, callout_id: u32, num_headers: usize, body_size: usize, num_trailers: usize) void,
    onDeleteImpl: *const fn (self: *anyopaque) void,

    pub fn init(pointer: anytype, comptime callbacks: TcpCallbacks(@TypeOf(pointer))) TcpContext {
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
            .onDownstreamDataImpl = gen.onDownstreamData,
            .onDownstreamCloseImpl = gen.onDownstreamClose,
            .onNewConnectionImpl = gen.onNewConnection,
            .onUpstreamDataImpl = gen.onUpstreamData,
            .onUpstreamCloseImpl = gen.onUpstreamClose,
            .onLogImpl = gen.onLog,
            .onHttpCalloutResponseImpl = gen.onHttpCalloutResponse,
            .onDeleteImpl = gen.onDelete,
        };
    }

    pub fn onDownstreamData(self: *Self, data_size: usize, end_of_stream: bool) enums.Action {
        return self.onDownstreamDataImpl(self.ptr, data_size, end_of_stream);
    }

    pub fn onDownstreamClose(self: *Self, peer_type: enums.PeerType) void {
        self.onDownstreamCloseImpl(self.ptr, peer_type);
    }

    pub fn onNewConnection(self: *Self) enums.Action {
        return self.onNewConnectionImpl(self.ptr);
    }

    pub fn onUpstreamData(self: *Self, data_size: usize, end_of_stream: bool) enums.Action {
        return self.onUpstreamDataImpl(self.ptr, data_size, end_of_stream);
    }

    pub fn onUpstreamClose(self: *Self, peer_type: enums.PeerType) void {
        self.onUpstreamCloseImpl(self.ptr, peer_type);
    }

    pub fn onLog(self: *Self) void {
        self.onLogImpl(self.ptr);
    }

    pub fn onHttpCalloutResponse(self: *Self, callout_id: u32, num_headers: usize, body_size: usize, num_trailers: usize) void {
        self.onHttpCalloutResponseImpl(self.ptr, callout_id, num_headers, body_size, num_trailers);
    }

    pub fn onDelete(self: *Self) void {
        self.onDeleteImpl(self.ptr);
    }
};

pub const HttpContext = struct {
    const Self = @This();

    ptr: *anyopaque,

    // The followings are only used by SDK internally. See state.zig.
    onHttpRequestHeadersImpl: *const fn (self: *anyopaque, num_headers: usize, end_of_stream: bool) enums.Action,
    onHttpRequestBodyImpl: *const fn (self: *anyopaque, body_size: usize, end_of_stream: bool) enums.Action,
    onHttpRequestTrailersImpl: *const fn (self: *anyopaque, num_trailers: usize) enums.Action,
    onHttpResponseHeadersImpl: *const fn (self: *anyopaque, num_headers: usize, end_of_stream: bool) enums.Action,
    onHttpResponseBodyImpl: *const fn (self: *anyopaque, body_size: usize, end_of_stream: bool) enums.Action,
    onHttpResponseTrailersImpl: *const fn (self: *anyopaque, num_trailers: usize) enums.Action,
    onLogImpl: *const fn (self: *anyopaque) void,
    onHttpCalloutResponseImpl: *const fn (self: *anyopaque, callout_id: u32, num_headers: usize, body_size: usize, num_trailers: usize) void,
    onDeleteImpl: *const fn (self: *anyopaque) void,

    pub fn init(pointer: anytype, comptime callbacks: HttpCallbacks(@TypeOf(pointer))) HttpContext {
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
            .onHttpRequestHeadersImpl = gen.onHttpRequestHeaders,
            .onHttpRequestBodyImpl = gen.onHttpRequestBody,
            .onHttpRequestTrailersImpl = gen.onHttpRequestTrailers,
            .onHttpResponseHeadersImpl = gen.onHttpResponseHeaders,
            .onHttpResponseBodyImpl = gen.onHttpResponseBody,
            .onHttpResponseTrailersImpl = gen.onHttpResponseTrailers,
            .onLogImpl = gen.onLog,
            .onHttpCalloutResponseImpl = gen.onHttpCalloutResponse,
            .onDeleteImpl = gen.onDelete,
        };
    }

    pub fn onHttpRequestHeaders(self: *Self, num_headers: usize, end_of_stream: bool) enums.Action {
        return self.onHttpRequestHeadersImpl(self.ptr, num_headers, end_of_stream);
    }

    pub fn onHttpRequestBody(self: *Self, body_size: usize, end_of_stream: bool) enums.Action {
        return self.onHttpRequestBodyImpl(self.ptr, body_size, end_of_stream);
    }

    pub fn onHttpRequestTrailers(self: *Self, num_trailers: usize) enums.Action {
        return self.onHttpRequestTrailersImpl(self.ptr, num_trailers);
    }

    pub fn onHttpResponseHeaders(self: *Self, num_headers: usize, end_of_stream: bool) enums.Action {
        return self.onHttpResponseHeadersImpl(self.ptr, num_headers, end_of_stream);
    }

    pub fn onHttpResponseBody(self: *Self, body_size: usize, end_of_stream: bool) enums.Action {
        return self.onHttpResponseBodyImpl(self.ptr, body_size, end_of_stream);
    }

    pub fn onHttpResponseTrailers(self: *Self, num_trailers: usize) enums.Action {
        return self.onHttpResponseTrailersImpl(self.ptr, num_trailers);
    }

    pub fn onLog(self: *Self) void {
        self.onLogImpl(self.ptr);
    }

    pub fn onHttpCalloutResponse(self: *Self, callout_id: u32, num_headers: usize, body_size: usize, num_trailers: usize) void {
        self.onHttpCalloutResponseImpl(self.ptr, callout_id, num_headers, body_size, num_trailers);
    }

    pub fn onDelete(self: *Self) void {
        self.onDeleteImpl(self.ptr);
    }
};

pub fn RootCallbacks(comptime T: type) type {
    return struct {
        // Implementations used by interfaces.
        // Note that these are optional so we can have the "default" (nop) implementation.

        /// onVmStart is called after the VM is created and _initialize is called.
        /// During this call, hostcalls.getVmConfiguration is available and can be used to
        /// retrieve the configuration set at vm_config.configuration in envoy.yaml
        /// Note that only one RootContext is called on this function;
        /// There's Wasm VM: RootContext = 1: N correspondence, and
        /// each RootContext corresponds to each config.configuration, not vm_config.configuration.
        onVmStartImpl: ?*const fn (self: T, configuration_size: usize) bool = null,

        /// onPluginStart is called after onVmStart and for each different plugin configurations.
        /// During this call, hostcalls.getPluginConfiguration is available and can be used to
        /// retrieve the configuration set at config.configuration in envoy.yaml
        onPluginStartImpl: ?*const fn (self: T, configuration_size: usize) bool = null,

        /// onPluginDone is called right before deinit is called.
        /// Return false to indicate it's in a pending state to do some more work left,
        /// And must call hostcalls.done after the work is done to invoke deinit and other
        /// cleanup in the host implementation.
        onPluginDoneImpl: ?*const fn (self: T) bool = null,

        /// onDelete is called when the host is deleting this context.
        onDeleteImpl: ?*const fn (self: T) void = null,

        /// newHttpContext is used for creating HttpContext for http filters.
        /// Return null to indicate this RootContext is not for HTTP streams.
        /// Deallocation of contexts created here should only be performed in HttpContext.onDelete.
        newHttpContextImpl: ?*const fn (self: T, context_id: u32) ?*HttpContext = null,

        /// newTcpContext is used for creating TcpContext for tcp filters.
        /// Return null to indicate this RootContext is not for TCP streams.
        /// Deallocation of contexts created here should only be performed in TcpContext.onDelete.
        newTcpContextImpl: ?*const fn (self: T, context_id: u32) ?*TcpContext = null,

        /// onQueueReady is called when the queue is ready after calling hostcalls.RegisterQueue.
        /// Note that the queue is dequeued by another VM running in another thread, so possibly
        /// the queue is empty during onQueueReady.
        onQueueReadyImpl: ?*const fn (self: T, quque_id: u32) void = null,

        /// onTick is called when the queue is called when SetTickPeriod hostcall
        /// is called by this root context.
        onTickImpl: ?*const fn (self: T) void = null,

        /// onHttpCalloutResponse is called when a dispatched http call by hostcalls.dispatchHttpCall
        /// has received a response.
        onHttpCalloutResponseImpl: ?*const fn (self: T, callout_id: u32, num_headers: usize, body_size: usize, num_trailers: usize) void = null,
    };
}

pub fn TcpCallbacks(comptime T: type) type {
    return struct {
        // Implementations used by interfaces.
        // Note that these types are optional so we can have the "default" (nop) implementation.

        /// onNewConnection is called when the tcp connection is established between Down and Upstreams.
        onNewConnectionImpl: ?*const fn (self: T) enums.Action = null,

        /// onDownstreamData is called when the data fram arrives from the downstream connection.
        onDownstreamDataImpl: ?*const fn (self: T, data_size: usize, end_of_stream: bool) enums.Action = null,

        /// onDownstreamClose is called when the downstream connection is closed.
        onDownstreamCloseImpl: ?*const fn (self: T, peer_type: enums.PeerType) void = null,

        /// onUpstreamData is called when the data fram arrives from the upstream connection.
        onUpstreamDataImpl: ?*const fn (self: T, data_size: usize, end_of_stream: bool) enums.Action = null,

        /// onUpstreamClose is called when the upstream connection is closed.
        onUpstreamCloseImpl: ?*const fn (self: T, peer_type: enums.PeerType) void = null,

        /// onUpstreamClose is called before the host calls onDelete.
        /// You can retreive the stream information (such as remote addesses, etc.) during this calls
        /// Can be used for implementing logging feature.
        onLogImpl: ?*const fn (self: T) void = null,

        /// onDelete is called when the host is deleting this context.
        onDeleteImpl: ?*const fn (self: T) void = null,

        /// onHttpCalloutResponse is called when a dispatched http call by hostcalls.dispatchHttpCall
        /// has received a response.
        onHttpCalloutResponseImpl: ?*const fn (self: T, callout_id: u32, num_headers: usize, body_size: usize, num_trailers: usize) void = null,
    };
}

pub fn HttpCallbacks(comptime T: type) type {
    return struct {
        // Implementations used by interfaces.
        // Note that these types are optional so we can have the "default" (nop) implementation.

        /// onHttpRequestHeaders is called when request headers arrives.
        onHttpRequestHeadersImpl: ?*const fn (self: T, num_headers: usize, end_of_stream: bool) enums.Action = null,

        /// onHttpRequestHeaders is called when a request body *frame* arrives.
        /// Note that this is possibly called multiple times until we see end_of_stream = true,
        onHttpRequestBodyImpl: ?*const fn (self: T, body_size: usize, end_of_stream: bool) enums.Action = null,

        /// onHttpRequestTrailers is called when request trailers arrives.
        onHttpRequestTrailersImpl: ?*const fn (self: T, num_trailers: usize) enums.Action = null,

        /// onHttpResponseHeaders is called when response headers arrives.
        onHttpResponseHeadersImpl: ?*const fn (self: T, num_headers: usize, end_of_stream: bool) enums.Action = null,

        /// onHttpResponseBody is called when a response body *frame* arrives.
        /// Note that this is possibly called multiple times until we see end_of_stream = true,
        onHttpResponseBodyImpl: ?*const fn (self: T, body_size: usize, end_of_stream: bool) enums.Action = null,

        /// onHttpResponseTrailers is called when response trailers arrives.
        onHttpResponseTrailersImpl: ?*const fn (self: T, num_trailers: usize) enums.Action = null,

        /// onUpstreamClose is called before the host calls onDelete.
        /// You can retreive the HTTP request/response information (such headers, etc.) during this calls
        /// Can be used for implementing logging feature.
        onLogImpl: ?*const fn (self: T) void = null,

        /// onDelete is called when the host is deleting this context.
        onDeleteImpl: ?*const fn (self: T) void = null,

        /// onHttpCalloutResponse is called when a dispatched http call by hostcalls.dispatchHttpCall
        /// has received a response.
        onHttpCalloutResponseImpl: ?*const fn (self: T, callout_id: u32, num_headers: usize, body_size: usize, num_trailers: usize) void = null,
    };
}
