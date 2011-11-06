#
## Calomel.org  ssh_gatekeeper.sh
#
## This script is run by the ForceCommand directive in the sshd_config. It expects
## the user SSH'ing to the box to answer the $QUERY question before being allowed
## a shell. Permissions of this script should be owned by root and executable by
## all other users (chmod 755)". Rsync, sftp and sshfs are allowed through,
## but scp is denied.
#

## Disconnect clients who try to quit the script (Ctrl-c)
trap jail INT
jail()
 {
   kill -9 $PPID
   exit 0
 }

## Allow SSH. Clients can ssh to the box and then answer the $QUERY question.
if [ -z "$SSH_ORIGINAL_COMMAND" ];
  then
    ## This is the question the client needs to know the answer to.
    ## Here we are asking for the current minute, day of the month
    ## and hour (24-hour time). If the date is "Mon Jan 10 13:25:00 EST 2020"
    ## then the answer is "251013"
    #QUERY=`date +%M%d%H`

    ### The welcome message. This can be helpful or completely arbitrary
    ### depending on your user. Here we use a random quote as we are
    ### expecting the user to already know the question.
    echo "" 
    echo "    All truths are easy to understand once they are"
    echo "    discovered; the point is to discover them."
    echo "                                   -Galileo Galilei"
    echo ""

    ### The Decision
    ### If the answer is correct give the user their shell.
    ### If the answer is wrong, log the attempt and kill the connection.


	pam=`pam_proxy $USER`
         if [ $? -eq 0 ];
           then
		echo 'Authenticated'
             $SHELL -l
             exit 0
           else
             logger "ssh_gatekeeper $USER login failed from $SSH_CLIENT"
		echo 'Authentication falied'
             kill -9 $PPID
             exit 0
         fi
fi

## Allow RSYNC. Rsync can not be used with the question above.
## We need to let the command though so our shell environment is clean. 
if [ `echo $SSH_ORIGINAL_COMMAND | awk '{print $1}'` = rsync ];
  then
    $SHELL -c "$SSH_ORIGINAL_COMMAND"
    exit 0
fi

## Allow sftp and sshfs. Make sure the path to your sftp-server binary
## is correctly expressed below. We need to let the command though so
## our shell environment is clean.
if [ `echo $SSH_ORIGINAL_COMMAND | awk '{print $1}'` = "/usr/lib/openssh/sftp-server" ];
  then
    $SHELL -c "$SSH_ORIGINAL_COMMAND"
    exit 0
fi

## Default deny. This is the last command to catch all other command
## input. If the client tries to use anything other than ssh or rsync
## the connection is dropped. SCP is denied.
kill -9 $PPID
exit 0

