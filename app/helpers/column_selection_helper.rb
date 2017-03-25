module ColumnSelectionHelper
  OPEN_COLUMN_DEFS = {
    open_time: { axis: 1, title: 'Time Open', view_types: %w(repo_summary author_summary) },
    total: { axis: 0, title: 'Number of PRs', view_types: %w(repo_summary author_summary) },
    authors: { axis: 0, title: 'Number of Authors', view_types: ['repo_summary'] },
    repo_count: { axis: 0, title: 'Number of Repos', view_types: ['author_summary'] },
    comment_count: { axis: 0, title: 'Number of Comments', view_types: %w(repo_summary author_summary) },
    mergeable: { axis: 0, title: 'Mergeable', view_types: %w(repo_summary author_summary) }
  }.freeze

  def open_column_selected?(column)
    open_column_defs.selected?(session[:open_columns], column)
  end

  def open_columns
    open_column_defs.match_columns(session[:open_columns])
  end

  def set_open_columns
    session[:open_columns] = column_settings open_column_defs, open_columns

    session.delete :open_columns if session[:open_columns].blank?

    redirect_back fallback_location: root_path
  end

  CLOSED_COLUMN_DEFS = {
    merge_time: { axis: 1, title: 'Merge Time', view_types: %w(repo_summary author_summary) },
    intg_time: { axis: 1, title: 'Integration Time', view_types: %w(repo_summary author_summary) },
    total: { axis: 0, title: 'Number of PRs', view_types: %w(repo_summary author_summary) },
    authors: { axis: 0, title: 'Number of Authors', view_types: ['repo_summary'] },
    repo_count: { axis: 0, title: 'Number of Repos', view_types: ['author_summary'] }
  }.freeze

  def closed_column_selected?(column)
    closed_column_defs.selected?(session[:closed_columns], column)
  end

  def closed_columns
    closed_column_defs.match_columns(session[:closed_columns])
  end

  def set_closed_columns
    session[:closed_columns] = column_settings closed_column_defs, closed_columns

    session.delete :closed_columns if session[:closed_columns].blank?

    redirect_back fallback_location: root_path
  end

  # Common methods
  def column_settings(defs, columns)
    defs.column_names.map {|column|
      if defs.view_includes_column?(view_type, column)
        params[column]
      else
        columns.include?(column) ? column.to_s : nil
      end
    }.compact.join ','
  end

  def axis_title(defs, column)
    defs.select_field(column, :axis).count > 1 ? '' : defs.get_field(column, :title)
  end

  def create_graph_data(defs, columns, pr_data, key)
    columns &= pr_data.map(&:keys).flatten.uniq

    chart_data = columns.map {|column| { name: defs.get_field(column, :title), data: pr_data.pluck(key, column) } }

    series = []
    axis = []
    columns.each_with_index {|column, index|
      series << [index, { targetAxisIndex: defs.get_field(column, :axis) }]
      axis << [defs.get_field(column, :axis), { logScale: false, title: axis_title(defs, column) }]
    }

    [chart_data, series.to_h, axis.to_h]
  end

  def create_trend_graph_data(defs, columns, file_data)
    columns &= file_data.first[:pr_data].map(&:keys).flatten.uniq

    chart_data = []
    file_data.each {|file_hash|
      next unless file_hash[:file_date].present?
      columns.each {|column|
        name = defs.get_field(column, :title)
        data = file_hash[:pr_data].pluck(column).prepend(file_hash[:file_date])

        series_data = chart_data.select {|h| h[:name] == name }

        if series_data.empty?
          chart_data << { name: name, data: [data] }
        else
          series_data[0][:data] << data
        end
      }
    }

    series = []
    axis = []
    columns.each_with_index {|column, index|
      series << [index, { targetAxisIndex: defs.get_field(column, :axis) }]
      axis << [defs.get_field(column, :axis), { logScale: false, title: axis_title(defs, column) }]
    }
    # binding.pry

    [chart_data, series.to_h, axis.to_h]
  end
end
