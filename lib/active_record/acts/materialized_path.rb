# Copyright (C) Sylwester Gryzio 2008. Released under the MIT licence.

module ActiveRecord #:nodoc:
  module Acts #:nodoc:
    module MaterializedPath #:nodoc:
      
      def self.included( base )
        base.extend( ClassMethods )
      end

=begin rdoc
acts_as_materialized_path is an implementation of path enumeration data model.
Such data is a tree structure.

The implementation allows to:

* Find all ancestors and descendants with a single query
* Find pranet, sibblings and children
* Insert new nodes to the structure
* Move node with or without it's descendats to different parent

Specific properties of the implementation

* The id has to be an integer

=== The data structure

A node has to have at least two columns:

* a primary key column of an integer type
* a path column of a text type


                  node1 (1, '1')
                    |
            +---------------+
            |               |
     node2 (2, '1.2')  node3 (3, '1.3')
                            |
                 +------------------------+
                 |                        |
           node4 (4, '1.3.4')      node5 (5, '1.3.5')

As shown above, each child's path column consists of
it's parent path column and it's id connected by a dot.
Root node has no dot in it's path column.

=== Compatibility

The code was tested with the following databases:
* PostgreSQL
* MySQL
* SQLite

=== Tests

Run rake -T to see the list of available tests.
* rake - runs all the tests
* rake spec - runs tests in spec directory 

=== See also

