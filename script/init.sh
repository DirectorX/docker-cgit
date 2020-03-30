#!/bin/sh

: ${ETCSVDIR:="/etc/sv"}
: ${RUNSVDIR:=$ETCSVDIR}

# store enviroment variables
export > /etc/envvars

export ETCSVDIR
export ETCSVDIR

shutdown() {
  echo "shutting down container"

  # first shutdown any service started by runit
  for _srv in $(ls -1 $ETCSVDIR); do
    sv force-stop $ETCSVDIR/$_srv
  done

  # shutdown runsvdir command
  kill -HUP $RUNSVDIR_PID
  wait $RUNSVDIR_PID

  # give processes time to stop
  sleep 0.5

  # kill any other processes still running in the container
  for _pid  in $(ps -eo pid | grep -v PID  | tr -d ' ' | grep -v '^1$' | head -n -6); do
    timeout -t 5 /bin/sh -c "kill $_pid && wait $_pid || kill -9 $_pid"
  done
  exit
}

PATH=/usr/local/bin:/usr/local/sbin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/X11R6/bin

# run all scripts in the run_once folder
/bin/run-parts /etc/run_once

exec env - PATH=$PATH runsvdir -P $ETCSVDIR &

RUNSVDIR_PID=$!
echo "Started runsvdir, PID is $RUNSVDIR"
echo "wait for processes to start...."

sleep 5
for _srv in $(ls -1 $ETCSVDIR); do
    sv status $ETCSVDIR/$_srv
done

# catch shutdown signals
trap shutdown SIGTERM SIGHUP SIGQUIT SIGINT
wait $RUNSVDIR_PID

shutdown
