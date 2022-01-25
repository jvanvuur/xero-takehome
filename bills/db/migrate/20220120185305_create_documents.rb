class CreateDocuments < ActiveRecord::Migration[7.0]
  def change
    create_table :documents do |t|
      t.string :uploaded_by
      t.string :vendor
      t.datetime :invoice_date
      t.decimal :amount
      t.decimal :amount_due
      t.string :currency
      t.decimal :tax
      t.integer :status

      t.timestamps
    end
  end
end
