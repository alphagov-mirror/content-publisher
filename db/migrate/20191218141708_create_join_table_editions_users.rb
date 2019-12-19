class CreateJoinTableEditionsUsers < ActiveRecord::Migration[6.0]
  def change
    create_join_table :editions, :users do |t|
      t.index %I[edition_id user_id], unique: true
    end
  end
end
