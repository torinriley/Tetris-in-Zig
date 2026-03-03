const std = @import("std");
const c = @cImport({
    @cInclude("raylib.h");
});

const BoardW = 10;
const BoardH = 20;
const CellSize: i32 = 32;
const OffsetX: i32 = 40;
const OffsetY: i32 = 40;
const FallIntervalStart: f32 = 0.55;
const ClearAnimDuration: f32 = 0.14;
const ScoreFilePath = "scores.txt";
const BgColor = c.BLACK;
const TermGreen = c.RAYWHITE;
const TermDim = c.LIGHTGRAY;
const TermDark = c.GRAY;

const ShapeType = enum(u8) { I, O, T, S, Z, J, L };
const Scene = enum { Menu, Playing, Scores };

const Vec2i = struct {
    x: i32,
    y: i32,
};

const PieceDef = struct {
    blocks: [4][4]Vec2i,
    color: c.Color,
};

const Piece = struct {
    t: ShapeType,
    rot: u8,
    x: i32,
    y: i32,
};

const SaveData = struct {
    top_scores: [5]i32,
    games_played: i32,
    total_lines: i32,
};

const Game = struct {
    board: [BoardH][BoardW]u8,
    current: Piece,
    next: ShapeType,
    rng: std.Random.DefaultPrng,
    score: i32,
    lines: i32,
    level: i32,
    drop_timer: f32,
    fall_interval: f32,
    game_over: bool,
    score_saved: bool,
    paused: bool,
    clear_anim_active: bool,
    clear_anim_timer: f32,
    clearing_rows: [4]i32,
    clearing_count: u8,
};

const piece_defs = [_]PieceDef{
    .{ // I
        .blocks = .{
            .{ .{ .x = -1, .y = 0 }, .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = 2, .y = 0 } },
            .{ .{ .x = 1, .y = -1 }, .{ .x = 1, .y = 0 }, .{ .x = 1, .y = 1 }, .{ .x = 1, .y = 2 } },
            .{ .{ .x = -1, .y = 1 }, .{ .x = 0, .y = 1 }, .{ .x = 1, .y = 1 }, .{ .x = 2, .y = 1 } },
            .{ .{ .x = 0, .y = -1 }, .{ .x = 0, .y = 0 }, .{ .x = 0, .y = 1 }, .{ .x = 0, .y = 2 } },
        },
        .color = c.SKYBLUE,
    },
    .{ // O
        .blocks = .{
            .{ .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = 0, .y = 1 }, .{ .x = 1, .y = 1 } },
            .{ .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = 0, .y = 1 }, .{ .x = 1, .y = 1 } },
            .{ .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = 0, .y = 1 }, .{ .x = 1, .y = 1 } },
            .{ .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = 0, .y = 1 }, .{ .x = 1, .y = 1 } },
        },
        .color = c.YELLOW,
    },
    .{ // T
        .blocks = .{
            .{ .{ .x = -1, .y = 0 }, .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = 0, .y = 1 } },
            .{ .{ .x = 0, .y = -1 }, .{ .x = 0, .y = 0 }, .{ .x = 0, .y = 1 }, .{ .x = 1, .y = 0 } },
            .{ .{ .x = -1, .y = 0 }, .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = 0, .y = -1 } },
            .{ .{ .x = 0, .y = -1 }, .{ .x = 0, .y = 0 }, .{ .x = 0, .y = 1 }, .{ .x = -1, .y = 0 } },
        },
        .color = c.PURPLE,
    },
    .{ // S
        .blocks = .{
            .{ .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = -1, .y = 1 }, .{ .x = 0, .y = 1 } },
            .{ .{ .x = 0, .y = -1 }, .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = 1, .y = 1 } },
            .{ .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = -1, .y = 1 }, .{ .x = 0, .y = 1 } },
            .{ .{ .x = 0, .y = -1 }, .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = 1, .y = 1 } },
        },
        .color = c.GREEN,
    },
    .{ // Z
        .blocks = .{
            .{ .{ .x = -1, .y = 0 }, .{ .x = 0, .y = 0 }, .{ .x = 0, .y = 1 }, .{ .x = 1, .y = 1 } },
            .{ .{ .x = 1, .y = -1 }, .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = 0, .y = 1 } },
            .{ .{ .x = -1, .y = 0 }, .{ .x = 0, .y = 0 }, .{ .x = 0, .y = 1 }, .{ .x = 1, .y = 1 } },
            .{ .{ .x = 1, .y = -1 }, .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = 0, .y = 1 } },
        },
        .color = c.RED,
    },
    .{ // J
        .blocks = .{
            .{ .{ .x = -1, .y = 0 }, .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = -1, .y = 1 } },
            .{ .{ .x = 0, .y = -1 }, .{ .x = 0, .y = 0 }, .{ .x = 0, .y = 1 }, .{ .x = 1, .y = 1 } },
            .{ .{ .x = -1, .y = 0 }, .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = 1, .y = -1 } },
            .{ .{ .x = 0, .y = -1 }, .{ .x = 0, .y = 0 }, .{ .x = 0, .y = 1 }, .{ .x = -1, .y = -1 } },
        },
        .color = c.BLUE,
    },
    .{ // L
        .blocks = .{
            .{ .{ .x = -1, .y = 0 }, .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = 1, .y = 1 } },
            .{ .{ .x = 0, .y = -1 }, .{ .x = 0, .y = 0 }, .{ .x = 0, .y = 1 }, .{ .x = 1, .y = -1 } },
            .{ .{ .x = -1, .y = 0 }, .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = -1, .y = -1 } },
            .{ .{ .x = 0, .y = -1 }, .{ .x = 0, .y = 0 }, .{ .x = 0, .y = 1 }, .{ .x = -1, .y = 1 } },
        },
        .color = c.ORANGE,
    },
};

