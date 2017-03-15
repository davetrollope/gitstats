module DataSelectionHelper
  OPEN_COLUMN_DEFS = {
    open_time: { axis: 1, title: 'Time Open' },
    total: { axis: 0, title: 'Number of PRs' },
    authors: { axis: 0, title: 'Number of Authors' },
    repo_count: { axis: 0, title: 'Number of Repos' },
    comment_count: { axis: 0, title: 'Number of Comments' },
    mergeable: { axis: 0, title: 'Mergeable' }
  }.freeze

  def open_column?(column)
    (session[:open_columns] || '').include?(column.to_s)
  end

  def open_columns
    OPEN_COLUMN_DEFS.keys
  end

  def session_open_columns
    open_columns & (session[:open_columns] || 'total').split(',').map(&:to_sym)
  end

  def column_field(column, field)
    OPEN_COLUMN_DEFS[column][field]
  end

  def axis_title(column)
    OPEN_COLUMN_DEFS.select {|_k, v| v[:axis] == column_field(column, :axis) }.count > 1 ? '' : column_field(column, :title)
  end

  def create_open_graph_data(columns, pr_data, key)
    chart_data = columns.map {|column| { name: column_field(column, :title), data: pr_data.pluck(key, column) } }
    series = columns.map.with_index {|column, index| [index, { targetAxisIndex: column_field(column, :axis) }] }.to_h
    axis = columns.map {|column| [column_field(column, :axis), { logScale: false, title: axis_title(column) }]}.to_h

    [chart_data, series, axis]
  end
end
