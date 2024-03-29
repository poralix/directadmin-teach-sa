#!/usr/bin/env bash
#######################################################################################
##
## Written by Alex Grebenschikov (zEitEr)
## Supported by: Poralix, www.poralix.com
## Report bugs and issues: https://github.com/poralix/directadmin-teach-sa/issues
## Version: 0.11 (beta, )Sat Aug 27 17:37:59 +07 2022
##          0.10 (beta), Mon Nov 22 00:37:20 +07 2021
##          0.9 (beta), Sat Oct 30 17:37:09 +07 2021
##          0.8 (beta), Wed Dec 11 23:36:02 +07 2019
##          0.7 (beta), Sat Nov 18 11:57:31 +07 2017
##
#######################################################################################
##
## The script goes through all Directadmin users and teaches SpamAssassin/Rspamd
## per user bases. Every user has its own bayes data, stored uner their own homedir.
##
#######################################################################################
##
## MIT License
##
## Copyright (c) 2016-2022 Alex S Grebenschikov (www.poralix.com)
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

DELETE_TEACH_DATA="0";             # deprecated
DELETE_TEACH_SPAM_DATA="0";        # clean spam data
DELETE_TEACH_HAM_DATA="0";         # clean ham data
MARK_AS_READ_TEACH_SPAM_DATA="0";  # mark as read spam data
MARK_AS_READ_TEACH_HAM_DATA="0";   # mark as read ham data
TEACH_SPAM_FOLDER="INBOX.teach-isspam";
TEACH_HAM_FOLDER="INBOX.teach-isnotspam";

VERSION="0.11 (beta)";

SETTINGS_FILE="`dirname $0`/settings.cnf";
if [ -f "${SETTINGS_FILE}" ]; then . ${SETTINGS_FILE}; fi;

USER_ID=$(id -u);

function e()
{
    echo "[$(date)] $@";
}