fn shapeIndex(t: ShapeType) usize {
    return @intFromEnum(t);
}

fn randomShape(r: std.Random) ShapeType {
    return @enumFromInt(r.uintLessThan(u8, 7));
}

fn colorForCell(cell: u8) c.Color {
    if (cell == 0) return c.BLANK;
    return piece_defs[cell - 1].color;
}

fn pieceBlocks(piece: Piece) [4]Vec2i {
    return piece_defs[shapeIndex(piece.t)].blocks[piece.rot];
}

fn defaultSaveData() SaveData {
    return SaveData{
        .top_scores = [_]i32{0} ** 5,
        .games_played = 0,
        .total_lines = 0,
    };
}

fn loadSaveData() SaveData {
    const cwd = std.fs.cwd();
    var file = cwd.openFile(ScoreFilePath, .{}) catch return defaultSaveData();
    defer file.close();

    var buf: [256]u8 = undefined;
    const n = file.readAll(&buf) catch return defaultSaveData();
    const input = buf[0..n];

    var data = defaultSaveData();
    var nums: [7]i32 = [_]i32{0} ** 7;
    var idx: usize = 0;

    var tok = std.mem.tokenizeAny(u8, input, " \n\r\t");
    while (tok.next()) |t| {
        if (idx >= nums.len) break;
        const v = std.fmt.parseInt(i32, t, 10) catch continue;
        nums[idx] = v;
        idx += 1;
    }

    if (idx >= nums.len) {
        data.games_played = nums[0];
        data.total_lines = nums[1];
        for (0..5) |i| {
            data.top_scores[i] = nums[i + 2];
        }
    }

    return data;
}

