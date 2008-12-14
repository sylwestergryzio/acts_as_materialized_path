require File.dirname(__FILE__) + '/spec_helper.rb'


# test 1
describe Hierarchy do
  before(:all) do
    @class_methods = [
      :acts_as_materialized_path, :create_root, :root, :roots, :sort,
      :sort_by_path_column, :sort_by_path_column!
    ]
    @instance_methods = [
      :add_child, :add_to_tree, :ancestors, :build_tree, :child?, :children,
      :children_count, :children_list, :children_list=, :descendants, :destroy_descendants,
      :find_parent, :full_set, :level, :move_to_child_of, :parent, :root, :root?,
      :save_as_root, :self_and_ancestors, :self_and_siblings, :siblings, :sort_list_by
    ]
    CreateHierarchy.migrate(:up)
    @hierarchy = Hierarchy.new
  end
  
  it "class should respond to class methods" do
    @class_methods.each do |method|
      Hierarchy.should respond_to(method)
    end
  end

  it "instance should respond to instance_methods" do
    @instance_methods.each do |method|
      @hierarchy.should respond_to(method)
    end
  end
  
  after(:all) do
    CreateHierarchy.migrate(:down)
  end
end


# test 2
describe Hierarchy, "with migrated data" do
  
  before(:all) do
    CreateHierarchy.migrate(:up)
    InsertIntoHierarchy.migrate(:up)
  end
  
  it "should have three roots at the beginning" do 
    Hierarchy.should have(3).roots
  end
  
  # boss of company 3 now have three subordinates
  it "should be able to insert a new node" do
    boss_of_company_3 = Hierarchy.find_by_name("Boss of company 3")
    employee = Hierarchy.new(:name => "Employee 3 of company 3", :position => "Subordinate of #{boss_of_company_3.name}")
    employee.move_to_child_of(boss_of_company_3)
    boss_of_company_3.should have(3).children
    boss_of_company_3.children.should include(employee)
  end
  
  # there are 4 companies now
  it "should be able to create a new root" do
    new_boss = Hierarchy.create_root(:name => "Boss of company 4", :position => "Boss")
    new_boss.root?.should be_true
  end
  
  it "should be able to find ancestors of a given node" do
    secretary_1_of_company_1 = Hierarchy.find_by_name("Secretary 1 of company 1")
    secretary_1_of_company_1.ancestors.should include(Hierarchy.find_by_name("Employee 1 of company 1"))
    secretary_1_of_company_1.ancestors.should include(Hierarchy.find_by_name("Boss of company 1"))
  end
  
  it "should be able to find descendants of a given node" do
    boss_of_company_1 = Hierarchy.find_by_name("Boss of company 1")
    boss_of_company_1.should have(4).descendants
    boss_of_company_1.descendants.should include(Hierarchy.find_by_name("Employee 1 of company 1"))
    boss_of_company_1.descendants.should include(Hierarchy.find_by_name("Secretary 1 of company 1"))
    boss_of_company_1.descendants.should include(Hierarchy.find_by_name("Employee 2 of company 1"))
    boss_of_company_1.descendants.should include(Hierarchy.find_by_name("Secretary 2 of company 1"))
  end
  
  it "should be able to find and sort children of a given node" do
    boss_of_company_3 = Hierarchy.find_by_name("Boss of company 3")
    boss_of_company_3.children(:order_dir => "desc").first.should eql(Hierarchy.find_by_name("Employee 3 of company 3"))
    boss_of_company_3.children(:order_dir => "desc").last.should eql(Hierarchy.find_by_name("Employee 1 of company 3"))
    boss_of_company_3.children.first.should eql(Hierarchy.find_by_name("Employee 1 of company 3"))
  end
  
  it "should be able to find parent of a given node" do
    Hierarchy.find_by_name("Secretary 1 of company 1").parent.should eql(Hierarchy.find_by_name("Employee 1 of company 1"))
  end
  
  it "should be able to find siblings of a given node" do
    Hierarchy.find_by_name("Secretary 1 of company 1").siblings.should be_empty
    Hierarchy.find_by_name("Employee 3 of company 3").should have(2).siblings
    Hierarchy.find_by_name("Employee 3 of company 3").siblings.should include(Hierarchy.find_by_name("Employee 1 of company 3"))
    Hierarchy.find_by_name("Employee 3 of company 3").siblings.should include(Hierarchy.find_by_name("Employee 2 of company 3"))
    Hierarchy.find_by_name("Employee 3 of company 3").siblings.should_not include(Hierarchy.find_by_name("Secretary 2 of company 3"))
  end
  
  it "should be able to tell if a node is a child" do
    Hierarchy.find_by_name("Secretary 1 of company 1").child?.should be_true
  end
  
  it "should be able to tell if a node is a root" do
    Hierarchy.find_by_name("Secretary 1 of company 1").root?.should be_false
    Hierarchy.find_by_name("Boss of company 2").root?.should be_true
  end
  
  it "should be able to tell the root of the tree" do
    Hierarchy.find_by_name("Secretary 1 of company 1").root.should eql(Hierarchy.find_by_name("Boss of company 1"))
    Hierarchy.find_by_name("Employee 2 of company 3").root.should eql(Hierarchy.find_by_name("Boss of company 3"))
  end
  
  it "should be able to tell level of a given node" do
    Hierarchy.find_by_name("Boss of company 3").level.should == 0
    Hierarchy.find_by_name("Employee 1 of company 1").level.should == 1
    Hierarchy.find_by_name("Secretary 2 of company 1").level.should == 2
  end
  
  it "should be able to count children of a given node" do
    Hierarchy.find_by_name("Boss of company 1").children_count.should == 2
    Hierarchy.find_by_name("Employee 3 of company 3").children_count.should == 0
  end
  
  it "should be able to return a subtree" do
    Hierarchy.find_by_name("Employee 1 of company 1").full_set.should have(2).rows
    Hierarchy.find_by_name("Employee 1 of company 1").full_set.should include(Hierarchy.find_by_name("Employee 1 of company 1"))
    Hierarchy.find_by_name("Employee 1 of company 1").full_set.should include(Hierarchy.find_by_name("Secretary 1 of company 1"))
  end
  
  it "should be able to move nodes" do
    employee_1_of_company_1 = Hierarchy.find_by_name("Employee 1 of company 1")
    boss_of_company_2 = Hierarchy.find_by_name("Boss of company 2")
    employee_1_of_company_1.move_to_child_of(boss_of_company_2, :descendants => "include")
    boss_of_company_2.should have(6).descendants
    boss_of_company_2.descendants.should include(employee_1_of_company_1)
    boss_of_company_2.descendants.should include(employee_1_of_company_1.descendants[0])
  end
  
  after(:all) do
    CreateHierarchy.migrate(:down)
  end
  