* acts_as_tree
* acts_as_nested_set
* BetterNestedSet
* acts_as_materialized_tree
=end


      module ClassMethods
        # Configuration option:
        # * +path_column+ - specifies the column name to store the path (default: +path_string+)
        #
        # Example:
        #
        #    acts_as_materialized_path (:path_column => 'path_string')
        #
        def acts_as_materialized_path (options = {})
          
          write_inheritable_attribute(:acts_as_materialized_path_options,
            { 
              :path_column => (options[:path_column]  || 'path_string' )
            })
          
          class_inheritable_reader :acts_as_materialized_path_options
          attr_protected  acts_as_materialized_path_options[:path_column].intern
          
          module_eval <<-EOV
            def #{acts_as_materialized_path_options[:path_column]}=(x)
              raise ActiveRecord::ActiveRecordError, "Unauthorized assignment to #{acts_as_materialized_path_options[:path_column]}: it's an internal field handled by acts_as_materialized_path code."
            end

          EOV
          
          include ActiveRecord::Acts::MaterializedPath::InstanceMethods
          extend ActiveRecord::Acts::MaterializedPath::ClassMethods
        end
        
        # The first root returned by roots function.
        # Order_options are:
        # * +order+ - the name of the column to sort by
        # * +order_dir+ - sort order asc or desc
        # The default options are path column and asc respectively.
        def root ( order_options = {} )
          roots = self.roots( order_options )
          if ( roots.size > 0 )
            roots[0]
          else
            nil
          end
        end
        
        # All roots in a table.
        # Order_options are:
        # * +order+ - the name of the column to sort by
        # * +order_dir+ - sort order asc or desc
        # The default options are path column and asc respectively.
        def roots ( order_options = {} )
          config = { :order => acts_as_materialized_path_options[:path_column], :order_dir => "asc"}
          config.update(order_options) if order_options.is_a?(Hash)
          
          if(config[:order] == acts_as_materialized_path_options[:path_column])
            roots = self.find(:all, :conditions => [ "#{acts_as_materialized_path_options[:path_column]} not like ?", "%.%"])
            self.sort_by_path_column!( roots, config[:order_dir] )
          else
            self.find(:all, :conditions => [ "#{acts_as_materialized_path_options[:path_column]} not like ?", "%.%"], :order => "#{config[:order]} #{config[:order_dir]}")
          end
        end

        # Creates new root in a table with path column set to it's id.
        # Parameters are as in standard ActiveRecord create method.
        def create_root ( parameters = {} )
          new_root = self.create(parameters)
          new_root[acts_as_materialized_path_options[:path_column]] = new_root.id.to_s
          new_root.save
          return new_root
        end

        # Sorts given set by path column.
        # * +to_sort+ - set to be sorted
        # * +order_dir+ - sort order asc or desc
        # to_sort parameter is replaced by the sorted set.
        def sort_by_path_column! ( to_sort, order_dir )
          to_sort.sort! { |x,y| sort(x,y, order_dir ) }
        end


        # Returns given set sorted by path column.
        # * +to_sort+ - set to be sorted
        # * +order_dir+ - sort order asc or desc
        # to_sort stays unchanged.
        def sort_by_path_column ( to_sort, order_dir )
          to_sort.sort { |x,y| sort(x,y, order_dir ) }
        end

        # Used to sort path column.
        # * +x+, +y+ - objects of a model's class
        # * +order+ - the sort order
        # Becouse of the anatomy of the path column, it can not be sorted in lexical order.
        # It has to be splitted and then each part of it has to becompared with the corresponding
        # part from another row.
        #
        # Example:
        #
        #   Consider strings 1.2 and 1.10. If sorted lexically, the result would be
        #   1.2, 1.10. Not necessarily expected result. If the order of insertions counts,
        #   it shoul be 1.2, 1.10.
        def sort ( x, y, order )
          x_path = x[acts_as_materialized_path_options[:path_column]].split(".")
          y_path = y[acts_as_materialized_path_options[:path_column]].split(".")
    
          min_size = x_path.size > y_path.size ? x_path.size : y_path.size;
          (0..min_size-1).each do |i|
            x_number = x_path[i].to_i;
            y_number = y_path[i].to_i;
            if x_number < y_number
              if order == "asc"
                return -1
              else
                return 1 
              end
            elsif x_number > y_number
              if order == "asc"
                return 1
              else
                return -1 
              end
            end
          end
          x_path.size < y_path.size ? -1 : 1;
        end
      end

      #
      # Most of te functions operate on a data in a database.
      #
      # With build_tree and sort_list_by it is possible to build a virtual tree and sort
      # the data in Ruby. Could be usefull when displaying data.
      #
      module InstanceMethods

        # Makes calling node a root.
        # Please remember to handle node's descendants.
        def save_as_root
          self[acts_as_materialized_path_options[:path_column]] = self.id.to_s
          self.save
        end

        # Destroys all descendants of a node.
        # Uses single LIKE statement.
        def destroy_descendants
          self.class.transaction do
            self.class.delete_all "#{acts_as_materialized_path_options[:path_column]} like '#{self[acts_as_materialized_path_options[:path_column]]}.%'"
            self.save
          end
        end


        # Returns the level of a node.
        # The level starts from zero and equals the number of dots in path column.
        def level
          self[acts_as_materialized_path_options[:path_column]].count(".")
        end

        # Returns all direct children of a node.
        # These are nodes that have path like node_path || '.' || child_id - that property was used in SQL select.
        # * +order+ - the name of the column to sort by
        # * +order_dir+ - sort order asc or desc
        # If path column was order column, sort_by_path_column! will be used to sort the result.
        def children ( order_options = {} )
          config = { :order => acts_as_materialized_path_options[:path_column], :order_dir => "asc"}
          config.update(order_options) if order_options.is_a?(Hash)
          if(config[:order] == acts_as_materialized_path_options[:path_column])
            children = self.class.find(:all, :conditions => [ "#{acts_as_materialized_path_options[:path_column]} like ? || id ", self[acts_as_materialized_path_options[:path_column]] + "." ])
            self.class.sort_by_path_column!(children, config[:order_dir])
          else
            self.class.find(:all, :conditions => [ "#{acts_as_materialized_path_options[:path_column]} like ? || id ", self[acts_as_materialized_path_options[:path_column]] + "." ], :order => "#{config[:order]} #{config[:order_dir]}")
          end
        end

        # Returns all descendants of a node.
        # These are nodes that have path like node_path || '.%'.
        # * +order+ - the name of the column to sort by
        # * +order_dir+ - sort order asc or desc
        # If path column was order column, sort_by_path_column! will be used to sort the result.
        def descendants ( order_options = {} )
          config = { :order => acts_as_materialized_path_options[:path_column], :order_dir => "asc"}
          config.update(order_options) if order_options.is_a?(Hash)
          if( config.has_value?(acts_as_materialized_path_options[:path_column]) )
            descendants = self.class.find(:all, :conditions => [ "#{acts_as_materialized_path_options[:path_column]} like ?", self[acts_as_materialized_path_options[:path_column]] + ".%" ] )
            self.class.sort_by_path_column!(descendants, config[:order_dir])
          else
            self.class.find(:all, :conditions => [ "#{acts_as_materialized_path_options[:path_column]} like ?", self[acts_as_materialized_path_options[:path_column]] + ".%" ], :order => "#{config[:order]} #{config[:order_dir]}" )
          end
        end

        # Get parent of a node.
        def parent
          if(self.root?)
            nil
          else
            self_and_ancestors_ids = self[acts_as_materialized_path_options[:path_column]].split(".");
            self.class.find_by_id( self_and_ancestors_ids[self_and_ancestors_ids.length - 2].to_i );
          end
        end

        # Returns all nodes on a route from a node to the root (including both).
        # A list of ancestors' ids is built and passed to a single SQL select.
        #
        # NOTE: id of a node is in the list as well.
        def self_and_ancestors
          self_and_ancestors_ids = self[acts_as_materialized_path_options[:path_column]].split(".");
          self.class.find(:all, :conditions => [ " id in (#{self_and_ancestors_ids.join(', ')})" ] );
        end

        # Returns all ancestors of a node.
        def ancestors
          self_and_ancestors - [self]
        end

        # Returns all sibblings of a node and itself.
        # These are all children of a node's parent.
        def self_and_siblings ( order_options = {} )
          self.parent.children(order_options)
        end

        # An array of all sibblings of a node.
        def siblings ( order_options = {} )
          self_and_siblings(order_options) - [self]
        end

        # The whole subtree rooted in the node.
        def full_set ( order_options = {} )
          [self] + descendants(order_options)
        end

        # The number of node's children.
        def children_count
          self.class.count :conditions => [ "#{acts_as_materialized_path_options[:path_column]} like ? || id ", self[acts_as_materialized_path_options[:path_column]] + "." ]
        end

        # Makes a node a child of a parent node that is passed to the function.
        # * +parent+ - the parent node
        # * +descendants+ - determines if to move node's descendants together with the node or not - include or exclude respectively
        # The defult option is exclude, which means do nothing - leave the decision to the programmer.
        def move_to_child_of( parent, options = {} )
          if(self.id == nil)
            self.save
          else
            self.reload
          end
          parent.reload
          options.default = "exclude"
          # get all descendants
          self.class.transaction do
            prev_path_string = self[acts_as_materialized_path_options[:path_column]]
            # move the node to new parent
            self[acts_as_materialized_path_options[:path_column]] = parent[acts_as_materialized_path_options[:path_column]] + "." + id.to_s
            if (options[:descendants] == "include")
              #update all descendants with new path_string of their parent
              self.class.update_all("#{acts_as_materialized_path_options[:path_column]} = '#{self[acts_as_materialized_path_options[:path_column]]}' || substr(#{acts_as_materialized_path_options[:path_column]}, #{prev_path_string.length+1})",
                "#{acts_as_materialized_path_options[:path_column]} like '#{prev_path_string}.%'")
            end
          end
          return self.save
        end

        # The root of a tree that a node belongs to.
        def root
          self.root? ? self : self.class.find_by_id(self[acts_as_materialized_path_options[:path_column]].split(/\./)[0])
        end

        # Returns +true+ if a node is a root of some tree.
        def root?
          self[acts_as_materialized_path_options[:path_column]] !~ /\./ ? true : false
        end

        # Returns +true+ if a node has a parent.
        def child?
          child_regex = Regexp.new("\\.#{id}$")
          self[acts_as_materialized_path_options[:path_column]] =~ child_regex ? true : false
        end


        # Used to store children list when building a virtual tree structure.
        def children_list=(x)
          @children_list = x
        end

        # Used to store children list when building a virtual tree structure.
        def children_list
          return @children_list
        end

        # Adds a child to a parent node in a virtual tree.
        # * +element+ - a child node to be added
        def add_child(element)
          if(self.children_list == nil)
            self.children_list = []
          end
          self.children_list.push(element)
        end

        # Finds the parent suitable for a given child node.
        # * +children_list+ - parent nodes to look among
        # * +child+ - a child node without a parent
        # This is an iterative function.
        def find_parent(children_list, child)
          
          children_list.each do |parent_candidate|
            parent_path = parent_candidate[acts_as_materialized_path_options[:path_column]]
            
            if(parent_candidate.level == child.level - 1 && child[acts_as_materialized_path_options[:path_column]].to_s.match("^"+parent_path+"\\."))
              return parent_candidate;
            elsif(child[acts_as_materialized_path_options[:path_column]].to_s.match("^"+parent_path+"\\."))
              return find_parent(parent_candidate.children_list, child)
            end
          end
          return nil;
        end

        # Adds a node to a virtual tree rooted in root.
        # * +root+ - a root node of the virtual tree
        # * +element+ - a node to be added
        def add_to_tree(root, element)
          if( root.level == element.level - 1 )
            root.add_child(element);
          else
            # look for parent candidate
            # element.level == parent.level+1 && element.path.contains(parent.path);
            parent = find_parent(root.children_list, element);
            parent.add_child(element);
          end
        end

        # Builds a virtual tree.
        def build_tree
          descendants_list = self.descendants
          descendants_list.each do |descendant|
            self.add_to_tree(self, descendant)
          end
        end

        # Sorts a set of nodes.
        # * +list+ - a set of nodes to sort
        # * +sort_column+ - a column to sort by
        # * +sort_order+ - a sort order
        def sort_list_by(list, sort_column, sort_order)
          
          if(sort_column == acts_as_materialized_path_options[:path_column])
            return self.class.sort_by_path_column(list, sort_order)
          end
          
          if(self[sort_column].is_a?(String))
            return list.sort { | a, b| sort_order == "asc" ? a[sort_column].casecmp(b[sort_column]) : b[sort_column].casecmp(a[sort_column]) }
          else
            return list.sort { |a,b| sort_order == "asc" ? a[sort_column] <=> b[sort_column] : b[sort_column] <=> a[sort_column] }
          end
        end
        
      end
    end
  end
end
