const std = @import("std");
const GPA = std.heap.GeneralPurposeAllocator;
const DB = @import("DB.zig");

const DB_FILE = "data/urls.db";

pub fn main() !void {
    var gpa = GPA(.{}){};
    const alloc = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    var db: DB = DB.init(alloc);
    defer db.deinit();

    try db.open_db(DB_FILE);
    try db.createDbIfNotExists();

    // TODO: Http Server
}
