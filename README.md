# mail-server
Star this repository if it is useful for you.  
[![Docker Stars](https://img.shields.io/docker/stars/takeyamajp/mail-server.svg)](https://hub.docker.com/r/takeyamajp/mail-server/)
[![Docker Pulls](https://img.shields.io/docker/pulls/takeyamajp/mail-server.svg)](https://hub.docker.com/r/takeyamajp/mail-server/)
[![license](https://img.shields.io/github/license/takeyamajp/docker-mail-server.svg)](https://github.com/takeyamajp/docker-mail-server/blob/master/LICENSE)

### Supported tags and respective Dockerfile links  
- [`latest`, `centos8`](https://github.com/takeyamajp/docker-mail-server/blob/master/centos8/Dockerfile)
- [`centos7`](https://github.com/takeyamajp/docker-mail-server/blob/master/centos7/Dockerfile)

### Image summary
    FROM centos:centos8  
    MAINTAINER "Hiroki Takeyama"
    
    ENV TIMEZONE Asia/Tokyo
    
    ENV HOST_NAME mail.example.com  
    ENV DOMAIN_NAME example.com
    
    ENV MAILBOX_SIZE_LIMIT 0  
    ENV MESSAGE_SIZE_LIMIT 10240000
    
    ENV AUTH_USER user1,user2  
    ENV AUTH_PASSWORD password1,password2
    
    ENV DISABLE_SMTP_AUTH_ON_PORT_25 true  
    ENV BOUNCE_MESSAGE true  
    ENV NOTICE_RECIPIENT user1
    
    ENV ANVIL_RATE_TIME_UNIT 60s  
    ENV SMTPD_CLIENT_CONNECTION_RATE_LIMIT 0
    
    # SMTP  
    EXPOSE 25  
    # Submission  
    EXPOSE 587  
    # SMTPS  
    EXPOSE 465
    
    # POP3  
    EXPOSE 110  
    # IMAP  
    EXPOSE 143
    
    # POP3S  
    EXPOSE 995  
    # IMAPS  
    EXPOSE 993
    
    VOLUME /mailbox
