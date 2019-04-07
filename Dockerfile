FROM ubuntu:18.04

RUN apt-get update
RUN apt-get install -y ansible
RUN apt-get install -y git
RUN git clone https://github.com/asnet-am/eduroam-imap-playbook.git

WORKDIR /eduroam-imap-playbook

RUN apt-get -y install sudo
RUN ansible-playbook -i inventories/development site.yml
