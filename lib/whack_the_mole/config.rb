# frozen_string_literal: true

module WhackTheMole
  module Config
    WIDTH = 640
    HEIGHT = 720
    GRASS_COLOR = 0xff_4caf50
    HOLE_COLOR = 0xff_4e342e
    TEXT_COLOR = 0xff_ffffff

    GRID_COLS = 3
    GRID_ROWS = 3
    CELL_SIZE = 192
    GRID_LEFT = (WIDTH - (GRID_COLS * CELL_SIZE)) / 2
    GRID_TOP = 120
    HOLE_WIDTH = 150
    HOLE_HEIGHT = 50

    SPRITE_SIZE = 36
    SCALE = 4
    DRAWN_SIZE = SPRITE_SIZE * SCALE
    SPRITE_ABOVE_HOLE = 80
    HIT_LEFT = 10 * SCALE
    HIT_TOP = 4 * SCALE
    HIT_WIDTH = 12 * SCALE
    HIT_HEIGHT = 19 * SCALE

    ROUND_MS = 60_000
    COUNTDOWN_MS = 3_000
    GAME_OVER_LOCKOUT_MS = 1_000
    MAX_MOLES = 2
    SPAWN_INTERVAL_MS = 500
    UP_MS_START = 1200
    UP_MS_END = 600
    RISE_FRAME_MS = 80
    DROP_FRAME_MS = 40
    SWING_FRAME_MS = 50

    HAMMER_HEAD_OFFSET = [-24, -28].freeze

    POPUP_MS = 600
    POPUP_RISE = 40
    MISS_SPEED = 0.7

    ASSETS_DIR = File.expand_path('../../assets', __dir__)
  end
end
