const std = @import("std");
const httpz = @import("httpz");
const DB = @import("DB.zig");

const Allocator = std.mem.Allocator;

const Self = @This();

_server: httpz.Server(*DB),
alloc: Allocator,

pub fn init(alloc: Allocator, db: *DB, port: u16) !Self {
    var server: Self = .{
        .alloc = alloc,
        ._server = undefined,
    };

    server._server = try .init(alloc, .{ .port = port }, db);
    var router = server._server.router(.{});
    router.post("/create", createAction, .{});
    router.get("/:key", redirectAction, .{});

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

fn redirectAction(db: *DB, req: *httpz.Request, res: *httpz.Response) !void {
    std.debug.print("redirect Action\n", .{});
    const key = req.param("key").?;

    const url = db.readKey(key) catch |err| {
        switch (err) {
            DB.Error.NoEntryFound => {
                res.status = 404;
                res.body = "Not Found";
            },
            else => {
                res.status = 500;
                res.body = "Internal Server Error";
            },
        }
        return;
    };

    res.status = 302;
    res.header("Location", url);
}

fn createAction(db: *DB, req: *httpz.Request, res: *httpz.Response) !void {
    std.debug.print("create Action\n", .{});
    const maybe_body = req.jsonObject() catch {
        res.status = 500;
        try res.json(.{ .msg = "Could not parse request body. Expecting a valid json object." }, .{});
        return;
    };

    if (maybe_body) |body| {
        if (body.get("url")) |url| {
            if (url == .string) {
                const key = db.newUrl(url.string, req.arena) catch {
                    res.status = 500;
                    try res.json(.{ .msg = "Could not create an entry." }, .{});
                    return;
                };

                res.status = 200;
                try res.json(.{ .key = key }, .{});
                return;
            }
        }
    }

    res.status = 500;
    try res.json(.{ .msg = "Internal Server error" }, .{});
}
