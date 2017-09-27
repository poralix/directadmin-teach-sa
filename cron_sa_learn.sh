#!/usr/bin/env bash
#######################################################################################
##
## Written by Alex S Grebenschikov (zEitEr) $ Wed Sep 27 16:52:01 +07 2017
## www: http://www.poralix.com/
## email: support@poralix.com
## Version: 0.4 (beta), Wed Sep 27 16:52:01 +07 2017
##
#######################################################################################
##
## The script goes through all Directadmin users and teach SpamAssassin
## per user bases. Every user has its own bayes data, stored at his/her
## own homedir.
##
#######################################################################################
##
## MIT License
##
## Copyright (c) 2016 Alex S Grebenschikov (www.poralix.com)
##
## Permission is hereby granted, free of charge, to any person obtaining a copy
## of this software and associated documentation files (the "Software"), to deal
## in the Software without restriction, including without limitation the rights
## to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
## copies of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:
##
## The above copyright notice and this permission notice shall be included in all
## copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
## OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
## SOFTWARE.
##
#######################################################################################

#######################################################################################
##
## !!!!                 DO NOT CHANGE ANYTHING BELOW HERE                          !!!!
## !!!!          UNLESS YOU ARE 100% SURE THAT YOU KNOW WHAT YOU DO                !!!!
## !!!!      IF IT'S REQUIRED YOU SHOULD UPDATE SETTINGS in settings.cnf           !!!!
##
#######################################################################################

DELETE_TEACH_DATA="0";
TEACH_SPAM_FOLDER="INBOX.teach-isspam";
TEACH_HAM_FOLDER="INBOX.teach-isnotspam";

SETTINGS_FILE="`dirname $0`/settings.cnf";
if [ -f "${SETTINGS_FILE}" ]; then . ${SETTINGS_FILE}; fi;

USER_ID=`id -u`;

function e()
{
    echo "[$(date)] $@";
}

function check_sudo_exists()
{
    SUDO="/usr/local/bin/sudo";
    [ -x "${SUDO}" ] || SUDO="/usr/bin/sudo";
    if [ -x "${SUDO}" ]; 
    then
    {
        e "[OK] The binary sudo was found";
    }
    else
    {
        e "[ERROR] The binary sudo was not found! Terminating...";
        exit 1;
    }
    fi;
}

function check_sudo_user()
{
    c=`sudo -u admin whoami 2>&1`
    if [ "${c}" != "admin" ]; 
    then
    {
        e "[ERROR] Cannot sudo as an user! Terminating...";
        exit 2;
    }
    fi;
}

function get_users_list()
{
    ls -1 /usr/local/directadmin/data/users/ | sort;
}

function teach_user_spam()
{
    if [ -n "$(find ${1}/{new,cur}/* -type f 2>/dev/null)" ]; then
    {
        local loc_res=`${SUDO} -u ${user} /usr/bin/sa-learn --no-sync --spam  ${1}/{cur,new}`;
        DO_SYNC=1;
        e "[OK] [${user}] [+] Teaching user SPAM from ${1}";
        e "[OK] [${user}] [+] ${loc_res}";

        if [ "${DELETE_TEACH_DATA}" == "1" ];
        then
        {
            e "[OK] [${user}] [+] Removing emails from ${1}";
            rm -f ${USER_SPAM_FOLDER}/new/* ${USER_SPAM_FOLDER}/cur/* >/dev/null 2>&1;
        }
        fi;
    }
    else
    {
        e "[OK] [${user}] [-] No emails found under ${1}, skipping learning spam";
    }
    fi;
}

function teach_user_ham()
{
    if [ -n "$(find ${1}/{new,cur}/* -type f 2>/dev/null)" ]; then
    {
        local loc_res=`${SUDO} -u ${user} /usr/bin/sa-learn --no-sync --ham  ${1}/{cur,new}`;
        DO_SYNC=1;
        e "[OK] [${user}] [+] Teaching user HAM from ${1}";
        e "[OK] [${user}] [+] ${loc_res}";

        if [ "${DELETE_TEACH_DATA}" == "1" ];
        then
        {
            e "[OK] [${user}] [+] Removing emails from ${1}";
            rm -f ${USER_HAM_FOLDER}/new/* ${USER_HAM_FOLDER}/cur/* >/dev/null 2>&1;
        }
        fi;
    }
    else
    {
        e "[OK] [${user}] [-] No emails found under ${1}, skipping learning ham";
    }
    fi;
}

function process_maildir()
{
    if [ -n "${TEACH_SPAM_FOLDER}" ];
    then
    {
        USER_SPAM_FOLDER="${1}/.${TEACH_SPAM_FOLDER}";
        if [ -d "${USER_SPAM_FOLDER}/new" ] || [ -d "${USER_SPAM_FOLDER}/cur" ]; then teach_user_spam "${USER_SPAM_FOLDER}"; fi;
    }
    fi;

    if [ -n "${TEACH_HAM_FOLDER}" ];
    then
    {
        USER_HAM_FOLDER="${1}/.${TEACH_HAM_FOLDER}";
        if [ -d "${USER_HAM_FOLDER}/new" ] || [ -d "${USER_HAM_FOLDER}/cur" ]; then teach_user_ham "${USER_HAM_FOLDER}"; fi;
    }
    fi;
}

function process_user()
{
    USER_HOME="/home/${user}";
    DO_SYNC=0;

    # Processing system mail account for an user
    if [ -d "${USER_HOME}/Maildir" ]; then
    {
        e "[OK] [${user}] [+] found system mail account in ${USER_HOME}/Maildir";
        process_maildir "${USER_HOME}/Maildir";
    }
    fi;

    # Processing virtual mail accounts for user's domains
    if [ -d "${USER_HOME}/imap" ]; then
    {
        for domain in `ls ${USER_HOME}/imap 2>/dev/null`;
        do
        {
            DOMAIN_DIR="${USER_HOME}/imap/${domain}";
            if [ -h "${DOMAIN_DIR}" ]; then continue; fi;

            e "[OK] [${user}] [+] found domain ${domain} owned by ${user}";

            for mdir in `ls -d ${DOMAIN_DIR}/*/Maildir 2>/dev/null`;
            do
            {
                e "[OK] [${user}] [+] found ${mdir}";
                process_maildir "${mdir}";
            };
            done;
        }
        done;
    }
    fi;

    # Run once per user, instead of once per email box
    if [ "${DO_SYNC}" == "1" ]; then
    {
        e "[OK] [${user}] Synchronizing the database and the journal";
        # Synchronize the database and the journal if needed
        ${SUDO} -u ${user} /usr/bin/sa-learn --sync;
        ${SUDO} -u ${user} /usr/bin/sa-learn --dump magic;
    }
    else
    {
        e "[OK] [${user}] [-] Nothing to synchronize yet";
    }
    fi;
}

user=`whoami`
e "[OK] Started!";
e "[INFO] Running $0 as user ${user}";
check_sudo_exists;
check_sudo_user;

if [ "${USER_ID}" == "0" ]; then
{
    users=`get_users_list`;
    for user in `echo ${users}`;
    do
    {
        e "[OK] [${user}] Running for user ${user}";
        process_user;
        #${SUDO} -u ${user} id;
        e "[OK] [${user}] Finished with user ${user}";
    }
    done;
}
else
{
    e "[OK] Running for user ${user}";
    process_user;
}
fi;
e "[OK] Finished!";

exit 0;
