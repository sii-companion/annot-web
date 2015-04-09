class AddGeneColumns < ActiveRecord::Migration
  def change
    add_column :genes, :seqid, :string
    add_column :genes, :gtype, :string
  end
end
