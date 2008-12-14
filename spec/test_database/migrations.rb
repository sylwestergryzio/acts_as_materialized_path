class CreateHierarchy < ActiveRecord::Migration
  def self.up
    create_table :hierarchies do |t|
      t.string :name, :position
      t.text :path_string
    end
  end

  def self.down
    drop_table :hierarchies
  end
end


class InsertIntoHierarchy < ActiveRecord::Migration
  
  def self.up
    (1..3).each do |i|
      boss = Hierarchy.create_root(:name => "Boss of company #{i}", :position => "Boss")
      (1..2).each do |j|
        employee = Hierarchy.create_root(:name => "Employee #{j} of company #{i}", :position => "Subordinate of #{boss.name}")
        employee.move_to_child_of(boss)
        secretary = Hierarchy.create_root(:name => "Secretary #{j} of company #{i}", :position => "Secretary of #{employee.name}")
        secretary.move_to_child_of(employee)
      end
    end
  end

  def self.down
    Hierarchy.delete_all 
  end
end