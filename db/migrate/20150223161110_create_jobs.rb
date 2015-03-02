class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.string :name
      t.string :job_id
      t.datetime :started_at
      t.string :status
      t.datetime :finished_at

      t.timestamps null: false
    end
  end
end
