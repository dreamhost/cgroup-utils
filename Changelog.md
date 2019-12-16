# Changelog

## 0.8

- Tweak cgutil top for recent environments
- Use GitHub Actions as CI

## 0.7

- Support PID and RDMA subsystems
- Support new control files
- Mark python2 deprecated

## 0.6

- Support new control files added between Linux 3.9 and 3.18
- Support Python 3
- Drop Python 2.5 support
- Fix several bugs. Thanks lebauce and pavel-odintsov!

## 0.5

- Support hugetlb subsystem
- Support additional cgroup files of blkio, memory and freezer
- Use argparse instead of optparse
- Fix several bugs. Thanks novas0x2a and unicell!

## 0.4

- Add unit tests for control file parsers and a test for PEP8 compliance
- Support dynamic cgroups hierarchy update for top command
- Support missing net_prio subsystem
- Complete event_control supports in event command
- Implement mkdir/rmdir commands
- Fix a bunch of bugs
