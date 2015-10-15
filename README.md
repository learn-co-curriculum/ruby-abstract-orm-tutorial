

# Building an ORM: Abstracted Example

We're going to walk through an example of an ORM built into a class called Student, which handles making a connection to the database, and performing basic CRUD functions. The example is abstracted and some things will seem very new to you. Be sure to go through this resource sequentially. When you're at the end, check out `student.rb`, which has the entire Student class.

## `save`
 
```ruby
require 'sqlite3'
class Student
 #....
 def save
    @@db.execute("INSERT INTO ? (#{attributes_for_sql}) VALUES #{question_marks_for_sql}", insert_for_sql)
 end
end
```

This is where we start, it is the student class's job to know how to save itself to the database.

`@@db` is a database connection maintained by the Student class.

The `.execute` method we get from requiring the `sqlite3` gem.

The heart of this method is in three other methods:
  * `attributes_for_sql` returns the column names for the attributes in a sql statement.
  * `question_marks_for_sql` returns an amount of ? for SQL replacement.
  * `insert_for_sql` returns an array of attribute values of a student.

We built this method by first having hard coded values and then extracting the logic into a method to encapsulate it and reduce the complexity of the individual methods.

## `ATTRIBUTES`

```ruby
  ATTRIBUTES = {
    :name => :text,
    :bio => :text,
    :tagline => :text
  }
```

The `ATTRIBUTES` constant is serving the purpose of consolidating the knowledge of the attributes of students into one place so that those details aren't leaked into any other part of the class. It started as an array but as we built the `create_table` logic, more meta data about the attributes was required, namely, their corresponding types as columns.

## `@@db`

```ruby
  @@db = SQLite3::Database.new('student.db')
```

`@@db` is a class variable that is loaded when Ruby read the class definition and only then, not upon instantiation of new students by `Student.new`. Since it's a class variable, it will be accessible in both class methods and instance methods, just like the `ATTRIBUTES` constant.

## `self.attributes`

```ruby
  def self.attributes
    ATTRIBUTES.keys
  end
```

Originally we were using the concrete or literal value `ATTRIBUTES` accross methods. However, when the structure of `ATTRIBUTES` changed from an array to a hash, the other methods broke. Rather than relying on the brittle structure of `ATTRIBUTES`, we encapsulated the access to the attribute names in class method `self.attributes`.

## `self.attributes_hash`

```ruby
  def self.attributes_hash
    ATTRIBUTES
  end
```

`self.attributes_hash` is a class accessor for the literal value of `ATTRIBUTES`.

## `self.table_name`

```ruby
  def self.table_name
    "students"
  end
```

`self.table_name` is a class accessor for the corresponding table name in our database.

## `self.columns_for_sql`

```ruby
  def self.columns_for_sql
    self.attributes_hash.collect{|k,v| "#{k.to_s.downcase} #{v.to_s.upcase}"}.join(",")
  end
```

`self.columns_for_sql` is a class method used in the `create_table` and `create_table_sql` methods to build the initial schema. It is only used in the context of creating the table.

## `self.create_table_sql`

```ruby
  def self.create_table_sql
    [self.table_name, self.columns_for_sql]
  end
```

`self.create_table_sql` is a class method that creates an array for the values of the `create_table` method.

## `self.create_table`

```ruby
  def self.create_table
    @@db.execute("CREATE TABLE ? (?) ", self.create_table_sql)
  end
  self.create_table
```

We could have executed the schema creation logic within the body of the class itself, but it makes more sense to encapsulate this logic into methods -to teach the class how to create the table rather than just create the table.

We build the `self.create_table` and then immediately call it.

## Creating `attr_accessor`s

```ruby
  self.attributes.each do |attribute|
    attr_accessor attribute
  end
```

This is the routine that accesses the attribute names of a student via the attributes accessor (which returns just the keys of the `ATTRIBUTES` hash). For each attribute, declar an accessor. We could also have a macro method (like `create_table`) that would encapsulate the logic and then call it again.

## `attributes_for_sql`

```ruby
  def attributes_for_sql
    self.class.attributes.join(",")
  end
```

The `attributes_for_sql` method generates the column names for the VALUES clause of our sql statement.

So the return of this method would be:
`=> "name, bio, tagline"`

## `question_marks_for_sql`

```ruby
  def question_marks_for_sql
    (["?"]*self.class.attributes.size).join(",")
  end
```

This method returns a ? for each attribute to make the SQL replacement in the INSERT easier to generate. It uses some nice string/array arithmetic.

## `values_for_attributes_for_sql`

```ruby
  def values_for_attributes_for_sql
    self.class.attributes.collect{|a| self.send(a)}
  end
```

The goal of this method is to collect all the actual values of a student's attributes. To accomplish this we iterate over the name of the attributes, like :name, and send them to the student instance as method calls via the `send` method.

## `insert_for_sql`

```ruby
  def insert_for_sql
    [values_for_attributes_for_sql].flatten
  end
```

All this method does is flatten the return value of the above method `values_for_attributes_for_sql`. This method isn't 100% required and could be a part of the original method, but we decided to abstract it out.

This method is then called in the `save` method when values are inserted into the table.

## Resources

* [Ruby's send method](http://rubymonk.com/learning/books/2-metaprogramming-ruby/chapters/25-dynamic-methods/lessons/65-send)
* [Introduction: ORMs in Ruby](http://www.sitepoint.com/orm-ruby-introduction/)
