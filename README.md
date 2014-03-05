## Docker Ruby Buildback

### Description
This image is meant to be used as a parent image only.<br />
In your ruby project dir create a Dockerfile with "FROM cpuguy83/ruby-buildpack" as the first line.<br />

This will look for a file called ".build.yml" in the root of your project and use specs in there to build the container.

#### .build.yml example

```yaml
ruby: ruby-2.1.1
pkg:
  - libmysqlclient-dev
cmds:
  pre:
    - # ?? Something to run every time before start
  install:
    - bundle install
  start:
    app: bundle exec puma
    worker: bundle exec sidekiq
    clock: bundle exec clockwork config/clockwork
  once:
    - bundle exec rake assets:precompile
```

### Usage
#### Building
As stated in the description, you should inherit from this image.<br />
From there build from your Dockerfile, the build will handle several things:
- add your app to the image
- install package dependencies as specified in your .build.yml file
- install the ruby you wish to use
- Perform a bundle install

#### Running
When you run  your image it will run any commands you have listed in before_start_cmds<br/>
You can pass in extra CMD arguments for starting specific "start_cmds".  For instance:
`docker run -d cpuguy83/my_ruby_app worker clock` will start the worker and clock start_cmds from your .build.yml<br />
If you do not pass in any extra CMD's when running the container it will start all of your start_cmds <br />

If you are starting multiple apps, runit is used to monitor these apps <br />
The runit configurations are stored in /opt/app/sv/[cmd_name]<br />
If you need, for some reason, to add commands to clean up before stopping the process, you should add a "finnish" script to the above dir.<br />
See the runit docs for more information.

