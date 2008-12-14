module ActiveRecord
  module Acts
    module MaterializedPath
      
      def self.included( base )
        base.extend( ClassMethods )
      end
      
      module ClassMethods
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
        
        # first root out of sorted set
        def root ( sort_order = "asc" )
          roots = self.roots( sort_order )
          if ( roots.size > 0 )
            roots[0]
          else
            nil
          end
        end
        
        # set ordered by given :order argument
        def roots ( sort_order = "asc" )
          roots = self.find(:all, :conditions => [ "#{acts_as_materialized_path_options[:path_column]} not like ?", "%.%"])
          self.sort_by_path_column!( roots, sort_order )
        end
        
        def create_root ( parameters = {} )
          new_root = self.create(parameters)
          new_root[acts_as_materialized_path_options[:path_column]] = new_root.id.to_s
          new_root.save
          return new_root
        end
        
        def sort_by_path_column! ( to_sort, sort_order )
          to_sort.sort! { |x,y| sort(x,y, sort_order ) }
        end
        
        def sort_by_path_column ( to_sort, sort_order )
          to_sort.sort { |x,y| sort(x,y, sort_order ) }
        end
        
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
      
      module InstanceMethods

        def save_as_root
          self[acts_as_materialized_path_options[:path_column]] = self.id.to_s
          self.save
        end
        
        # remember to put dot in the like statement
        # e.g. 1.2.4.11 and 1.2.44.22 and 1.2.4 was destroyed 
        # 1.2.44 and all it's descendants will be destroyed 
        # as well if there is no dot in the like statement
        def destroy_descendants
          self.class.transaction do
            self.class.delete_all "#{acts_as_materialized_path_options[:path_column]} like '#{self[acts_as_materialized_path_options[:path_column]]}.%'"
            self.save
          end
        end
        
        def level
          self[acts_as_materialized_path_options[:path_column]].count(".")
        end
        
        def children ( sort_order = "asc" )
          children = self.class.find(:all, :conditions => [ "#{acts_as_materialized_path_options[:path_column]} like ? || id ", self[acts_as_materialized_path_options[:path_column]] + "." ])
          self.class.sort_by_path_column!(children, sort_order)
        end
        
        def descendants ( sort_order = "asc" )
          descendants = self.class.find(:all, :conditions => [ "#{acts_as_materialized_path_options[:path_column]} like ?", self[acts_as_materialized_path_options[:path_column]] + ".%" ] )
          self.class.sort_by_path_column!(descendants, sort_order)
        end
        
        def parent
          if(self.root?)
            nil
          else
            self_and_ancestors_ids = self[acts_as_materialized_path_options[:path_column]].split(".");
            self.class.find_by_id( self_and_ancestors_ids[self_and_ancestors_ids.length - 2].to_i );
          end
        end
        
        def self_and_ancestors
          self_and_ancestors_ids = self[acts_as_materialized_path_options[:path_column]].split(".");
          self.class.find(:all, :conditions => [ " id in (#{self_and_ancestors_ids.join(', ')})" ] );
        end
        
        def ancestors
          self_and_ancestors - [self]
        end
        
        def self_and_siblings ( sort_order = "asc" )
          self.parent.children(sort_order)
        end
        
        def siblings ( sort_order = "asc" )
          self_and_siblings(sort_order) - [self]
        end
        
        def full_set ( sort_order = "asc" )
          [self] + descendants(sort_order)
        end
        
        def children_count
          self.class.count :conditions => [ "#{acts_as_materialized_path_options[:path_column]} like ? || id ", self[acts_as_materialized_path_options[:path_column]] + "." ]
        end
        
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
        
        def root
          self.root? ? self : self.class.find_by_id(self[acts_as_materialized_path_options[:path_column]].split(/\./)[0])
        end
        
        def root?
          self[acts_as_materialized_path_options[:path_column]] !~ /\./ ? true : false
        end
        
        def child?
          child_regex = Regexp.new("\\.#{id}$")
          self[acts_as_materialized_path_options[:path_column]] =~ child_regex ? true : false
        end
        
        def children_list=(x)
          @children_list = x
        end
        
        def children_list
          return @children_list
        end
        
        def add_child(element)
          if(self.children_list == nil)
            self.children_list = []
          end
          self.children_list.push(element)
        end
          
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
        
        def build_tree
          descendants_list = self.descendants
          descendants_list.each do |descendant|
            self.add_to_tree(self, descendant)
          end
        end
        
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
