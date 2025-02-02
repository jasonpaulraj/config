### yum Error:rpmdb open failed

```BASH
rpmdb: PANIC: fatal region error detected; run recovery
error: db3 error(-30974) from dbenv->open: DB_RUNRECOVERY: Fatal error, run database recovery
error: cannot open Packages index using db3 - (-30974)
error: cannot open Packages database in /var/lib/rpm
CRITICAL:yum.main:

Error: rpmdb open failed
```

## Solution

You may fix this by cleaning out rpm database. But first, in order to minimize the risk, make sure you create a backup of files in /var/lib/rpm/ using cp command:

```bash
mkdir /root/backups.rpm.mm_dd_yyyy/
```

```bash
cp -avr /var/lib/rpm/ /root/backups.rpm.mm_dd_yyyy/
```

The try this to fix this problem:

```bash
rm -f /var/lib/rpm/__db*
```

```bash
db_verify /var/lib/rpm/Packages
```

```bash
rpm --rebuilddb
```

```bash
yum clean all
```

And finally verify that error has gone with the following yum command

```bash
yum update
```
