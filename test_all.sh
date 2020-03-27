#!/bin/sh

ERRFILE=/tmp/.cgroup-utils.stderr
PYTHON=python

while getopts 23 OPT; do
    case $OPT in
        2)  PYTHON=python2
        ;;
        3)  PYTHON=python3
        ;;
    esac
done

results_ok=0
results_ng=0
results_un=0	# Unknown

enabled_cgroups=
while read name _ _ enabled; do
    if [ $enabled = 1 ]; then
        if [ $name != perf_event -a $name != debug ]; then
            enabled_cgroups="$enabled_cgroups $name"
        fi
    fi
done < /proc/cgroups

named_cgroup=$(grep cgroup /proc/mounts | egrep -o -e 'name=[^,\ ]*')
if [ -n "$named_cgroup" ]; then
    enabled_cgroups="$enabled_cgroups $named_cgroup"
fi

test_run()
{
    cmd="$PYTHON $*"

    $cmd >/dev/null 2>$ERRFILE
    ret=$?
    if [ $ret != 0 ]; then
        grep -q "EnvironmentError: Not enabled in the system" $ERRFILE
        if [ $? = 0 ]; then
            echo "[??] $cmd"
            results_un=$((results_un + 1))
        else
            echo "[NG] $cmd"
            results_ng=$((results_ng + 1))
            cat $ERRFILE
        fi
    else
        echo "[ok] $cmd"
        results_ok=$((results_ok + 1))
    fi
}

test_run_event()
{
    cmd="$PYTHON $*"

    $cmd >/dev/null 2>$ERRFILE
    ret=$?
    if [ $ret = 2 ]; then
        # Timed out
        echo "[ok] $cmd"
        results_ok=$((results_ok + 1))
    else
        echo "[NG] $cmd"
        results_ng=$((results_ng + 1))
        cat $ERRFILE
    fi
}

test_support()
{
    cmd="$PYTHON $*"

    $cmd >/dev/null 2>$ERRFILE
    ret=$?
    if [ $ret != 0 ]; then
        echo "[NG] $cmd"
        results_ng=$((results_ng + 1))
        cat $ERRFILE
    else
        echo "[ok] $cmd"
        results_ok=$((results_ok + 1))
    fi
}

buildpath=$(find ./build/lib.linux* -maxdepth 0 -type d)
export PYTHONPATH=$buildpath:.

echo "## Testing each commands for each subsystems"
for subsys in $enabled_cgroups; do
    test_run bin/cgutil tree -o $subsys
    test_run bin/cgutil configs -o $subsys
    test_run bin/cgutil stats -o $subsys
done

test_run bin/cgutil top -b -n 1

root=$(awk '/^(cgroup.*)?memory/ {print $2;}' /proc/mounts)
path=$root/memory.usage_in_bytes
test_run_event bin/cgutil event -t 0.1 $path +1M
path=$root/memory.oom_control
test_run_event bin/cgutil event -t 0.1 $path

echo "## Testing each command helps"
for cmd in configs event pgrep stats top tree; do
    test_run bin/cgutil $cmd --help
done

echo "## Run doctest of cgroup.py"
$PYTHON -mdoctest cgutils/cgroup.py

echo "## Checking unsupported files of subsystems"
for subsys in $enabled_cgroups; do
    test_support bin/check_support -o $subsys
done

echo "$results_ok tests passed, $results_ng tests failed, $results_un tests unknown"

if [ $results_ng -gt 0 ]; then
    status=1
else
    status=0
fi
exit $status
