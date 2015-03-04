# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20150303100946) do

  create_table "file_types", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "jobs", force: :cascade do |t|
    t.string   "name"
    t.string   "job_id"
    t.datetime "started_at"
    t.string   "status"
    t.datetime "finished_at"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.integer  "user_id"
    t.string   "path"
    t.integer  "user_file_id"
    t.boolean  "do_contiguate"
    t.boolean  "do_exonerate"
    t.boolean  "do_ratt"
    t.integer  "max_gene_length"
    t.decimal  "augustus_score_threshold"
    t.integer  "taxon_id"
    t.string   "db_id"
    t.integer  "reference_id"
    t.string   "prefix"
    t.string   "ratt_transfer_type"
    t.string   "config_file"
    t.text     "stdout"
    t.text     "stderr"
  end

  create_table "user_files", force: :cascade do |t|
    t.string   "name"
    t.integer  "file_type_id"
    t.integer  "user_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "file_uid"
    t.string   "file_name"
  end

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.string   "fullname"
    t.string   "institution"
    t.string   "email"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "password_digest"
  end

end
