# GitStats

This application is designed to provide collection and visualization of pull request data from Github.

There are two sides to this application:

* Data Collection

  * Using the whenever gem (and thus cron) data is collected from Github
   on a periodic basis. See [config/schedule.rb](config/schedule.rb)
  * The GithubDataCollector model implements the retrieval of data.
  * The GithubDataFile model implements the persistence of data
    * Data is stored in dir archive
  
* Data Visualization

  * A Rails server using Bootstrap and D3 to gleen data about the lifecycle of a PR, author or repo etc.
  
# Evaluation Instance
An example instance of this application is running for [evaluation purposes](http://gitstats.hopto.org) - take a look!

# Configuration

## [etc/github.yml](etc/github.yml)

Github server URL and username.

In theory, this can be tweaked to work with a github server hosted on premise - but this is not tested at this time.

## Environment Variables

Running the rails server in production typically requires the 
RAILS_SERVE_STATIC_FILES and SECRET_KEY_BASE variables to be set. E.G.

<pre>
  RAILS_SERVE_STATIC_FILES=1 SECRET_KEY_BASE=secret RAILS_ENV=production rails s
</pre>
