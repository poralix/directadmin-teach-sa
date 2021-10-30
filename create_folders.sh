#!/usr/bin/env bash
#######################################################################################
##
## Written by Alex S Grebenschikov (zEitEr)
## www: http://www.poralix.com/
## Report bugs and issues: https://github.com/poralix/directadmin-teach-sa/issues
## Version: 0.9 (beta), Sat Oct 30 17:37:09 +07 2021
##
#######################################################################################
##
## The script creates IMAP folders TEACH-SPAM and TEACH-ISNOTSPAM on per 
## mailbox, domain bases or for all existing domains.
##
#######################################################################################
##
## MIT License
##
## Copyright (c) 2016-2021 Alex S Grebenschikov (www.poralix.com)
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

SETTINGS_FILE="`dirname $0`/settings.cnf";
if [ -f "${SETTINGS_FILE}" ]; then . ${SETTINGS_FILE}; fi;

function e()
{
    echo "[$(date)] $@";
}

function usage()
{
    echo "#############################################################################";
    echo "#   The script creates IMAP folders TEACH-SPAM and TEACH-ISNOTSPAM on per   #";
    echo "#   mailbox, domain bases or for all existing domains                       #";
    echo "#                                                                           #";
    echo "#   Written by Alex S Grebenschikov (zEitEr), web: www.poralix.com          #";
    echo "#                                                                           #";
    echo "#############################################################################";
    echo "";
    echo "Usage $0 [<email-box>|<domain-name>|--all|--settings]";
    echo "";
    echo "Options:"
    echo "   <email-box>   - specify a mail-box to create folders for a single";
    echo "                   mailbox, e.g. info@example.com";
    echo "   <domain-name> - specify a domain-name to create folder for all ";
    echo "                   existing mail-boxes on the domain, e.g. example.com";
    echo "   --all         - used to create imap folders for all existing mail boxes";
    echo "                   on all the existing domains on the server";
    echo "   --settings    - used to show names of the imap folders for learning";
    echo "";
    exit 1;
}

function show_options()
{
    echo "
    # SPAM:
    TEACH SPAM FOLDER: ${TEACH_SPAM_FOLDER}
    DELETE TEACH SPAM DATA: ${DELETE_TEACH_SPAM_DATA}
    MARK AS READ SPAM DATA: ${MARK_AS_READ_TEACH_SPAM_DATA}

    # NOT SPAM:
    TEACH NOT SPAM FOLDER: ${TEACH_HAM_FOLDER}
    DELETE TEACH NOT SPAM DATA: ${DELETE_TEACH_HAM_DATA}
    MARK AS READ NOT SPAM DATA: ${MARK_AS_READ_TEACH_HAM_DATA}

    # IMPORTANT:
    The settings can be re-defined in `dirname $0`/settings.cnf
    Report bugs and issues here: https://github.com/poralix/directadmin-teach-sa/issues
    ";
    exit 1;
}

function process_folder()
{
    local loc_folder="${1}";
    local loc_mdir="${2}";
    local loc_dir="${loc_mdir}/.${loc_folder}/";

    if [ ! -d "${loc_dir}" ]; then
    {
        e "[OK] [+] Creating directory ${loc_dir}";
        mkdir ${loc_dir};

        chmod 770 ${loc_dir};
        chown ${user}:mail ${loc_dir};
        [ -d "${loc_dir}" ] && e "[OK] [+] Created ${loc_dir}";
    }
    else
    {
        e "[NOTICE] [-] Directory ${loc_dir} already exists, skipping...";
    }
    fi;

    c=`grep ${loc_folder} ${loc_mdir}/subscriptions -c 2>/dev/null`
    if [ "${c}" == "0" ]; then
    {
        e "[OK] [+] Updating subscriptions";
        echo ${loc_folder} >> ${loc_mdir}/subscriptions
    }
    else
    {
        e "[NOTICE] [-] Skipping subscriptions. Already exists...";
    }
    fi;
}