fn saveSaveData(data: *const SaveData) void {
    const cwd = std.fs.cwd();
    var file = cwd.createFile(ScoreFilePath, .{ .truncate = true }) catch return;
    defer file.close();

    var out_buf: [128]u8 = undefined;
    const line = std.fmt.bufPrint(&out_buf, "{d} {d} {d} {d} {d} {d} {d}\n", .{
        data.games_played,
        data.total_lines,
        data.top_scores[0],
        data.top_scores[1],
        data.top_scores[2],
        data.top_scores[3],
        data.top_scores[4],
    }) catch return;
    file.writeAll(line) catch {};
}

fn insertTopScore(scores: *[5]i32, score: i32) void {
    var insert_at: usize = scores.len;
    for (scores, 0..) |s, i| {
        if (score > s) {
            insert_at = i;
            break;
        }
    }

    if (insert_at == scores.len) return;

    var i: usize = scores.len - 1;
    while (i > insert_at) : (i -= 1) {
        scores[i] = scores[i - 1];
    }
    scores[insert_at] = score;
}

fn maybeSaveGameResult(game: *Game, save_data: *SaveData) void {
    if (!game.game_over or game.score_saved) return;

    save_data.games_played += 1;
    save_data.total_lines += game.lines;
    insertTopScore(&save_data.top_scores, game.score);
    saveSaveData(save_data);
    game.score_saved = true;
}

fn collides(game: *const Game, piece: Piece) bool {
    const blocks = pieceBlocks(piece);
    for (blocks) |b| {
        const x = piece.x + b.x;
        const y = piece.y + b.y;

        if (x < 0 or x >= BoardW) return true;
        if (y >= BoardH) return true;
        if (y >= 0 and game.board[@intCast(y)][@intCast(x)] != 0) return true;
    }
    return false;
}

fn movePiece(game: *Game, dx: i32, dy: i32) bool {
    var candidate = game.current;
    candidate.x += dx;
    candidate.y += dy;
    if (collides(game, candidate)) return false;
    game.current = candidate;
    return true;
}

fn rotatePiece(game: *Game) void {
    var candidate = game.current;
    candidate.rot = (candidate.rot + 1) % 4;

    const kicks = [_]i32{ 0, -1, 1, -2, 2 };
    for (kicks) |kx| {
        var try_piece = candidate;
        try_piece.x += kx;
        if (!collides(game, try_piece)) {
            game.current = try_piece;
            return;
        }
    }
}

fn lockPiece(game: *Game) void {
    const blocks = pieceBlocks(game.current);
    for (blocks) |b| {
        const x = game.current.x + b.x;
        const y = game.current.y + b.y;
        if (y >= 0 and y < BoardH and x >= 0 and x < BoardW) {
            game.board[@intCast(y)][@intCast(x)] = @intFromEnum(game.current.t) + 1;
        }
    }
}

fn findFullRows(game: *const Game, rows: *[4]i32) u8 {
    var count: u8 = 0;
    var y: i32 = BoardH - 1;
    while (y >= 0) : (y -= 1) {
        var full = true;
        for (0..BoardW) |x| {
            if (game.board[@intCast(y)][x] == 0) {
                full = false;
                break;
            }
        }
        if (full and count < rows.len) {
            rows[count] = y;
            count += 1;
        }
    }
    return count;
}

fn rowIsMarked(row: i32, rows: *const [4]i32, count: u8) bool {
    for (0..@as(usize, @intCast(count))) |i| {
        if (rows[i] == row) return true;
    }
    return false;
}

fn removeMarkedRows(game: *Game, rows: *const [4]i32, count: u8) void {
    var new_board = [_][BoardW]u8{[_]u8{0} ** BoardW} ** BoardH;

    var dst: i32 = BoardH - 1;
    var src: i32 = BoardH - 1;
    while (src >= 0) : (src -= 1) {
        if (rowIsMarked(src, rows, count)) continue;
        new_board[@intCast(dst)] = game.board[@intCast(src)];
        dst -= 1;
    }

    while (dst >= 0) : (dst -= 1) {
        new_board[@intCast(dst)] = [_]u8{0} ** BoardW;
    }

    game.board = new_board;
}

