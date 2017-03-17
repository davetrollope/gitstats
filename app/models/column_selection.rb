class ColumnSelection
  attr_reader(:definitions)
  attr_reader(:definition_key)
  attr_reader(:default_value)
  attr_reader(:default_view)

  def initialize(column_definitions, key, default_value, default_view)
    @definitions = column_definitions
    @definition_key = key
    @default_value = default_value
    @default_view = default_view
  end

  def selected?(session, column)
    (session[definition_key] || default_value).include?(column.to_s)
  end

  def columns
    definitions.keys
  end

  def view_columns(session)
    definitions.select {|_k, v| v[:view_types].include?(session['view_type'] || default_view)}.keys
  end

  def session_columns(session)
    columns & (session[definition_key] || default_value).split(',').map(&:to_sym)
  end

  def column_field(column, field)
    definitions[column][field]
  end

  def select_field(column, field)
    definitions.select {|_k, v| v[field] == column_field(column, field) }
  end
end
