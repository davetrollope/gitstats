# GitStats

This application is designed to provide collection and visualization of pull request data from Github.

There are two sides to this application:

* Data Collection

  * Using the whenever gem (and thus cron) data is collected from Github
   on a periodic basis. See [config/schedule.rb](config/schedule.rb)
  * The GithubDataCollector model implements the retrieval of data.
  * Data is stored in dir archive
  
* Data Visualization

  * A Rails server using Bootstrap and D3 to gleen data about the lifecycle of a PR, author or repo etc.
  
# Configuration

The github server URL and username is configured in [etc/github.yml](etc/github.yml)

In theory, this can be tweaked to work with a github server hosted on premise - but this is not tested at this time.
