# directadmin-teach-sa
A set of scripts to create folders and teach SpamAssassin per user on Directadmin based servers. 
Every single user has it's own bayes files stored under his/her homedir.

# Installation

```
cd /usr/local/directadmin/scripts/custom/
git clone https://github.com/poralix/directadmin-teach-sa.git
cd ./directadmin-teach-sa
cp -p ./0teach-sa_cron /etc/cron.d/
cp -p settings.cnf.default settings.cnf
```

# First run

Before running update *settings.cnf* if it's required. For example if you need to change folders' names.

```
cd /usr/local/directadmin/scripts/custom/directadmin-teach-sa
./create_folders.sh --all
```

# Structure

**create_folders.sh** - a script to create *teach-isspam* and *teach-isnotspam* folders:

- for a single email-box
- for all email boxes on a single domain
- for all domains on a server

*Usage*:

```
./create_folders.sh [<email-box>|<domain-name>|--all|--settings]
```

Can be used with the Directadmin hook-script: /usr/local/directadmin/scripts/custom/email_create_post.sh

```
#!/bin/sh
SCRIPT="/usr/local/directadmin/scripts/custom/directadmin-teach-sa/create_folders.sh";
[ -x "${SCRIPT}" ] && ${SCRIPT} "${user}@${domain}" >/dev/null 2>&1;
```

or copy the sample *email_create_post.sh.sample*:

```
cp -p /usr/local/directadmin/scripts/custom/email_create_post.sh /usr/local/directadmin/scripts/custom/email_create_post.sh~bak
cp email_create_post.sh.sample /usr/local/directadmin/scripts/custom/email_create_post.sh
chmod 700 /usr/local/directadmin/scripts/custom/email_create_post.sh
chown diradmin:diradmin /usr/local/directadmin/scripts/custom/email_create_post.sh
```

**cron_sa_learn.sh** - a script to run with *cron*. The script goes through all Directadmin users and 
teach SpamAssassin per user bases. Every user has its own bayes data, stored under his/her own homedir.

The script requires *root* permissions and *sudo* installed on a server to run. It will use *sudo* to 
switch to user for teaching SpamAssassin.

*Usage*:

```
./cron_sa_learn.sh > ./cron_sa_learn.log 2>&1
```

or run with cron:

```
21    * * * *     root /usr/local/directadmin/scripts/custom/directadmin-teach-sa/cron_sa_learn.sh > /usr/local/directadmin/scripts/custom/directadmin-teach-sa/cron_sa_learn.log 2>&1
```


**settings.cnf** - a script with settings:

```
# TEACH SPAM FOLDER
TEACH_SPAM_FOLDER="INBOX.teach-isspam";

# TEACH NOT SPAM FOLDER
TEACH_HAM_FOLDER="INBOX.teach-isnotspam";

# TO DELETE OR NOT EMAIL AFTER TEACHING SPAM
DELETE_TEACH_SPAM_DATA="0";

# TO DELETE OR NOT EMAIL AFTER TEACHING NOT SPAM
DELETE_TEACH_HAM_DATA="0";

# TO MARK AS READ OR NOT EMAIL AFTER TEACHING SPAM
# DELETE_TEACH_SPAM_DATA SHOULD BE SET TO 0
MARK_AS_READ_TEACH_SPAM_DATA="1";

# TO MARK AS READ OR NOT EMAIL AFTER TEACHING NOT SPAM
# DELETE_TEACH_HAM_DATA SHOULD BE SET TO 0
MARK_AS_READ_TEACH_HAM_DATA="1";
```

IF IT'S REQUIRED YOU SHOULD UPDATE SETTINGS in settings.cnf

# History

**v0.11**

- Get a homedir from /etc/passwd to support /home2, /home3, etc ... (beta)

**v0.10**

- A support for Rspamd added (beta)

**v0.9:**

- Script failed to start, if no user `admin` exists on a server - FIXED

**v0.8:**

- Fixed "too many arguments" error

**v0.7:**

- Debug mode added

**v0.6:**

- Fix for Perl 5.24.x applied: https://github.com/poralix/directadmin-teach-sa/issues/3

**v.0.5:**

- The setting DELETE_TEACH_DATA is deprecated since
- Added DELETE_TEACH_SPAM_DATA to control cleaning from SPAM folder
- Added DELETE_TEACH_HAM_DATA to control cleaning from HAM folder
- Added MARK_AS_READ_TEACH_SPAM_DATA to mark or not as read emails in SPAM folder
- Added MARK_AS_READ_TEACH_HAM_DATA to mark or not as read emails in HAM folder

# Thanks to

- John from Directadmin for basic script on help.directadmin.com
- User _jobhh_ https://github.com/jobhh for posting issues
- Andrew Oakley www.aoakley.com for markallread script

# License and Copyright

Copyright (c) 2016-2022 Alex S Grebenschikov (www.poralix.com)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