fn lineScore(lines: i32, level: i32) i32 {
    return switch (lines) {
        1 => 40 * level,
        2 => 100 * level,
        3 => 300 * level,
        4 => 1200 * level,
        else => 0,
    };
}

fn spawnNext(game: *Game) void {
    game.current = Piece{ .t = game.next, .rot = 0, .x = 4, .y = 0 };
    game.next = randomShape(game.rng.random());
    game.drop_timer = 0;

    if (collides(game, game.current)) {
        game.game_over = true;
    }
}

fn updateLevelSpeed(game: *Game) void {
    game.level = @max(1, @divTrunc(game.lines, 10) + 1);
    const speedup = @as(f32, @floatFromInt(game.level - 1)) * 0.045;
    game.fall_interval = @max(0.08, FallIntervalStart - speedup);
}

fn applyLineClear(game: *Game) void {
    if (!game.clear_anim_active) return;

    removeMarkedRows(game, &game.clearing_rows, game.clearing_count);
    const cleared: i32 = @intCast(game.clearing_count);
    game.lines += cleared;
    game.score += lineScore(cleared, game.level);
    updateLevelSpeed(game);

    game.clear_anim_active = false;
    game.clear_anim_timer = 0;
    game.clearing_count = 0;

    spawnNext(game);
}

fn resolveLock(game: *Game) void {
    lockPiece(game);
    game.clearing_count = findFullRows(game, &game.clearing_rows);
    if (game.clearing_count > 0) {
        game.clear_anim_active = true;
        game.clear_anim_timer = ClearAnimDuration;
    } else {
        spawnNext(game);
    }
}

fn initGame() Game {
    const rng = std.Random.DefaultPrng.init(@as(u64, @intCast(std.time.milliTimestamp())));
    var game = Game{
        .board = [_][BoardW]u8{[_]u8{0} ** BoardW} ** BoardH,
        .current = Piece{ .t = .I, .rot = 0, .x = 4, .y = 0 },
        .next = .I,
        .rng = rng,
        .score = 0,
        .lines = 0,
        .level = 1,
        .drop_timer = 0,
        .fall_interval = FallIntervalStart,
        .game_over = false,
        .score_saved = false,
        .paused = false,
        .clear_anim_active = false,
        .clear_anim_timer = 0,
        .clearing_rows = [_]i32{0} ** 4,
        .clearing_count = 0,
    };

    game.current.t = randomShape(game.rng.random());
    game.next = randomShape(game.rng.random());
    return game;
}

fn hardDrop(game: *Game) void {
    var drop_dist: i32 = 0;
    while (movePiece(game, 0, 1)) {
        drop_dist += 1;
    }
    game.score += drop_dist * 2;
    resolveLock(game);
}

fn stepGravity(game: *Game) void {
    if (!movePiece(game, 0, 1)) {
        resolveLock(game);
    }
}

fn cellRect(x: i32, y: i32) c.Rectangle {
    return c.Rectangle{
        .x = @floatFromInt(OffsetX + x * CellSize),
        .y = @floatFromInt(OffsetY + y * CellSize),
        .width = @floatFromInt(CellSize),
        .height = @floatFromInt(CellSize),
    };
}

fn drawCell(x: i32, y: i32, color: c.Color) void {
    const r = cellRect(x, y);
    c.DrawRectangleRec(r, color);
    c.DrawRectangleLinesEx(r, 1.0, TermDark);
}

