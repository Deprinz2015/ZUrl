const std = @import("std");
const DB = @import("DB.zig");
const Server = @import("Server.zig");
const Zli = @import("Zli");

const GPA = std.heap.GeneralPurposeAllocator;

const DEFAULT_DB_FILE = "data/urls.db";
const DEFAULT_PORT = 8080;

var db: DB = undefined;
var server: Server = undefined;

pub fn main() !void {
    var gpa = GPA(.{}){};
    const alloc = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    var parser = Zli.init(alloc);
    defer parser.deinit();

    try parser.addOption("port", null, "Port number, on which the server to run on.");
    try parser.addOption("db", null, "Path to the sqlite file.");
    try parser.addOption("help", 'h', "Print this help/usage message.");

    if (try parser.option(bool, "help")) {
        _ = try parser.help(std.io.getStdErr().writer(), 0);
        return;
    }

    const port = try parser.option(u16, "port") orelse DEFAULT_PORT;
    const dbfile = try parser.option([]const u8, "db") orelse DEFAULT_DB_FILE;

    db = DB.init(alloc);
    defer db.deinit();

    try db.open_db(dbfile);
    try db.createDbIfNotExists();

    server = try Server.init(alloc, &db, port);
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
