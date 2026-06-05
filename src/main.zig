const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const c = @cImport(@cInclude("zkemsdk.h"));

fn zkErrorString(error_code: c_int) []const u8 {
    return switch (error_code) {
        c.ZK_SUCCESS => "success",
        c.ZK_ERR_NO_DATA => "no data",
        c.ZK_ERR_INVALID_PARAM => "invalid param",
        c.ZK_ERROR_NOT_INIT => "not initialized",
        c.ZK_ERROR_IO => "I/O error",
        c.ZK_ERROR_SIZE => "size error",
        c.ZK_ERROR_NO_SPACE => "no space",
        c.ZK_ERROR_UNSUPPORT => "unsupported",
        else => "unknown error",
    };
}

fn printLastError(writer: *Io.Writer) !void {
    var error_code: c_int = undefined;
    if (c.Z_LastError(&error_code) == 0) {
        try writer.writeAll("Z_lastError failed\n");
        return;
    }

    try writer.print("error: {s}\n", .{zkErrorString(error_code)});
}

// Pasos:
//
// - Cargar zkemsdk.dll.
// - Llamar a Z_Connect_NET("ip", 4370).
//   - Si falla:
//     - llamar a Z_LastError()
//     - imprimir el error.
//   - Si conecta:
//     - llamar a Z_EnableDevice(machine_number, 0) para bloquear el teclado mientras leés.
//     - llamar a Z_ReadLog(machine_number).
//     - iterar con Z_GetLog(...).
//       - imprimir cada registro.
//     - volver a Z_EnableDevice(machine_number, 1).
//     - Z_Close().

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io = init.io;

    var stdout_buf: [1024]u8 = undefined;
    var stdout_fw: Io.File.Writer = .init(.stdout(), io, &stdout_buf);
    const stdout: *Io.Writer = &stdout_fw.interface;
    defer stdout.flush() catch {};

    var args: std.process.Args.Iterator = try init.minimal.args.iterateAllocator(gpa);
    defer args.deinit();

    const cmd: [:0]const u8 = args.next().?;
    const ip_str: [:0]const u8, const port: c_int, const mn: c_int = args: {
        const err = error.InvalidArgs;

        const ip_str: [:0]const u8 = args.next() orelse break :args err;
        const port_str: [:0]const u8 = args.next() orelse break :args err;
        const mn_str: [:0]const u8 = args.next() orelse break :args err;
        if (args.next() != null) break :args err;

        const port: c_int = try std.fmt.parseInt(c_int, port_str, 10);
        const mn: c_int = try std.fmt.parseInt(c_int, mn_str, 10);

        break :args .{ ip_str, port, mn };
    } catch |err| {
        try stdout.print("Usage: {s} <ip> <port> <machine_number>\n", .{cmd});
        return err;
    };

    try stdout.writeAll(" --- ZK POC ---\n\n");

    if (c.Z_Connect_NET(ip_str, port) == 0) {
        try printLastError(stdout);
        return error.Z_Connect_NETFailed;
    }
    defer c.Z_Close();

    if (c.Z_EnableDevice(mn, 0) == 0) {
        try printLastError(stdout);
        return error.Z_EnableDeviceFailed;
    }
    defer if (c.Z_EnableDevice(mn, 1) == 0) {
        printLastError(stdout) catch {};
        stdout.print("error: Unable to enable back device {d}\n", .{mn}) catch {};
    };

    if (c.Z_ReadLog(mn) == 0) {
        try printLastError(stdout);
        return error.Z_ReadLog;
    }

    var tmachine: c_int = undefined;
    var enroll_number: c_int = undefined;
    var emachine_number: c_int = undefined;
    var verify_mode: c_int = undefined;
    var in_out_mode: c_int = undefined;
    var year: c_int = undefined;
    var month: c_int = undefined;
    var day: c_int = undefined;
    var hour: c_int = undefined;
    var minute: c_int = undefined;

    try stdout.print("machine number: {d}\n", .{mn});

    while (c.Z_GetLog(
        mn,
        &tmachine,
        &enroll_number,
        &emachine_number,
        &verify_mode,
        &in_out_mode,
        &year,
        &month,
        &day,
        &hour,
        &minute,
    ) != 0) {
        try stdout.print(
            \\        ----- Entry -----
            \\
            \\        tmachine: {d:>10}
            \\   enroll number: {d:>10}
            \\ emachine number: {d:>10}
            \\     verify mode: {d:>10}
            \\     in out mode: {d:>10}
            \\            year: {d:>10}
            \\           month: {d:>10}
            \\             day: {d:>10}
            \\            hour: {d:>10}
            \\          minute: {d:>10}
            \\
        , .{
            tmachine,
            enroll_number,
            emachine_number,
            verify_mode,
            in_out_mode,
            year,
            month,
            day,
            hour,
            minute,
        });
    }

    try stdout.writeAll("That's all.\n");
}