function process_mailbox()
{
    email="${1}";
    mailbox=`echo ${email} | cut -d\@ -f1`;
    domain=`echo ${email} | cut -d\@ -f2`;
    e "[OK] Running for mailbox ${mailbox} on domain ${domain}";
    process_domain "${domain}" "${mailbox}";
}

function process_domain()
{
    domain="${1}";
    mailbox="${2}";
    user=`grep ^${domain}: /etc/virtual/domainowners | cut -d\  -f2`;

    if [ -z "${user}" ];
    then
    {
        e "[ERROR] Domain ${domain} was not found on the server!";
        return;
    }
    fi;

    e "[OK] Domain ${domain} owned by user ${user}";

    # Create folder for system mail account
    if [ -d "/home/${user}/Maildir" ]; then
    {
        if [ -z "${mailbox}" ];
        then
        {
            e "[OK] Processing system mail account for user ${user} (i.e. ${user}@$(hostname))";

            # SPAM
            if [ -n "${TEACH_SPAM_FOLDER}" ]; then process_folder "${TEACH_SPAM_FOLDER}" "/home/${user}/Maildir" >/dev/null; fi;

            # HAM
            if [ -n "${TEACH_HAM_FOLDER}" ]; then process_folder "${TEACH_HAM_FOLDER}" "/home/${user}/Maildir" >/dev/null; fi;
        }
        else
        {
            e "[NOTICE] Skipping system account for user ${user}, as programm is running in a single mailbox mode...";
        }
        fi;
    }
    fi;

    if [ ! -d "/home/${user}/imap/${domain}/" ];
    then
    {
        e "[NOTICE] Does not seem to have imap folder. Skipping...";
        return;
    }
    fi;

    e "[OK] Found imap folder /home/${user}/imap/${domain}/";

    if [ ! -f "/etc/virtual/${domain}/passwd" ];
    then
    {
        e "[NOTICE] Password file does not exist for the domain ${domain}!";
        return;
    }
    fi;

    c=`wc -l "/etc/virtual/${domain}/passwd" | cut -d\  -f1`

    if [ "${c}" == "0" ]; 
    then
    {
        e "[NOTICE] Password file found but is empty for the domain ${domain}. Skipping...";
        return;
    }
    fi;

    e "[OK] Password file found for the domain ${domain}";

    if [ -z "${mailbox}" ];
    then
    {
        for box in `cat /etc/virtual/${domain}/passwd | cut -d\: -f1`;
        do
        {
            create_folders;
        }
        done;
    }
    else
    {
        box=`cat /etc/virtual/${domain}/passwd | grep "^${mailbox}:"|cut -d\: -f1`;
        create_folders;
    }
    fi;
}

function process_all_domains()
{
    for domain in `cat /etc/virtual/domainowners | cut -d\: -f1 | sort | uniq`;
    do
    {
        process_domain "${domain}";
    }
    done;
}

function create_folders()
{
    local mdir=`grep ^${box}: /etc/virtual/${domain}/passwd | cut -d\: -f6`;
    if [ -n "${mdir}" ]; 
    then
    {
        mdir="${mdir}/Maildir";

        if [ -d "${mdir}" ];
        then
        {
            e "[OK] Found maildir for ${box} in ${mdir}";

            # SPAM
            if [ -n "${TEACH_SPAM_FOLDER}" ]; then process_folder "${TEACH_SPAM_FOLDER}" "${mdir}"; fi;

            # HAM
            if [ -n "${TEACH_HAM_FOLDER}" ]; then process_folder "${TEACH_HAM_FOLDER}" "${mdir}"; fi;
        }
        else
        {
            e "[WARNING] maildir ${box} was not found in ${mdir}";
        }
        fi;
    }
    fi;
}

if [ -z "$1" ]; then usage; fi;


case $1 in
    "--all")
        e "[OK] Program started"
        process_all_domains;
        e "[OK] Program finished"
    ;;
    "--settings")
        show_options;
    ;;
    *)
        e "[OK] Program started"
        c=`echo ${1} | grep -c '@'`;
        if [ "${c}" == "0" ]; then process_domain "${1}";
        else process_mailbox "${1}"; fi;
        e "[OK] Program finished"
    ;;
esac;


exit 0;
