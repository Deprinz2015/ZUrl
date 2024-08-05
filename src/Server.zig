const std = @import("std");
const httpz = @import("httpz");
const DB = @import("DB.zig");

const Allocator = std.mem.Allocator;

const Self = @This();

_server: httpz.ServerCtx(void, void),
alloc: Allocator,

pub fn init(alloc: Allocator, db: *DB) !Self {
    var server: Self = .{
        .alloc = alloc,
        .db = db,
        ._server = undefined,
    };

    server._server = try httpz.ServerApp(*DB).init(alloc, .{ .port = 8080 }, db);
    var router = server._server.router();
    router.get("/:key", handler);

    return server;
}

pub fn deinit(self: *Self) void {
    self._server.deinit();
}

pub fn start(self: *Self) !void {
    try self._server.listen();
}

pub fn stop(self: *Self) void {
    self._server.stop();
}

fn handler(db: *DB, req: *httpz.Request, res: *httpz.Response) !void {
    const key = req.param("key").?;
    // TODO: Finish handler, getting url from db and redirect, if not found, return 404
}
