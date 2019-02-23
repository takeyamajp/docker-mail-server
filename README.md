# docker-mail-server
[![Docker Stars](https://img.shields.io/docker/stars/takeyamajp/mail-server.svg)](https://hub.docker.com/r/takeyamajp/mail-server/)
[![Docker Pulls](https://img.shields.io/docker/pulls/takeyamajp/mail-server.svg)](https://hub.docker.com/r/takeyamajp/mail-server/)
[![](https://img.shields.io/badge/GitHub-Dockerfile-orange.svg)](https://github.com/takeyamajp/docker-mail-server/blob/master/Dockerfile)
[![license](https://img.shields.io/github/license/takeyamajp/docker-mail-server.svg)](https://github.com/takeyamajp/docker-mail-server/blob/master/LICENSE)

    FROM centos:centos7  
    MAINTAINER "Hiroki Takeyama"
    
    ENV TIMEZONE Asia/Tokyo
    
    ENV HOST_NAME mail.example.com  
    ENV DOMAIN_NAME example.com
    
    ENV MAILBOX_SIZE_LIMIT 0  
    ENV MESSAGE_SIZE_LIMIT 10240000
    
    ENV AUTH_USER user1,user2  
    ENV AUTH_PASSWORD password1,password2
    
    # SMTP  
    EXPOSE 25  
    EXPOSE 587
    
    # SMTPS  
    EXPOSE 465
    
    # POP3/IMAP  
    EXPOSE 110  
    EXPOSE 143
    
    # POP3S/IMAPS  
    EXPOSE 995  
    EXPOSE 993
    
    VOLUME /mailbox
