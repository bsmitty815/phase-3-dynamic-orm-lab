require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

    # creates a downcased, plural table name based on the Class name
    def self.table_name
        "#{self.to_s.downcase}s"
    end


    #returns an array of SQL column names
    def self.column_names

        sql = "pragma table_info('#{table_name}')"
    
        table_info = DB[:conn].execute(sql)
        column_names = []
        table_info.each do |row|
            column_names << row["name"]
        end
        column_names.compact
    end


    #creates an new instance of a student
    #creates a new student with attributes
    def initialize(options={})
        options.each do |property, value|
            self.send("#{property}=", value)
        end
    end


    #return the table name when called on an instance of Student
    def table_name_for_insert
        self.class.table_name
    end



    #return the column names when called on an instance of Student
    #does not include an id column
    def values_for_insert
        values = []
        self.class.column_names.each do |col_name|
          values << "'#{send(col_name)}'" unless send(col_name).nil? #This will return an array:["", ""] 
        end
        values.join(", ")  #This will return:
    end


    #formats the column names to be used in a SQL statement
    def col_names_for_insert
        self.class.column_names.delete_if {|col| col == "id"}.join(", ")
    end


    #saves the student to the db
    #sets the student's id
    def save
        sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
        DB[:conn].execute(sql)
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    end


    #executes the SQL to find a row by name
    def self.find_by_name(name)
        sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
        DB[:conn].execute(sql)
    end


    #executes the SQL to find a row by the attribute passed into the method
    #accounts for when an attribute value is an integer
    def self.find_by(attribute_hash)
        value = attribute_hash.values.first
        formatted_value = value.class == Fixnum ? value : "'#{value}'"
        sql = "SELECT * FROM #{self.table_name} WHERE #{attribute_hash.keys.first} = #{formatted_value}"
        DB[:conn].execute(sql)
    end

end