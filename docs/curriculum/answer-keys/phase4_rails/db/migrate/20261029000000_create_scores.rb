# frozen_string_literal: true

class CreateScores < ActiveRecord::Migration[8.1]
  def change
    create_table :scores do |t|
      t.string :player_name, null: false
      t.integer :points, null: false
      t.integer :hits, null: false
      t.integer :misses, null: false
      t.timestamps
    end
  end
end
