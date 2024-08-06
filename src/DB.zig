const std = @import("std");
const Allocator = std.mem.Allocator;
const c = @cImport(
    @cInclude("sqlite3.h"),
);

const ALLOWED_CHARACTERS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

pub const Error = error{
    CouldNotOpen,
    SQLiteError,
    CouldNotGenerateKey,
    QueryFormatError,
    NoEntryFound,
};

const UrlEntry = struct {
    id: ?u32,
    key: []const u8,
    url: []const u8,

    /// need to call freeShort on entry after usage with the same allocator
    fn createFromUrl(alloc: Allocator, url: []const u8) !UrlEntry {
        const key = try randomString(alloc, 5);
        return .{
            .id = null,
            .key = key,
            .url = url,
        };
    }

    /// frees the .short slice
    fn freeKey(self: *const UrlEntry, alloc: Allocator) void {
        alloc.free(self.key);
    }

    /// Caller owns memory
    fn randomString(alloc: Allocator, len: usize) ![]const u8 {
        var prng = std.Random.DefaultPrng.init(blk: {
            var seed: u64 = undefined;
            try std.posix.getrandom(std.mem.asBytes(&seed));
            break :blk seed;
        });

        const string = try alloc.alloc(u8, len);
        var idx: usize = 0;
        while (idx < len) : (idx += 1) {
            string[idx] = ALLOWED_CHARACTERS[prng.random().intRangeLessThan(usize, 0, ALLOWED_CHARACTERS.len)];
        }
        return string;
    }
};

const DB = @This();

db: ?*c.sqlite3 = null,
found_entries: std.ArrayList(UrlEntry),
alloc: Allocator,

pub fn open_db(self: *DB, db_file: []const u8) !void {
    const rc = c.sqlite3_open(db_file.ptr, &self.db);
    if (rc != 0) {
        std.debug.print("Could not open database because '{s}'\n", .{c.sqlite3_errstr(rc)});
        return Error.CouldNotOpen;
    }
}

pub fn init(alloc: Allocator) DB {
    return .{
        .alloc = alloc,
        .found_entries = std.ArrayList(UrlEntry).init(alloc),
    };
}

fn deinitEntries(self: *DB) void {
    for (self.found_entries.items) |entry| {
        self.alloc.free(entry.url);
        self.alloc.free(entry.key);
    }
    self.found_entries.clearAndFree();
}

pub fn deinit(self: *DB) void {
    const rc = c.sqlite3_close(self.db);
    if (rc != 0) {
        std.debug.print("Could not open database because '{s}'\n", .{c.sqlite3_errstr(rc)});
    }

    self.deinitEntries();
    self.found_entries.deinit();
}

/// dupes the created key with provided alloc
pub fn newUrl(self: *DB, url: []const u8, alloc: Allocator) ![]const u8 {
    const entry = UrlEntry.createFromUrl(self.alloc, url) catch {
        std.debug.print("Could not create a new entry from url.\n", .{});
        return Error.CouldNotGenerateKey;
    };
    defer entry.freeKey(self.alloc);

    const insert_sql = "INSERT INTO url (key, url) VALUES ('{s}', '{s}')";
    const insert_query = std.fmt.allocPrintZ(self.alloc, insert_sql, .{ entry.key, entry.url }) catch {
        std.debug.print("Could not format insert query\n", .{});
        return Error.QueryFormatError;
    };
    defer self.alloc.free(insert_query);

    self.executeString(insert_query) catch |e| {
        std.debug.print("Could not insert entry\n", .{});
        return e;
    };

    return try alloc.dupe(u8, entry.key);
}

pub fn readKey(self: *DB, key: []const u8) ![]const u8 {
    const select_sql = "SELECT * FROM url WHERE key = '{s}'";
    const select_query = std.fmt.allocPrintZ(self.alloc, select_sql, .{key}) catch {
        std.debug.print("Could not format select query\n", .{});
        return Error.QueryFormatError;
    };
    defer self.alloc.free(select_query);

    self.queryString(select_query) catch |e| {
        std.debug.print("Could not query table\n", .{});
        return e;
    };

    if (self.found_entries.items.len == 0) {
        return Error.NoEntryFound;
    }

    return self.found_entries.items[0].url;
}

pub fn createDbIfNotExists(self: *DB) !void {
    const create_db =
        \\ CREATE TABLE IF NOT EXISTS url (
        \\      id INTEGER PRIMARY KEY AUTOINCREMENT,
        \\      key CHAR(5) NOT NULL UNIQUE,
        \\      url LONGTEXT NOT NULL
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

fn queryCallback(ctx: ?*anyopaque, col_count: c_int, row: [*c][*c]u8, column_names: [*c][*c]u8) callconv(.C) c_int {
    const self: *DB = @ptrCast(@alignCast(ctx.?));
    var entry: UrlEntry = .{
        .id = undefined,
        .url = undefined,
        .key = undefined,
    };
    var idx: usize = 0;
    while (idx < col_count) : (idx += 1) {
        const col_name = std.mem.span(column_names[idx]);
        const value = self.alloc.dupe(u8, std.mem.span(row[idx])) catch return 1;

        if (std.mem.eql(u8, col_name, "id")) {
            entry.id = std.fmt.parseInt(u32, value, 10) catch return 1;
            self.alloc.free(value);
        } else if (std.mem.eql(u8, col_name, "key")) {
            entry.key = value;
        } else if (std.mem.eql(u8, col_name, "url")) {
            entry.url = value;
        }
    }

    self.found_entries.append(entry) catch return 1;
    return 0;
}

fn queryString(self: *DB, sql: []const u8) !void {
    self.deinitEntries(); // Every Query must start with a clean entry list
    var err_msg: [*c]u8 = undefined;
    const rc = c.sqlite3_exec(self.db, sql.ptr, queryCallback, self, &err_msg);
    if (rc != 0) {
        std.debug.print("Error when executing sql: '{s}'\n", .{err_msg});
        return Error.SQLiteError;
    }
}
