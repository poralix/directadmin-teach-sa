#!/bin/env bash
#######################################################################################
##
## Written by Alex S Grebenschikov $ Mon Sep 26 18:34:51 +07 2016
## www: http://www.poralix.com/
## email: support@poralix.com
##
#######################################################################################
##
## The script creates imap folders for all email accounts on the server
## according to this guide http://help.directadmin.com/item.php?id=358
##
#######################################################################################
##
## MIT License
##
## Copyright (c) 2016 Alex S Grebenschikov
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

TEACH_SPAM_FOLDER="INBOX.teach-isspam";
TEACH_HAM_FOLDER="INBOX.teach-isnotspam";

if [ -f "settings.cnf" ]; then
. settings.cnf
fi;

function usage()
{
    echo "Usage $0 [<domain-name>|--all|--options]";
    exit 1;
}

function show_options()
{
    echo "";
    echo "TEACH SPAM FOLDER: ${TEACH_SPAM_FOLDER}";
    echo "TEACH NOT SPAM FOLDER: ${TEACH_HAM_FOLDER}";
    echo "";
    echo "The folders can be re-defined in settings.cnf";
    echo "";
    exit 1;
}

function process_folder()
{
    check_folder="${1}";
    check_dir="${mdir}/.${check_folder}/";

    if [ ! -d "${check_dir}" ]; then
    {
        echo "[OK] [+] Creating directory ${check_dir}";
        mkdir ${check_dir};

        chmod 770 ${check_dir};
        chown ${user}:mail ${check_dir};
        [ -d "${check_dir}" ] && echo "[OK] [+] Created ${check_dir}";
    }
    else
    {
        echo "[WARNING] [-] Directory ${check_dir} already exists, skipping...";
    }
    fi;

    c=`grep ${check_folder} ${mdir}/subscriptions -c`
    if [ $c -eq 0 ]; then
    {
        echo "[OK] [+] Updating subscriptions";
        echo ${check_folder} >> ${mdir}/subscriptions
    }
    else
    {
        echo "[WARNING] [-] Skipping subscriptions. Already exists...";
    }
    fi;
}

function process_domain()
{
    domain="${1}";
    user=`grep ^${domain}: /etc/virtual/domainowners | cut -d\  -f2`;

    if [ -z "${user}" ];
    then
    {
        echo "[ERROR] Domain ${domain} was not found on the server!";
        return;
    }
    fi;

    echo "[OK] Domain ${domain} owned by user ${user}";

    if [ ! -d "/home/${user}/imap/${domain}/" ];
    then
    {
        echo "[WARNING] Does not seem to have imap folder. Skipping...";
        return;
    }
    fi;

    echo "[OK] Found imap folder /home/${user}/imap/${domain}/";

    if [ ! -f "/etc/virtual/${domain}/passwd" ];
    then
    {
        echo "[WARNING] Password file does not exist for the domain ${domain}!";
        return;
    }
    fi;

    c=`wc -l "/etc/virtual/${domain}/passwd" | cut -d\  -f1`

    if [ "${c}" == "0" ]; 
    then
        echo "[WARNING] Password file found but is empty for the domain ${domain}. Skipping...";
        return;
    fi;

    echo "[OK] Password file found for the domain ${domain}";

    for box in `cat /etc/virtual/${domain}/passwd | cut -d\: -f1`;
    do
    {
        mdir="`grep ^${box}: /etc/virtual/${domain}/passwd | cut -d\: -f6`/Maildir";

        if [ -d "${mdir}" ];
        then
        {
            echo "[OK] Found maildir for ${box} in ${mdir}";

            # SPAM
            if [ -n "${TEACH_SPAM_FOLDER}" ]; then process_folder ${TEACH_SPAM_FOLDER}; fi;

            # HAM
            if [ -n "${TEACH_HAM_FOLDER}" ]; then process_folder ${TEACH_HAM_FOLDER}; fi;
        }
        else
        {
            echo "[WARNING] maildir ${box} was not found in ${mdir}";
        }
        fi;
    }
    done;
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

if [ -z "$1" ]; then usage; fi;

case $1 in
    "--all")
        process_all_domains;
    ;;
    "--options")
        show_options;
    ;;
    *)
        process_domain "${1}";
    ;;
esac;

exit 0;