end


# test 3
describe Hierarchy, "with nonempty set of nodes" do
  
  # these test only shows that built_tree works, but this is just a temporary structure
  # use it only for display purposes
  
  before(:all) do
    CreateHierarchy.migrate(:up)
    InsertIntoHierarchy.migrate(:up)
    @root = Hierarchy.find_by_name("Boss of company 1")
  end

  it "should be able to build a tree out of these nodes" do
    @root.build_tree
    @root.children_list.should_not be_empty
  end
  
  it "should be able to add nodes to already built tree" do
    new_employee = Hierarchy.create(:name => "Employee 3 of company 1", :position => "Subordinate of #{@root.name}")
    # the below line is required so that path_string could be filled
    new_employee.move_to_child_of(@root)
    @root.add_to_tree(@root, new_employee)
    @root.children_list.should include(new_employee)
    
    new_secretary = Hierarchy.create(:name => "Secretary 3 of company 1", :position => "Secretary of #{new_employee.name}")
    # the below line is required so that path_string could be filled
    new_secretary.move_to_child_of(new_employee)
    new_employee.children_list.should be_nil
    @root.add_to_tree(@root, new_secretary)
    new_employee.children_list.should include(new_secretary)
    new_employee.children_list.size.should == 1
  end
  
  it "should be able to add children to already built tree" do
    employee_1_of_company_1 = Hierarchy.find_by_name("Employee 1 of company 1")
    employee_1_of_company_1.build_tree
    new_secretary = Hierarchy.create(:name => "Secretary 4 of company 1", :position => "Secretary of #{employee_1_of_company_1.name}")
    employee_1_of_company_1.add_child(new_secretary)
    employee_1_of_company_1.children_list.should include(new_secretary)
    employee_1_of_company_1.children_list.size.should == 2
  end
  
  it "should be able to find a node's parent" do
    secretary_2_of_company_1= Hierarchy.find_by_name("Secretary 2 of company 1")
    employee_2_of_company_1 = Hierarchy.find_by_name("Employee 2 of company 1")
    @root.find_parent(@root.children_list, secretary_2_of_company_1).should eql(employee_2_of_company_1)
  end
  
  after(:all) do
    CreateHierarchy.migrate(:down)
  end
end