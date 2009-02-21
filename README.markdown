# Description

    This is an implementation of path enumeration data model.
    Declaration *acts_as_materialized_path* placed in an ActiveRecord model
    allows this model to perform operations on such data.
    
    Data table has to have at least two columns:

    1. id INTEGER PRIMARY KEY column
    2. path_string TEXT column (name of the column can be different)

## Installation

    Add gems.github.com source to the sources list

        gem sources -a http://gems.github.com

    Install the gem

        gem install sgryzio-acts_as_materialized_path

## Usage

    To declare a model to behave like path enumeration model
    put *acts_as_materialized_path* declaration in the model:

    class Foo < ActiveRecord::Base
        acts_as_materialized_path
    end

    You can optionally pass :path_column => "your_column_name" to the declaration
    (the default name is path_string).

## Examples

    1. Creating new root:

        newRoot = Foo.create_root( :param1 => "value_of_param1", :param2 => "value_of_param2" )

    2. Add a new node as a child of newRoot:

        newNode = Foo.create( parameters... )
        newNode.move_to_child_of( newRoot )
        
    3. Display all descendants of someNode and order the result
       by column_name in ascending order:

        someNode = Foo.find_by_id( someNodeId )
        someNode.descendants( :order => "column_name", :order_dir => "asc" )

    For more examples please chcek spec/test_models_spec.rb.

## License

    (The MIT License)

    Copyright (c) 2008 FIXME full name

    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
    'Software'), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    