fn drawBoard(game: *const Game) void {
    c.DrawRectangle(OffsetX - 2, OffsetY - 2, BoardW * CellSize + 4, BoardH * CellSize + 4, TermDim);
    c.DrawRectangle(OffsetX, OffsetY, BoardW * CellSize, BoardH * CellSize, c.BLACK);

    for (0..BoardH) |yy| {
        for (0..BoardW) |xx| {
            const cell = game.board[yy][xx];
            if (cell != 0) {
                drawCell(@intCast(xx), @intCast(yy), colorForCell(cell));
            } else {
                c.DrawRectangleLines(OffsetX + @as(i32, @intCast(xx)) * CellSize, OffsetY + @as(i32, @intCast(yy)) * CellSize, CellSize, CellSize, c.ColorAlpha(TermDark, 0.55));
            }
        }
    }

    if (game.clear_anim_active) {
        const alpha: f32 = if (@mod(@as(i32, @intFromFloat(game.clear_anim_timer * 1000.0)), 2) == 0)
            0.75
        else
            0.35;
        for (0..@as(usize, @intCast(game.clearing_count))) |i| {
            const row = game.clearing_rows[i];
            c.DrawRectangle(OffsetX, OffsetY + row * CellSize, BoardW * CellSize, CellSize, c.ColorAlpha(c.RAYWHITE, alpha));
        }
    }

    const blocks = pieceBlocks(game.current);
    const color = piece_defs[shapeIndex(game.current.t)].color;
    for (blocks) |b| {
        const x = game.current.x + b.x;
        const y = game.current.y + b.y;
        if (y >= 0) drawCell(x, y, color);
    }
}

fn drawSidePanel(game: *const Game, save_data: *const SaveData) void {
    const panel_x = OffsetX + BoardW * CellSize + 32;
    c.DrawText("ZTETRIS", panel_x, OffsetY, 34, TermGreen);

    var buf: [64]u8 = undefined;

    const score_txt = std.fmt.bufPrintZ(&buf, "Score: {d}", .{game.score}) catch "Score";
    c.DrawText(score_txt.ptr, panel_x, OffsetY + 64, 24, TermGreen);

    const lines_txt = std.fmt.bufPrintZ(&buf, "Lines: {d}", .{game.lines}) catch "Lines";
    c.DrawText(lines_txt.ptr, panel_x, OffsetY + 96, 24, TermGreen);

    const level_txt = std.fmt.bufPrintZ(&buf, "Level: {d}", .{game.level}) catch "Level";
    c.DrawText(level_txt.ptr, panel_x, OffsetY + 128, 24, TermGreen);

    const best_txt = std.fmt.bufPrintZ(&buf, "Best: {d}", .{save_data.top_scores[0]}) catch "Best";
    c.DrawText(best_txt.ptr, panel_x, OffsetY + 160, 24, TermGreen);

    c.DrawText("NEXT", panel_x, OffsetY + 206, 24, TermGreen);
    const next_blocks = piece_defs[shapeIndex(game.next)].blocks[0];
    const next_color = piece_defs[shapeIndex(game.next)].color;

    for (next_blocks) |b| {
        const px = panel_x + 28 + b.x * (CellSize / 2);
        const py = OffsetY + 258 + b.y * (CellSize / 2);
        c.DrawRectangle(px, py, CellSize / 2, CellSize / 2, next_color);
        c.DrawRectangleLines(px, py, CellSize / 2, CellSize / 2, TermDark);
    }

    c.DrawText("A/D : MOVE", panel_x, OffsetY + 350, 20, TermDim);
    c.DrawText("S   : DROP", panel_x, OffsetY + 376, 20, TermDim);
    c.DrawText("W   : ROT", panel_x, OffsetY + 402, 20, TermDim);
    c.DrawText("SPC : HARD", panel_x, OffsetY + 428, 20, TermDim);
    c.DrawText("R   : RESET", panel_x, OffsetY + 454, 20, TermDim);
    c.DrawText("P   : PAUSE", panel_x, OffsetY + 480, 20, TermDim);
    c.DrawText("M   : MENU", panel_x, OffsetY + 506, 20, TermDim);

    if (game.game_over) {
        c.DrawRectangle(OffsetX + 18, OffsetY + 250, BoardW * CellSize - 36, 110, c.ColorAlpha(c.BLACK, 0.8));
        c.DrawText("GAME OVER", OffsetX + 52, OffsetY + 270, 36, TermGreen);
        c.DrawText("R: RESTART", OffsetX + 94, OffsetY + 314, 20, TermGreen);
        c.DrawText("M: MENU", OffsetX + 112, OffsetY + 338, 20, TermGreen);
    } else if (game.paused) {
        c.DrawRectangle(OffsetX + 18, OffsetY + 250, BoardW * CellSize - 36, 110, c.ColorAlpha(c.BLACK, 0.82));
        c.DrawText("PAUSED", OffsetX + 94, OffsetY + 272, 38, TermGreen);
        c.DrawText("P: RESUME", OffsetX + 96, OffsetY + 318, 22, TermGreen);
    }
}

