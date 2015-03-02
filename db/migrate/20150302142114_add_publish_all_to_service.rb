class AddPublishAllToService < ActiveRecord::Migration

  def up
    add_column :services, :publish_all, :boolean, default: true
  end

  def down
    remove_column :services, :publish_all
  end

end
