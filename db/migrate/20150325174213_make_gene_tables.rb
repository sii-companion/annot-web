class MakeGeneTables < ActiveRecord::Migration
  def change
    create_table :genes do |t|
      t.string :gene_id, index: true, null: false
      t.integer :loc_start, null: false
      t.integer :loc_end, null: false
      t.integer :job_id, index: true
      t.string :product, null: false
      t.string :strand, null: false
    end
    create_table :clusters do |t|
      t.integer :job_id, index: true, null: false
      t.string :cluster_id
    end
    create_table :trees do |t|
      t.string :seq_uid
      t.string :seq_name
      t.integer :job_id
    end
    add_column :jobs, :tree_id, :integer
    add_foreign_key :clusters, :jobs
    add_foreign_key :trees, :jobs
    add_foreign_key :jobs, :trees
    create_join_table :genes, :jobs do |t|
      t.index :gene_id
      t.index :job_id
    end
    create_join_table :genes, :clusters do |t|
      t.index :gene_id
      t.index :cluster_id
    end
    create_join_table :genes, :trees do |t|
      t.index :gene_id
      t.index :tree_id
    end
    create_join_table :clusters, :trees do |t|
      t.index :cluster_id
      t.index :tree_id
    end
  end
end