fn drawAsciiTitle(base_x: i32, base_y: i32, color: c.Color) void {
    const lines = [_][*:0]const u8{
        "ZZZZZZ  TTTTTT  EEEEEE  TTTTTT  RRRRR   IIIIII   SSSSS ",
        "    ZZ    TT    EE        TT    RR  RR    II    SS     ",
        "   ZZ     TT    EEEEE     TT    RRRRR     II     SSSS  ",
        "  ZZ      TT    EE        TT    RR  RR    II        SS ",
        "ZZZZZZ    TT    EEEEEE    TT    RR   RR IIIIII  SSSSS  ",
    };
    const font = c.GetFontDefault();
    const font_size: f32 = 17;
    const char_step: i32 = 9;
    for (lines, 0..) |line, i| {
        const row_y = base_y + @as(i32, @intCast(i)) * 24;
        const text = std.mem.span(line);
        for (text, 0..) |ch, col| {
            if (ch == ' ') continue;
            c.DrawTextCodepoint(
                font,
                @as(i32, ch),
                c.Vector2{
                    .x = @floatFromInt(base_x + @as(i32, @intCast(col)) * char_step),
                    .y = @floatFromInt(row_y),
                },
                font_size,
                color,
            );
        }
    }
}

fn drawMenu(menu_idx: i32, save_data: *const SaveData) void {
    const options = [_][*:0]const u8{ "Start Game", "Scores", "Quit" };

    drawAsciiTitle(54, 78, TermGreen);

    for (options, 0..) |opt, i| {
        const selected = menu_idx == @as(i32, @intCast(i));
        const color = if (selected) TermGreen else TermDim;
        const marker: [*:0]const u8 = if (selected) ">" else ".";
        const y = 290 + @as(i32, @intCast(i)) * 52;
        c.DrawText(marker, 160, y, 34, color);
        c.DrawText(opt, 196, y, 34, color);
    }

    var stats_buf: [80]u8 = undefined;
    const best = std.fmt.bufPrintZ(&stats_buf, "Best score: {d}", .{save_data.top_scores[0]}) catch "";
    c.DrawText(best.ptr, 180, 500, 28, TermGreen);

    const games = std.fmt.bufPrintZ(&stats_buf, "Games played: {d}", .{save_data.games_played}) catch "";
    c.DrawText(games.ptr, 180, 534, 24, TermDim);

    c.DrawText("UP/DOWN SELECT  ENTER CONFIRM", 110, 640, 22, TermDim);
}

fn drawScores(save_data: *const SaveData) void {
    c.DrawText("ZTETRIS :: HIGH SCORES", 96, 90, 42, TermGreen);

    for (0..save_data.top_scores.len) |i| {
        var line_buf: [64]u8 = undefined;
        const line = std.fmt.bufPrintZ(&line_buf, "{d}. {d}", .{ i + 1, save_data.top_scores[i] }) catch "";
        c.DrawText(line.ptr, 220, 200 + @as(i32, @intCast(i)) * 52, 36, TermGreen);
    }

    var stats_buf: [80]u8 = undefined;
    const total_lines = std.fmt.bufPrintZ(&stats_buf, "Total lines cleared: {d}", .{save_data.total_lines}) catch "";
    c.DrawText(total_lines.ptr, 150, 510, 28, TermGreen);

    const played = std.fmt.bufPrintZ(&stats_buf, "Games played: {d}", .{save_data.games_played}) catch "";
    c.DrawText(played.ptr, 190, 548, 26, TermDim);

    c.DrawText("M: BACK TO MENU", 176, 640, 24, TermDim);
}

