require 'sqlite3'
 
class Student
  ATTRIBUTES = {
    :name => :text,
    :bio => :text,
    :tagline => :text
  }
 
  @@db = SQLite3::Database.new('student.db')
 
  def self.attributes
    ATTRIBUTES.keys
  end
 
  def self.attributes_hash
    ATTRIBUTES
  end

  def self.table_name
    "students"
  end
 
  def self.columns_for_sql
    self.attributes_hash.collect{|k,v| "#{k.to_s.downcase} #{v.to_s.upcase}"}.join(",")
  end
 
  def self.create_table_sql
    [self.table_name, self.columns_for_sql]
  end
 
  def self.create_table
    @@db.execute("CREATE TABLE ? (?) ", self.create_table_sql)
  end
  self.create_table
 
  self.attributes.each do |attribute|
    attr_accessor attribute
  end
 
  def attributes_for_sql
    self.class.attributes.join(",")
  end
 
  def question_marks_for_sql
    (["?"]*self.class.attributes.size).join(",")
  end
 
  def values_for_attributes_for_sql
    self.class.attributes.collect{|a| self.send(a)}
  end
 
  def insert_for_sql
    [values_for_attributes_for_sql].flatten
  end
 
  def save
    @@db.execute("INSERT INTO ? (#{attributes_for_sql}) VALUES #{question_marks_for_sql}", insert_for_sql)
  end
end