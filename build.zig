const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{ .cpu_arch = .wasm32, .os_tag = .wasi });
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .Debug });

    const bin = b.addExecutable(.{ .name = "example", .root_source_file = b.path("example/example.zig"), .optimize = optimize, .target = target });
    const pkg = b.addModule("proxy-wasm-zig-sdk", .{
        .root_source_file = b.path("lib/lib.zig"),
    });
    bin.wasi_exec_model = .reactor;
    bin.root_module.addImport("proxy-wasm-zig-sdk", pkg);
    bin.rdynamic = true;
    b.installArtifact(bin);

    // e2e test setup.
    const host_target = b.standardTargetOptions(.{});
    var e2e_test = b.addTest(.{ .root_source_file = b.path("example/e2e_test.zig"), .target = host_target });
    e2e_test.step.dependOn(&bin.step);
    e2e_test.linkLibC();
    const run_e2e = b.addRunArtifact(e2e_test);

    const e2e_test_setp = b.step("e2e", "Run End-to-End test with Envoy proxy");
    e2e_test_setp.dependOn(&run_e2e.step);
}
