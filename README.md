# log-filter-from-nginx-with-cronjob-and-send-notification-to-slack-channel-or-email

This document has been devided into 3 parts. Here we will do filter nginx logs  with crontab then push notification to slack channel and then send mail the copy by postfix mail server.

# 1.Nginx log filter with cronjob

Make a file named config in `~/.ssh/` folder. 

Add these following lines in the file.

```
Hostname 192.168.1.1
user USER1
```

Save the file & go to terminal and run the following command:

> akash-support@akashsupport-3570R-370R-470R-450R-510R:~/.ssh$ ssh <host name> 


It will be a successful login in appmin user at logreader.

Find Nginx logs in directory. Now make a .sh file and put the following command line.

> $ nano abc.sh 

Add these following lines in the file. The command line will filter the nginx file log by “error” and “current date” and will put them in to a new file. The new file name format will be currentdate_error. 


```
#!/bin/bash
grep $(date +"%Y-%m-%d") /home/nginx.log | grep "error" > /home/"$(date +%F)_ERROR"
```


Save the file with ctr+x. Now we have to run the .sh file in cronjob. For this, run the command in terminal.

> $ crontab -e  

Add the line 

`59 17 * * * /bin/sh /home/abc.sh`



The cronjob will run the abc.sh file everyday at **17:59 GMT**.

# 2. Send error log file with count to slack channel

First we have to collect lagacy token from the following link-----

https://api.slack.com/custom-integrations/legacy-tokens

Then make a sh file named slack-upload.sh and put the following info:

```
#!/usr/bin/env bash
# This bash script makes use of the Slack API to upload files.
# I found this useful due to the fact that the attachement option
# available in incoming webhooks seems to have an upper limit of
# content size, which is way too small.
#
# See also: https://api.slack.com/methods/files.upload
# safety first
set -euf -o pipefail
echo=&#39;echo -e&#39;
Usage() {
${echo}
${echo} &quot;\tusage:\n\t\t$0 [OPTIONS]&quot;
${echo}
${echo} &quot;Required:&quot;
${echo} &quot; -c CHANNEL\tSlack channel to post to&quot;
${echo} &quot; -f FILENAME\tName of file to upload&quot;
${echo} &quot; -s SLACK_TOKEN\tAPI auth token&quot;
${echo}
${echo} &quot;Optional:&quot;
${echo} &quot; -u API_URL\tSlack API endpoint to use (default:
https://slack.com/api/files.upload)&quot;
${echo} &quot; -h \tPrint help&quot;
${echo} &quot; -m TYPE\tFile type (see https://api.slack.com/types/file#file_types)&quot;
${echo} &quot; -n TITLE\tTitle for slack post&quot;
${echo} &quot; -v \tVerbose mode&quot;
${echo} &quot; -x COMMENT\tAdd a comment to the file&quot;
${echo}
exit ${1:-$USAGE}
}
# Exit Vars
: ${HELP:=0}
: ${USAGE:=1}

# Default Vars
API_URL=&#39;https://slack.com/api/files.upload&#39;
CURL_OPTS=&#39;-s&#39;
# main
while getopts :c:f:s:u:hm:n:vx: OPT; do
case ${OPT} in
c)
CHANNEL=&quot;$OPTARG&quot;
;;
f)
FILENAME=&quot;$OPTARG&quot;
SHORT_FILENAME=$(basename ${FILENAME})
;;
s)
SLACK_TOKEN=&quot;$OPTARG&quot;
;;
u)
API_URL=&quot;$OPTARG&quot;
;;
h)
Usage ${HELP}
;;
m)
CURL_OPTS=&quot;${CURL_OPTS} -F filetype=${OPTARG}&quot;
;;
n)
CURL_OPTS=&quot;${CURL_OPTS} -F title=&#39;${OPTARG}&#39;&quot;
;;
v)
CURL_OPTS=&quot;${CURL_OPTS} -v&quot;
;;
x)
CURL_OPTS=&quot;${CURL_OPTS} -F initial_comment=&#39;${OPTARG}&#39;&quot;
;;
\?)
echo &quot;Invalid option: -$OPTARG&quot; &gt;&amp;2
Usage ${USAGE}
;;
esac
done
if [[ ( &quot;${CHANNEL}&quot; != &quot;#&quot;* ) &amp;&amp; ( &quot;${CHANNEL}&quot; != &quot;@&quot;* ) ]]; then
CHANNEL=&quot;#${CHANNEL}&quot;
fi
# had to use eval to avoid strange whitespace behavior in options
eval curl $CURL_OPTS \
--form-string channels=${CHANNEL} \
-F file=@${FILENAME} \
-F filename=${SHORT_FILENAME} \

-F token=${SLACK_TOKEN} \
${API_URL}
exit 0
```

save and close the file.

Then again make a sh file named slack.sh and put the following info:
Put the lagacy token on the command.

