
if [ "$1" == "" ]; then
  prefix=$(date +%Y%m%d)
fi

for project in ruby rails python golang clojure jruby graalvm erlang
do
  rails runner "require 'github_data_file'; GithubDataFile.get_consolidated_user_prs 'archive', '${prefix}*_open_pr_data.json', "$prefix", $project, state: 'open', skip_fetch: true"
done