function de()
{
    [ "${DEBUG}" == "1" ] && echo "[$(date)] $@";
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
    local loc_sudo_user;
    loc_sudo_user=$(head -1 /usr/local/directadmin/data/admin/admin.list);
    c=$(sudo -u "${loc_sudo_user}" whoami 2>&1);
    if [ "${c}" != "${loc_sudo_user}" ] && [ -n "${loc_sudo_user}" ];
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
    local loc_found="$(find ${1}/{new,cur}/ -type f 2>/dev/null | wc -l)"
    local loc_res;
    local loc_notlearned;

    if [ "${loc_found}" -ne 0 ]; then
    {
        e "[OK] [${user}] [+] Found ${loc_found} emails under ${1}, now going to learn spam";
        if [ "${IS_SPAMASSASSIN}" == "1" ]; then
        {
            loc_res=$(${SUDO} -u ${user} ${TEACH_BIN} --no-sync --spam ${1}/{cur,new});
            loc_notlearned=$(echo "${loc_res}" | grep "from 0 message" -c);
            [ "${loc_notlearned}" == "1" ] || DO_SYNC=1;
        }
        else
        {
            loc_res=$(${TEACH_BIN} -v --connect ${RSPAMD_SOCK} learn_spam ${1}/{cur,new});
        }
        fi;

        e "[OK] [${user}] [+] Teaching user SPAM from ${1}";
        e "[OK] [${user}] [+] ${loc_res}";

        if [ "${DELETE_TEACH_SPAM_DATA}" == "1" ]; then
        {
            e "[OK] [${user}] [+] Removing emails from ${1}";
            if [ "${DEBUG}" == "1" ]; then
                find ${1}/{new,cur}/ -type f -exec rm -f -v {} \;
            else
                find ${1}/{new,cur}/ -type f -exec rm -f {} \;
            fi;
        }
        elif [ "${MARK_AS_READ_TEACH_SPAM_DATA}" == "1" ]; then
        {
            markallread "${1}";
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
    local loc_found="$(find ${1}/{new,cur}/ -type f 2>/dev/null | wc -l)"
    local loc_res;
    local loc_notlearned;

    if [ "${loc_found}" -ne 0 ]; then
    {
        e "[OK] [${user}] [+] Found ${loc_found} emails under ${1}, now going to learn ham";
        if [ "${IS_SPAMASSASSIN}" == "1" ]; then
        {
            loc_res=$(${SUDO} -u ${user} ${TEACH_BIN} --no-sync --ham  ${1}/{cur,new});
            loc_notlearned=$(echo "${loc_res}" | grep "from 0 message" -c);
            [ "${loc_notlearned}" == "1" ] || DO_SYNC=1;
        }
        else
        {
            loc_res=$(${TEACH_BIN} -v --connect ${RSPAMD_SOCK} learn_ham ${1}/{cur,new});
        }
        fi;

        e "[OK] [${user}] [+] Teaching user HAM from ${1}";
        e "[OK] [${user}] [+] ${loc_res}";

        if [ "${DELETE_TEACH_HAM_DATA}" == "1" ]; then
        {
            e "[OK] [${user}] [+] Removing emails from ${1}";
            if [ "${DEBUG}" == "1" ]; then
                find ${1}/{new,cur}/ -type f -exec rm -f -v {} \;
            else
                find ${1}/{new,cur}/ -type f -exec rm -f {} \;
            fi;
        }
        elif [ "${MARK_AS_READ_TEACH_HAM_DATA}" == "1" ]; then
        {
            markallread "${1}";
        }
        fi;
    }
    else
    {
        e "[OK] [${user}] [-] No emails found under ${1}, skipping learning ham";
    }
    fi;
}

function markallread()
{
    if cd "${1}/new"; 
    then
        de "[OK] [${user}] [DEBUG] Directory changed to ${1}/new";
        e "[OK] [${user}] [+] Going to mark emails as read in ${1}/new/";
        for email in $(ls -1 ./* 2>/dev/null);
        do
            # Move from /new/ to /cur/
            # Also add status "seen" to message by appending :2,S to filename
            de "[OK] [${user}] [DEBUG] Marking email ${email} as read now:";
            mv ${VERBOSE} "${email}" "`echo ${email} | sed -r 's/^.\/(.*)$/..\/cur\/\1:2,S/'`";
        done;
    else
        e "[ERROR] Failed to change diretory to ${1}/new. Skipping marking emails as read.";
    fi;

    if cd "${1}/cur";
    then
        de "[OK] [${user}] [DEBUG] Directory changed to ${1}/cur";
        e "[OK] [${user}] [+] Going to mark emails as read in ${1}/cur";
        for email in $(ls -1 ./ -I "*:2,*S*" 2>/dev/null);
        do
            # Add status "seen" to message by appending S to filename
            de "[OK] [${user}] [DEBUG] Marking email ${email} as read now:";
            mv ${VERBOSE} "${email}" "`echo ${email} | sed -r 's/^(.*)$/\1S/'`";
        done;
    else
        e "[ERROR] Failed to change diretory to ${1}/cur. Skipping marking emails as read.";
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
    USER_HOME=$(grep -m1 "^${user}:" /etc/passwd | awk -F: '{print $6}');
    DO_SYNC=0;
    cd "${USER_HOME}" || e "[ERROR] Failed to change directory to ${USER_HOME}";

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
        for domain in $(ls ${USER_HOME}/imap 2>/dev/null);
        do
        {
            DOMAIN_DIR="${USER_HOME}/imap/${domain}";
            if [ -h "${DOMAIN_DIR}" ]; then continue; fi;

            e "[OK] [${user}] [+] found mail-domain ${domain} owned by ${user} in ${DOMAIN_DIR}";

            for mdir in $(ls -d ${DOMAIN_DIR}/*/Maildir 2>/dev/null);
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

    if [ "${IS_SPAMASSASSIN}" == "1" ]; then
    {
        # Run once per user, instead of once per email box
        if [ "${DO_SYNC}" == "1" ]; then
        {
            e "[OK] [${user}] Synchronizing the database and the journal";
            # Synchronize the database and the journal if needed
            ${SUDO} -u ${user} ${TEACH_BIN} --sync;
            ${SUDO} -u ${user} ${TEACH_BIN} --dump magic;
        }
        else
        {
            e "[OK] [${user}] [-] Nothing to synchronize yet";
        }
        fi;
    }
    else
    {
        e "[INFO] No need to sync with Rspamd, yet";
    }
    fi;
}

user=$(whoami);
e "[OK] Started ${VERSION}!";
e "[INFO] Running $0 as user ${user}";
e "[INFO] DELETE_TEACH_SPAM_DATA=${DELETE_TEACH_SPAM_DATA}";
e "[INFO] DELETE_TEACH_HAM_DATA=${DELETE_TEACH_HAM_DATA}";
e "[INFO] MARK_AS_READ_TEACH_SPAM_DATA=${MARK_AS_READ_TEACH_SPAM_DATA}";
e "[INFO] MARK_AS_READ_TEACH_HAM_DATA=${MARK_AS_READ_TEACH_HAM_DATA}";

# WHAT OPTION DO WE HAVE IN DIRECTADMIN?
SPAMD_OPTION=$(grep ^spamd= /usr/local/directadmin/custombuild/options.conf | cut -d= -f2);

case "${SPAMD_OPTION}" in
    rspamd)
        e "[INFO] Rspamd is enabled in DirectAdmin options";
        # IS RSPAMD INSTALLED AND RUNNING?
        TEACH_BIN="/usr/local/bin/rspamc";
        [ -f "${TEACH_BIN}" ] || TEACH_BIN="/usr/bin/rspamc";
        [ -f "${TEACH_BIN}" ] || TEACH_BIN="/bin/rspamc";
        if [ ! -f "${TEACH_BIN}" ]; then
        {
            TEACH_BIN="";
            e "Rspamd is not installed on the server. Terminating...";
            exit 100;
        }
        fi;
        RSPAMD_SOCK="/var/run/rspamd/rspamd_controller.sock";
        IS_RSPAMD=1;
        IS_SPAMASSASSIN=0;
    ;;
    spamassassin)
        e "[INFO] SpamAssassin is enabled in DirectAdmin options";
        # IS SPAMASSASSIN INSTALLED AND RUNNING?
        TEACH_BIN="/usr/local/bin/sa-learn";
        [ -f "${TEACH_BIN}" ] || TEACH_BIN="/usr/bin/sa-learn";
        [ -f "${TEACH_BIN}" ] || TEACH_BIN="/bin/sa-learn";
        if [ ! -f "${TEACH_BIN}" ]; then
        {
            TEACH_BIN="";
            e "SpamAssassin is not installed on the server. Terminating...";
            exit 100;
        }
        fi;
        RSPAMD_SOCK="";
        IS_RSPAMD=0;
        IS_SPAMASSASSIN=1;
    ;;
    no|*)
        e "[ERROR] AntiSpam is disabled in DirectAdmin options. Terminating...";
        # AntiSPAM not enabled?
        TEACH_BIN="";
        RSPAMD_SOCK="";
        exit 1;
    ;;
esac;

check_sudo_exists;
check_sudo_user;

case "${1}" in
    debug|-debug|--debug)
        DEBUG=1;
        VERBOSE="-v";
        e "[INFO] Enabling DEBUG mode";
    ;;
    *)
        DEBUG=0;
        VERBOSE="";
    ;;
esac;

if [ "${USER_ID}" == "0" ]; then
{
    users=$(get_users_list);
    for user in ${users};
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
e "[OK] Finished ${VERSION}!";

exit 0;