```
#!/bin/sh
newest=$(ls /mnt/sharedfolder_client/Log_result/ -Art | tail -n 1)
count=$(grep -o -c error /mnt/sharedfolder_client/Log_result/$newest)
sudo ./slack-upload.sh -f /mnt/sharedfolder_client/Log_result/$newest -c &#39;#general&#39; -s
xoxp-xxxxxxxxxxxxxxxxxxxxx -x &#39;Total Error: &#39;$count
```

save and close the file.
From terminal run `./slack.sh` command. A notification will be appeared
with error log file with count.

Run `crontab -e` command and put these following command. It will run multiple sh files during the specific time. 

`59 17 * * * /home/appmin/logs/lifemed-prep/abc.sh && /home/appmin/logs/lifemed-prep/slack.sh`

# 3. Configure Postfix to Send Mail Using an External SMTP Server

[Refference]: https://www.linode.com/docs/email/postfix/postfix-smtp-debian7/

**Prerequisites**

Make sure All updates installed :

> sudo apt-get update 

Make sure the libsasl2-modules package is installed and up to date:

> sudo apt-get install libsasl2-modules 

**Installing Postfix**

1. Install Postfix with the following command:

> sudo apt-get install postfix 

2.During the installation, a prompt will appear asking for your General type of mail configuration.

Select Internet Site.

3. Enter the fully qualified name of your domain, `iappdragon.com`.



4. Once the installation is finished, open the `/etc/postfix/main.cf` file with your favorite text editor:

> sudo nano /etc/postfix/main.cf 

5.Make sure that the myhostname parameter is configured with your server’s (Fully qualified domain name)FQDN:

`myhostname = domain.com`


**Configuring SMTP Usernames and Passwords**

1.Open or create the `/etc/postfix/sasl_passwd file`, using your favorite text editor:

> sudo nano /etc/postfix/sasl_passwd 

2.Add your destination (SMTP Host), username, and password in the following format:

`smtp.hosts.co.uk doman.com:password`

3.Create the hash db file for Postfix by running the postmap command:

> sudo postmap /etc/postfix/sasl_passwd 

If all went well, you should have a new file named sasl_passwd.db in the `/etc/postfix/` directory.

Securing Your Password and Hash Database Files


The `/etc/postfix/sasl_passwd` and the `/etc/postfix/sasl_passwd.db` files created in the previous steps contain your SMTP credentials in plain text.

For security reasons, you should change their permissions so that only the root user can read or write to the file. Run the following commands to change the ownership to root and update the permissions for the two files:

> sudo chown root:root /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db 

> sudo chmod 0600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db 

Configuring the Relay Server

In this section, you will configure the /etc/postfix/main.cf file to use the external SMTP server.

1. Open the `/etc/postfix/main.cf` file with your favorite text editor:

> sudo nano /etc/postfix/main.cf 

2. Update the relayhost parameter to show your external SMTP relay host. 

**Important:**** If you specified a non-default TCP port in the sasl_passwd file, then you must use the same port when configuring the relayhost parameter.

```
# specify SMTP relay host
relayhost = smtp.hosts.co.uk:587
```

3. At the end of the file, add the following parameters to enable authentication:

```
# enable SASL authentication
smtp_sasl_auth_enable = yes
# disallow methods that allow anonymous authentication.
smtp_sasl_security_options = noanonymous
# where to find sasl_passwd
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
# Enable STARTTLS encryption
smtp_use_tls = yes
# where to find CA certificates
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
```

4. Save your changes.

5. Restart Postfix:

> sudo service postfix restart 

**Testing Postfix**

The fastest way to test your configuration is to send an email to any unrelated email address, using the mail command:

> echo "body of your email" | mail -s "This is a Subject" -a "From: you@example.com" recipient@elsewhere.com 

`e.g: echo "body of your email" | mail -s "This is a Subject" -a "From: akashpaul@domain.com" akashpaul190994@gmail.com`


You may have to install mailutils to use the mail command:

> sudo apt-get install mailutils 

Alternatively, you can use Postfix’s own sendmail implementation, by entering lines similar to those shown below:

```
sendmail recipient@elsewhere.com
From: you@example.com
Subject: Test mail
This is a test email
```

If the file is located in terminals default directory, the the following command may be useful for you to attaching a file with mail.

> echo "body of your email" | mail -s "This is a Subject" -a "From: akashpaul@iappdragon.com" akashpaul190994@gmail.com -A message.txt 

File can be attached from different directories….. follow the following command.

> echo "body of your email" | mail -s "This is a Subject" -a "From: akashpaul@iappdragon.com" akashpaul190994@gmail.com -A /home/akash-support/Desktop/message.txt 


Here is the bash script for sending the last modified file with mail.

```
#!/bin/sh
newest=$(ls -Art | tail -n 1)
echo "body of your email" | mail -s "This is a Subject" -a "From: akashpaul@domain.com" akashpaul190994@gmail.com -A "$newest"
```
