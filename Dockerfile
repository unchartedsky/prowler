FROM python
MAINTAINER Jaehoon Choi <plaintext@andromedarabbit.net>
RUN apt-get update && apt-get upgrade -y \
	&& apt-get install -y xvfb wkhtmltopdf \
	&& pip install awscli ansi2html \
	&& curl --silent -Lo slackcat https://github.com/bcicen/slackcat/releases/download/v1.4/slackcat-1.4-$(uname -s)-amd64 \
	&& mv slackcat /usr/local/bin/ \
	&& chmod +x /usr/local/bin/slackcat

RUN curl -sL https://github.com/toniblyx/prowler/archive/master.tar.gz | tar xz \
	&& mv prowler-master /prowler

WORKDIR /prowler

CMD ./prowler