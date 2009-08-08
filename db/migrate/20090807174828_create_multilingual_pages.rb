class CreateMultilingualPages < ActiveRecord::Migration
  def self.up
    add_column :pages, :multilingual_slugs, :string
    add_index :pages, [:class_name, :multilingual_slugs, :parent_id]
  end

  def self.down
    remove_column :pages, :multilingual_slugs
  end
end
