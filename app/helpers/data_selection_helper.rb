module DataSelectionHelper
  OPEN_COLUMN_DEFS = {
    open_time: { axis: 1, title: 'Time Open', view_types: %w(repo_summary author_summary) },
    total: { axis: 0, title: 'Number of PRs', view_types: %w(repo_summary author_summary) },
    authors: { axis: 0, title: 'Number of Authors', view_types: ['repo_summary'] },
    repo_count: { axis: 0, title: 'Number of Repos', view_types: ['author_summary'] },
    comment_count: { axis: 0, title: 'Number of Comments', view_types: %w(repo_summary author_summary) },
    mergeable: { axis: 0, title: 'Mergeable', view_types: %w(repo_summary author_summary) }
  }.freeze

  def open_column?(column)
    (session[:open_columns] || '').include?(column.to_s)
  end

  def open_columns
    OPEN_COLUMN_DEFS.keys
  end

  def open_view_columns
    OPEN_COLUMN_DEFS.select {|_k, v| v[:view_types].include?(session['view_type'] || 'repo_summary')}.keys
  end

  def session_open_columns
    open_columns & (session[:open_columns] || 'total').split(',').map(&:to_sym)
  end

  def open_column_field(column, field)
    OPEN_COLUMN_DEFS[column][field]
  end

  def open_axis_title(column)
    corresponding_columns = OPEN_COLUMN_DEFS.select {|_k, v| v[:axis] == open_column_field(column, :axis) }
    corresponding_columns.count > 1 ? '' : open_column_field(column, :title)
  end

  def create_open_graph_data(columns, pr_data, key)
    columns &= pr_data.map(&:keys).flatten.uniq

    chart_data = columns.map {|column| { name: open_column_field(column, :title), data: pr_data.pluck(key, column) } }
    series = columns.map.with_index {|column, index| [index, { targetAxisIndex: open_column_field(column, :axis) }] }.to_h
    axis = columns.map {|column| [open_column_field(column, :axis), { logScale: false, title: open_axis_title(column) }]}.to_h

    [chart_data, series, axis]
  end

  CLOSED_COLUMN_DEFS = {
    merge_time: { axis: 1, title: 'Merge Time', view_types: %w(repo_summary author_summary) },
    intg_time: { axis: 1, title: 'Integration Time', view_types: %w(repo_summary author_summary) },
    total: { axis: 0, title: 'Number of PRs', view_types: %w(repo_summary author_summary) },
    authors: { axis: 0, title: 'Number of Authors', view_types: ['repo_summary'] },
    repo_count: { axis: 0, title: 'Number of Repos', view_types: ['author_summary'] }
  }.freeze

  def closed_column?(column)
    (session[:closed_columns] || '').include?(column.to_s)
  end

  def closed_columns
    CLOSED_COLUMN_DEFS.keys
  end

  def closed_view_columns
    CLOSED_COLUMN_DEFS.select {|_k, v| v[:view_types].include?(session['view_type'] || 'repo_summary')}.keys
  end

  def session_closed_columns
    closed_columns & (session[:closed_columns] || 'total').split(',').map(&:to_sym)
  end

  def closed_column_field(column, field)
    CLOSED_COLUMN_DEFS[column][field]
  end

  def closed_axis_title(column)
    corresponding_columns = CLOSED_COLUMN_DEFS.select {|_k, v| v[:axis] == closed_column_field(column, :axis) }
    corresponding_columns.count > 1 ? '' : closed_column_field(column, :title)
  end

  def create_closed_graph_data(columns, pr_data, key)
    columns &= pr_data.map(&:keys).flatten.uniq

    chart_data = columns.map {|column| { name: closed_column_field(column, :title), data: pr_data.pluck(key, column) } }
    series = columns.map.with_index {|column, index| [index, { targetAxisIndex: closed_column_field(column, :axis) }] }.to_h
    axis = columns.map {|column| [closed_column_field(column, :axis), { logScale: false, title: closed_axis_title(column) }]}.to_h

    [chart_data, series, axis]
  end
end
