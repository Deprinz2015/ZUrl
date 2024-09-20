const std = @import("std");
const DB = @import("DB.zig");
const Server = @import("Server.zig");
const Zli = @import("Zli");

const GPA = std.heap.GeneralPurposeAllocator;

var db: DB = undefined;
var server: Server = undefined;

pub fn main() !u8 {
    var gpa = GPA(.{}){};
    const alloc = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    var parser = Zli.init(alloc);
    defer parser.deinit();
    parser.parse() catch |err| {
        std.debug.print("Error: {s}\n", .{@errorName(err)});
        std.debug.print("{s}", .{parser.help});
        return 1;
    };

    if (parser.options.help) {
        std.debug.print("{s}", .{parser.help});
        return 0;
    }

    db = DB.init(alloc);
    defer db.deinit();

    try db.open_db(parser.options.db);
    try db.createDbIfNotExists();

    server = try Server.init(alloc, &db, parser.options.port);
    defer server.deinit();

    std.posix.sigaction(std.posix.SIG.INT, &.{
        .handler = .{ .handler = shutdown },
        .mask = std.posix.empty_sigset,
        .flags = 0,
    }, null);

    try server.start();
    return 0;
}

fn shutdown(_: c_int) callconv(.C) void {
    std.debug.print("\nShutting down...\n", .{});
    server.stop();
}
