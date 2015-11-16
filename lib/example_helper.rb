module ExampleHelper

  #def add_foreign_key_constraint(to_table, from_table, to_column, from_column)
  #  constraint_name = "fk_#{from_table}_#{from_column}"
  #
  #  execute %{alter table #{to_table} add constraint #{constraint_name} foreign key (#{to_column}) references #{from_table}(#{from_column})}
  #end
  #
  #def remove_foreign_key_constraint(to_table, from_table, to_column, from_column)
  #  constraint_name = "fk_#{from_table}_#{from_column}"
  #
  #  execute %{alter table #{to_table} drop foreign key #{constraint_name}}
  #end

end