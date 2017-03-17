module DataSelectionHelper
  OPEN_COLUMN_DEFS = {
    open_time: { axis: 1, title: 'Time Open', view_types: %w(repo_summary author_summary) },
    total: { axis: 0, title: 'Number of PRs', view_types: %w(repo_summary author_summary) },
    authors: { axis: 0, title: 'Number of Authors', view_types: ['repo_summary'] },
    repo_count: { axis: 0, title: 'Number of Repos', view_types: ['author_summary'] },
    comment_count: { axis: 0, title: 'Number of Comments', view_types: %w(repo_summary author_summary) },
    mergeable: { axis: 0, title: 'Mergeable', view_types: %w(repo_summary author_summary) }
  }.freeze

  attr_accessor :open_column_defs, :closed_column_defs

  def create_column_defs
    @open_column_defs = ColumnSelection.new OPEN_COLUMN_DEFS, :open_columns, 'total', 'repo_summary'
    @closed_column_defs = ColumnSelection.new CLOSED_COLUMN_DEFS, :closed_columns, 'total', 'repo_summary'
  end

  def open_column?(column)
    open_column_defs.selected?(session, column)
  end

  def open_columns
    open_column_defs.columns
  end

  def open_view_columns
    open_column_defs.view_columns(session)
  end

  def session_open_columns
    open_column_defs.session_columns(session)
  end

  def open_column_field(column, field)
    open_column_defs.column_field(column, field)
  end

  def open_axis_title(column)
    open_column_defs.select_field(column, :axis).count > 1 ? '' : open_column_field(column, :title)
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
    closed_column_defs.selected?(session, column)
  end

  def closed_columns
    closed_column_defs.columns
  end

  def closed_view_columns
    closed_column_defs.view_columns(session)
  end

  def session_closed_columns
    closed_column_defs.session_columns(session)
  end

  def closed_column_field(column, field)
    closed_column_defs.column_field(column, field)
  end

  def closed_axis_title(column)
    closed_column_defs.select_field(column, :axis).count > 1 ? '' : open_column_field(column, :title)
  end

  def create_closed_graph_data(columns, pr_data, key)
    columns &= pr_data.map(&:keys).flatten.uniq

    chart_data = columns.map {|column| { name: closed_column_field(column, :title), data: pr_data.pluck(key, column) } }
    series = columns.map.with_index {|column, index| [index, { targetAxisIndex: closed_column_field(column, :axis) }] }.to_h
    axis = columns.map {|column| [closed_column_field(column, :axis), { logScale: false, title: closed_axis_title(column) }]}.to_h

    [chart_data, series, axis]
  end
end
