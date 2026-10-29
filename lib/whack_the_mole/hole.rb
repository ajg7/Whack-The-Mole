# frozen_string_literal: true

module WhackTheMole
  Hole = Data.define(:x, :y) do
    def self.grid(cols: Config::GRID_COLS, rows: Config::GRID_ROWS)
      (0...rows).to_a.product((0...cols).to_a).map do |row, col|
        new(x: Config::GRID_LEFT + (Config::CELL_SIZE * (col + 0.5)).to_i,
            y: Config::GRID_TOP + (Config::CELL_SIZE * (row + 0.5)).to_i)
      end
    end
  end
end
