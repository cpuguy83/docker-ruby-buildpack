FROM ubuntu:12.04
RUN rm /bin/sh && ln -s /bin/bash /bin/sh
ENV DEBIAN_FRONTEND noninteractive
RUN locale-gen en_US.UTF-8 && update-locale en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8
RUN apt-get update -qq && apt-get install -y ca-certificates curl git runit -qq

RUN curl -L https://get.rvm.io | bash -s head
ENV PATH /usr/local/rvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN /bin/bash -l -c rvm requirements
RUN source /usr/local/rvm/scripts/rvm && rvm install ruby
RUN rvm all do gem install bundler
ADD app_setup.rb /tmp/app_setup.rb
ONBUILD ADD . /opt/app
ONBUILD WORKDIR /opt/app
ONBUILD RUN rvm all do /tmp/app_setup.rb install
ONBUILD ENTRYPOINT ["rvm", "all", "do", "/tmp/app_setup.rb"]
