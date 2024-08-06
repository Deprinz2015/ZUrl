const std = @import("std");
const DB = @import("DB.zig");
const Server = @import("Server.zig");

const GPA = std.heap.GeneralPurposeAllocator;

const DB_FILE = "data/urls.db";
const PORT = 8080;

var db: DB = undefined;
var server: Server = undefined;

pub fn main() !void {
    var gpa = GPA(.{}){};
    const alloc = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    db = DB.init(alloc);
    defer db.deinit();

    try db.open_db(DB_FILE);
    try db.createDbIfNotExists();

    server = try Server.init(alloc, &db, PORT);
    defer server.deinit();

    std.posix.sigaction(std.posix.SIG.INT, &.{
        .handler = .{ .handler = shutdown },
        .mask = std.posix.empty_sigset,
        .flags = 0,
    }, null);

    try server.start();
}

fn shutdown(_: c_int) callconv(.C) void {
    std.debug.print("\nShutting down...\n", .{});
    server.stop();
}
