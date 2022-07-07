# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20220707125827) do

  create_table "circos_images", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3" do |t|
    t.string   "file_uid"
    t.string   "file_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "job_id"
    t.string   "chromosome"
    t.index ["job_id"], name: "index_circos_images_on_job_id", using: :btree
  end

  create_table "clusters", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3" do |t|
    t.integer "job_id",     null: false
    t.string  "cluster_id"
    t.index ["job_id"], name: "index_clusters_on_job_id", using: :btree
  end

  create_table "clusters_genes", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3" do |t|
    t.integer "gene_id",    null: false
    t.integer "cluster_id", null: false
    t.index ["cluster_id"], name: "index_clusters_genes_on_cluster_id", using: :btree
    t.index ["gene_id"], name: "index_clusters_genes_on_gene_id", using: :btree
  end

  create_table "clusters_trees", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3" do |t|
    t.integer "cluster_id", null: false
    t.integer "tree_id",    null: false
    t.index ["cluster_id"], name: "index_clusters_trees_on_cluster_id", using: :btree
    t.index ["tree_id"], name: "index_clusters_trees_on_tree_id", using: :btree
  end

  create_table "file_types", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3" do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "genes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3" do |t|
    t.string  "gene_id",                 null: false
    t.integer "loc_start",               null: false
    t.integer "loc_end",                 null: false
    t.integer "job_id"
    t.text    "product",   limit: 65535, null: false
    t.string  "strand",                  null: false
    t.string  "seqid"
    t.string  "gtype"
    t.string  "species"
    t.integer "tree_id"
    t.string  "section"
    t.index ["gene_id"], name: "index_genes_on_gene_id", using: :btree
    t.index ["job_id"], name: "index_genes_on_job_id", using: :btree
  end

  create_table "genes_jobs", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3" do |t|
    t.integer "gene_id", null: false
    t.integer "job_id",  null: false
    t.index ["gene_id"], name: "index_genes_jobs_on_gene_id", using: :btree
    t.index ["job_id"], name: "index_genes_jobs_on_job_id", using: :btree
  end

  create_table "genes_trees", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3" do |t|
    t.integer "gene_id", null: false
    t.integer "tree_id", null: false
    t.index ["gene_id"], name: "index_genes_trees_on_gene_id", using: :btree
    t.index ["tree_id"], name: "index_genes_trees_on_tree_id", using: :btree
  end

  create_table "genome_stats", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3" do |t|
    t.integer  "nof_regions"
    t.integer  "overall_length"
    t.decimal  "gc_overall",                    precision: 10, scale: 2
    t.decimal  "gc_coding",                     precision: 10, scale: 2
    t.integer  "nof_genes"
    t.decimal  "gene_density",                  precision: 10, scale: 2
    t.decimal  "avg_coding_length",             precision: 10, scale: 2
    t.integer  "nof_coding_genes"
    t.integer  "nof_genes_with_mult_cds"
    t.integer  "nof_genes_with_function"
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
    t.integer  "job_id"
    t.integer  "nof_pseudogenes"
    t.integer  "nof_pseudogenes_with_function"
    t.index ["job_id"], name: "index_genome_stats_on_job_id", using: :btree
  end

  create_table "jobs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3" do |t|
    t.string   "name"
    t.string   "job_id"
    t.datetime "started_at"
    t.string   "status"
    t.datetime "finished_at"
    t.datetime "created_at",                                                      null: false
    t.datetime "updated_at",                                                      null: false
    t.integer  "user_id"
    t.string   "path"
    t.boolean  "do_contiguate"
    t.boolean  "do_exonerate"
    t.boolean  "do_ratt"
    t.integer  "max_gene_length"
    t.decimal  "augustus_score_threshold",               precision: 10, scale: 2
    t.integer  "taxon_id"
    t.string   "db_id"
    t.integer  "reference_id"
    t.string   "prefix"
    t.string   "ratt_transfer_type"
    t.string   "config_file"
    t.text     "stdout",                   limit: 65535
    t.text     "stderr",                   limit: 65535
    t.integer  "genome_stat_id"
    t.boolean  "no_resume"
    t.integer  "tree_id"
    t.integer  "sequence_file_id"
    t.integer  "transcript_file_id"
    t.boolean  "use_transcriptome_data"
    t.boolean  "do_pseudo"
    t.string   "email"
    t.string   "organism"
    t.integer  "abacas_match_size"
    t.integer  "abacas_match_sim"
    t.index ["tree_id"], name: "fk_rails_0e6111546c", using: :btree
    t.index ["user_id"], name: "index_jobs_on_user_id", using: :btree
  end

  create_table "result_files", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3" do |t|
    t.string   "file_uid"
    t.string   "file_name"
    t.integer  "job_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "md5"
    t.index ["job_id"], name: "index_result_files_on_job_id", using: :btree
  end

  create_table "simple_captcha_data", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3" do |t|
    t.string   "key",        limit: 40
    t.string   "value",      limit: 6
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["key"], name: "idx_key", using: :btree
  end

  create_table "trees", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3" do |t|
    t.string  "seq_uid"
    t.string  "seq_name"
    t.integer "job_id"
    t.index ["job_id"], name: "index_trees_on_job_id", using: :btree
  end

  create_table "user_files", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3" do |t|
    t.string   "name"
    t.integer  "file_type_id"
    t.integer  "user_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "file_uid"
    t.string   "file_name"
    t.string   "type"
    t.integer  "job_id"
    t.index ["id", "type"], name: "index_user_files_on_id_and_type", using: :btree
    t.index ["job_id"], name: "index_user_files_on_job_id", using: :btree
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3" do |t|
    t.string   "name"
    t.string   "fullname"
    t.string   "institution"
    t.string   "email"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "password_digest"
    t.string   "remember_digest"
  end

  add_foreign_key "clusters", "jobs"
  add_foreign_key "jobs", "trees"
  add_foreign_key "trees", "jobs"
end