pub fn main() !void {
    const screen_w = 560;
    const screen_h = 730;

    c.InitWindow(screen_w, screen_h, "Zig Tetris");
    defer c.CloseWindow();
    c.SetTargetFPS(60);

    var save_data = loadSaveData();
    var game = initGame();
    var scene: Scene = .Menu;
    var menu_idx: i32 = 0;

    var running = true;
    while (running and !c.WindowShouldClose()) {
        const dt: f32 = c.GetFrameTime();

        switch (scene) {
            .Menu => {
                if (c.IsKeyPressed(c.KEY_UP)) {
                    menu_idx = @max(0, menu_idx - 1);
                }
                if (c.IsKeyPressed(c.KEY_DOWN)) {
                    menu_idx = @min(2, menu_idx + 1);
                }

                if (c.IsKeyPressed(c.KEY_ENTER)) {
                    switch (menu_idx) {
                        0 => {
                            game = initGame();
                            spawnNext(&game);
                            scene = .Playing;
                        },
                        1 => scene = .Scores,
                        2 => running = false,
                        else => {},
                    }
                }
            },
            .Scores => {
                if (c.IsKeyPressed(c.KEY_M) or c.IsKeyPressed(c.KEY_BACKSPACE)) {
                    scene = .Menu;
                }
            },
            .Playing => {
                if (c.IsKeyPressed(c.KEY_M)) {
                    scene = .Menu;
                }

                if (c.IsKeyPressed(c.KEY_R)) {
                    game = initGame();
                    spawnNext(&game);
                }

                if (c.IsKeyPressed(c.KEY_P) and !game.game_over) {
                    game.paused = !game.paused;
                }

                if (!game.game_over and !game.paused) {
                    if (game.clear_anim_active) {
                        game.clear_anim_timer -= dt;
                        if (game.clear_anim_timer <= 0) {
                            applyLineClear(&game);
                        }
                    } else {
                        if (c.IsKeyPressed(c.KEY_A) or c.IsKeyPressed(c.KEY_LEFT)) {
                            _ = movePiece(&game, -1, 0);
                        }
                        if (c.IsKeyPressed(c.KEY_D) or c.IsKeyPressed(c.KEY_RIGHT)) {
                            _ = movePiece(&game, 1, 0);
                        }
                        if (c.IsKeyPressed(c.KEY_W) or c.IsKeyPressed(c.KEY_UP)) {
                            rotatePiece(&game);
                        }
                        if (c.IsKeyPressed(c.KEY_SPACE)) {
                            hardDrop(&game);
                        }

                        if (c.IsKeyDown(c.KEY_S) or c.IsKeyDown(c.KEY_DOWN)) {
                            game.drop_timer += dt * 18.0;
                            game.score += 1;
                        } else {
                            game.drop_timer += dt;
                        }

                        while (game.drop_timer >= game.fall_interval and !game.game_over and !game.clear_anim_active) {
                            game.drop_timer -= game.fall_interval;
                            stepGravity(&game);
                        }
                    }
                }

                maybeSaveGameResult(&game, &save_data);
            },
        }

        c.BeginDrawing();
        defer c.EndDrawing();

        c.ClearBackground(BgColor);

        switch (scene) {
            .Menu => drawMenu(menu_idx, &save_data),
            .Scores => drawScores(&save_data),
            .Playing => {
                drawBoard(&game);
                drawSidePanel(&game, &save_data);
            },
        }
    }
}
