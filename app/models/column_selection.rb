class ColumnSelection
  attr_reader(:definitions)
  attr_reader(:default_value)
  attr_reader(:default_view)

  def initialize(column_definitions, default_value, default_view)
    @definitions = column_definitions
    @default_value = default_value
    @default_view = default_view
  end

  def selected?(current_columns, column)
    (current_columns || default_value).include?(column.to_s)
  end

  def column_names
    definitions.keys
  end

  def get_field(column, field)
    definitions[column][field]
  end

  def select_columns_by_view(view_type)
    definitions.select {|_k, v| v[:view_types].include?(view_type || default_view)}
  end

  def view_includes_column?(view_type, column)
    select_columns_by_view(view_type).keys.include? column
  end

  def match_columns(current_columns)
    column_names & (current_columns || default_value).split(',').map(&:to_sym)
  end

  def select_field(column, field)
    definitions.select {|_k, v| v[field] == get_field(column, field) }
  end
end
