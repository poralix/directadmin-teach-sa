#!/usr/bin/env bash
#######################################################################################
##
## Written by Alex S Grebenschikov (zEitEr) $ Mon Sep 26 18:34:51 +07 2016
## www: http://www.poralix.com/
## email: support@poralix.com
## Version: 0.2 (beta), Mon Sep 11 20:04:25 +07 2017
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
    echo "";
    echo "TEACH SPAM FOLDER: ${TEACH_SPAM_FOLDER}";
    echo "TEACH NOT SPAM FOLDER: ${TEACH_HAM_FOLDER}";
    echo "DELETE TEACH DATA: ${DELETE_TEACH_DATA}";
    echo "";
    echo "The settings can be re-defined in `dirname $0`/settings.cnf";
    echo "";
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
        e "[WARNING] [-] Directory ${loc_dir} already exists, skipping...";
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
        e "[WARNING] [-] Skipping subscriptions. Already exists...";
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
            if [ -n "${TEACH_SPAM_FOLDER}" ]; then process_folder "${TEACH_SPAM_FOLDER}" "/home/${user}/Maildir"; fi;

            # HAM
            if [ -n "${TEACH_HAM_FOLDER}" ]; then process_folder "${TEACH_HAM_FOLDER}" "/home/${user}/Maildir"; fi;
        }
        else
        {
            e "[WARNING] Skipping system account for user ${user}, as programm is running in a single mailbox mode...";
        }
        fi;
    }
    fi;

    if [ ! -d "/home/${user}/imap/${domain}/" ];
    then
    {
        e "[WARNING] Does not seem to have imap folder. Skipping...";
        return;
    }
    fi;

    e "[OK] Found imap folder /home/${user}/imap/${domain}/";

    if [ ! -f "/etc/virtual/${domain}/passwd" ];
    then
    {
        e "[WARNING] Password file does not exist for the domain ${domain}!";
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
    local mdir="`grep ^${box}: /etc/virtual/${domain}/passwd | cut -d\: -f6`/Maildir";

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

if [ -z "$1" ]; then usage; fi;

case $1 in
    "--all")
        process_all_domains;
    ;;
    "--settings")
        show_options;
    ;;
    *)
        c=`echo ${1} | grep -c '@'`;
        if [ "${c}" == "0" ]; then process_domain "${1}"; fi;
        if [ "${c}" == "1" ]; then process_mailbox "${1}"; fi;
    ;;
esac;

exit 0;
