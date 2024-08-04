const std = @import("std");
const c = @cImport(
    @cInclude("sqlite3.h"),
);

const Error = error{
    CouldNotOpen,
    SQLiteError,
};

const UrlEntry = struct {
    id: ?u32,
    short: []const u8,
    full_url: []const u8,

    pub fn createFromUrl(url: []const u8) UrlEntry {
        _ = url;
    }

    fn randomString() []const u8 {
        var prng = std.Random.DefaultPrng.init(blk: {
            var seed: u64 = undefined;
            try std.posix.getrandom(std.mem.asBytes(&seed));
            break :blk seed;
        });
        const rand = prng.random();
        _ = rand;
    }
};

const DB = @This();

db: ?*c.sqlite3 = null,

pub fn open_db(self: *DB, db_file: []const u8) !void {
    const rc = c.sqlite3_open(db_file.ptr, &self.db);
    if (rc != 0) {
        std.debug.print("Could not open database because '{s}'\n", .{c.sqlite3_errstr(rc)});
        return Error.CouldNotOpen;
    }
}

pub fn deinit(self: *DB) void {
    const rc = c.sqlite3_close(self.db);
    if (rc != 0) {
        std.debug.print("Could not open database because '{s}'\n", .{c.sqlite3_errstr(rc)});
    }
}

pub fn createDbIfNotExists(self: *DB) !void {
    const create_db =
        \\ CREATE TABLE IF NOT EXISTS url (
        \\      id INTEGER PRIMARY KEY AUTOINCREMENT,
        \\      short CHAR(5) NOT NULL,
        \\      full_url LONGTEXT NOT NULL
        \\ ) 
    ;

    self.executeString(create_db) catch |e| {
        std.debug.print("Could not create database\n", .{});
        return e;
    };
}

fn executeString(self: *DB, sql: []const u8) !void {
    var err_msg: [*c]u8 = undefined;
    const rc = c.sqlite3_exec(self.db, sql.ptr, null, null, &err_msg);
    if (rc != 0) {
        std.debug.print("Error when executing sql: '{s}'\n", .{err_msg});
        return Error.SQLiteError;
    }
}
