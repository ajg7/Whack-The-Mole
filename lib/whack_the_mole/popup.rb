# frozen_string_literal: true

module WhackTheMole
  Popup = Data.define(:x, :y, :started_at) do
    def progress(now)
      ((now - started_at).to_f / Config::POPUP_MS).clamp(0.0, 1.0)
    end

    def offset(now)
      -Config::POPUP_RISE * progress(now)
    end

    def alpha(now)
      (255 * (1.0 - progress(now))).round
    end

    def expired?(now)
      now - started_at >= Config::POPUP_MS
    end
  end
end
