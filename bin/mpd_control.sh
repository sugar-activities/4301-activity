#!/bin/sh -e

if [ -n "$MPD_DEBUG" ]; then
    set -x
    MPD_OPTS=--verbose
fi

umask 0022
PATH=/sbin:/bin:/usr/sbin:/usr/bin

LOCATION=`dirname $0`
LOCATION=`dirname $LOCATION`

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$LOCATION/lib

# edit /etc/default/mpd to change these:
DAEMON=$LOCATION/bin/mpd
if [ ! -f $HOME/.mpd/mpd.conf ] ; then
	if [ ! -d $HOME/.mpd ] ; then
		mkdir $HOME/.mpd
		mkdir $HOME/.mpd/Music
		mkdir $HOME/.mpd/Playlists
	fi
	cp $LOCATION/etc/mpd.conf.template $HOME/.mpd/mpd.conf
fi
MPDCONF=$HOME/.mpd/mpd.conf
START_MPD=true
PIDFILE=`sed -n -e 's/^[[:space:]]*pid_file[[:space:]]*"\?\([^"]*\)\"\?/\1/p' $MPDCONF`
USER=`sed -n -e 's/^[[:space:]]*user[[:space:]]*"\?\([^"]*\)\"\?/\1/p' $MPDCONF`

if [ -r /etc/default/mpd ]; then
    . /etc/default/mpd
fi

if [ ! -e `dirname $PIDFILE` ];then
       mkdir `dirname $PIDFILE`
       chown $USER `dirname $PIDFILE`
fi

check_conf () {
    if ! (grep -q db_file $MPDCONF && grep -q pid_file $MPDCONF); then
        echo "$MPDCONF must have db_file and pid_file set; not starting."
        exit 1
    fi
}

check_dbfile () {
    DBFILE=`sed -n -e 's/^[[:space:]]*db_file[[:space:]]*"\?\([^"]*\)\"\?/\1/p' $MPDCONF`
    if [ "$FORCE_CREATE_DB" -o ! -f "$DBFILE" ]; then
        echo -n "creating $DBFILE... "
        $DAEMON --create-db "$MPDCONF" > /dev/null 2>&1
    fi
}

mpd_start () {
    if [ "$START_MPD" != "true" ]; then
        echo "Not starting MPD: disabled by /etc/default/mpd."
        exit 1
    fi
    echo -n "Starting Music Player Daemon: "
    check_conf
    check_dbfile
    if $DAEMON $MPD_OPTS "$MPDCONF"; then
        echo "mpd."
    else
        echo "failed."
        exit 1
    fi
}

mpd_stop () {
    echo -n "Stopping Music Player Daemon: "
    if $DAEMON --kill "$MPDCONF" >/dev/null 2>&1; then
        echo "mpd."
    else
        echo "not running or no pid_file set."
    fi
}

# note to self: don't call the non-standard args for this in
# {post,pre}{inst,rm} scripts since users are not forced to upgrade
# /etc/init.d/mpd when mpd is updated
case "$1" in
    start)
        mpd_start
        ;;
    stop)
        mpd_stop
        ;;
    restart|reload)
        mpd_stop
        mpd_start
        ;;
    force-start|start-create-db)
        FORCE_CREATE_DB=1
        mpd_start
        ;;
    force-restart|force-reload)
        FORCE_CREATE_DB=1
        mpd_stop
        mpd_start
        ;;
    *)
        echo "Usage: $0 {start|start-create-db|stop|restart|reload}"
        exit 1
        ;;
esac
