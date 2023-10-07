# Poni

## inotify transfer daemon

Based on INotify lib from https://github.com/Dlacreme/spy/blob/master/src/watcher.cr

Poni is an INotify rsync daemon.

It can watch multiple files or directories for changes and rsync any changes to a partner/slave host including localhost

It works similar to lsyncd but with much simpler configuration.

Poni uses rsync to do the actual file transfer when it detects a change for a watched file or directory.

---

## Installation

Download or compile Poni as a binary, place into /usr/local/bin

### to run from command line:

    ./poni -c config.yaml

### to run as system service:

Create a systemd service file for Poni,

vi /etc/systemd/system/poni.service

    [Unit]
    Description=Poni
    After=syslog.target network.target

    [Service]
    ExecStart=/usr/local/bin/poni -c /etc/poni/config.yml
    Restart=always
    User=root

    [Install]
    WantedBy=multi-user.target

reload services

    systemctl daemon-reload

start the service

    systemctl restart poni

---

## Usage

Configure Poni config file by editing /etc/poni/config.yml

place each Sync configuration under "Sync" section, and give each sync a unique name/description

see config.yaml for examples

    sync:
      "sync dir1 to nycweb1":               ## unique name/description for each sync
        source_path: /opt/dir1              ## local path that will be synced to target
        remote_host: nycweb1                ## target host
        remote_path: /opt                   ## target path on remote host
        remote_user: jsmith                 ## SSH user which will initiate rsync
        priv_key: /home/jsmith/.ssh/id_rsa  ## path to user's private SSH key (on the local host running Poni service)
        port: 1122                          ## custom SSH port, default = 22
        rsync_opts: azBP                    ## additional Rsync flags (default: azP)
        interval: 15                        ## sleep time in seconds before rsyncing on a change, default = 10
        recurse: true                       ## watch directories recursively for changes (ie, watch subdirectories), default = false
        simulate: true                      ## show rsync actions in log output, but dont do actual rsync or delete actions. default = true

      "sync syslog to web9":
        source_path: /var/log/syslog
        remote_host: web9
        remote_path: /mnt/backup/logs/host123
        remote_user: root
        priv_key: /root/.ssh/id_rsa

Poni will read each file or folder path as a separate sync directive, read the remote host, remote path, remote user and any given rsync options or sync interval.

For syncs that have same configuration (ie, same remote_host, remote_user, etc) - can use Defaults section for all global default values,

    defaults:
      source_path: /my/default/source/path
      remote_host: default-host-name
      remote_user: default-user-name
      remote_path: /default/path/on/remote/host
      priv_key: default-ssh-key
      interval: 3
      rsync_opts: aVZPs

    sync:
      "sync default path to default target path": []  # this sync will use all the default values above

      "sync default path to default target except for Interval":
        interval: 30  # this sync will use all default values except for Interval


if a Default value is not provided for port, interval, rsync_opts, and recurse, and these values are not provided for invidual Sync configs, Poni will assign an internal default to each one,

- port = 22
- interval = 10 (seconds)
- rsync_opts = "azP"
- recurse = false
- simulate = true

---
### Logging

Poni can log to either syslog or a custom log file

    ---
    log:
      destination: stdout

or

    log:
      destination: /path/to/log/file

you can also set logging levels

    log:
      level: info

- info = will log all messages
- warning = will log only Warning and Error messages
- error = will only log Error messages
- debug = used for development of Poni

---

## Syncing same source_path to multiple remote_paths

if same source_path is configured for multiple remote_paths, then Poni will use the "interval" value of the last config for that source_path, ie

```
sync:
  "sync to web1 - JOE":
    source_path: /my/local/file
    remote_path: /home/joe/
    remote_host: web1
    interval: 30

  "sync to web1 - MARY":
    source_path: /my/local/file
    remote_path: /home/mary
    remote_host: web1
    interval: 5

here the overall sync interval for both remote paths will be 5 seconds
```


---

## Poni process explained

upon startup Poni reads a user-provided config YAML file as demonstrated above

it parses each Sync block and creates an Inotify Watcher which alerts the main thread if a file or directory for each source_path was modified.

After creating a Watcher, Poni will create a background Scheduler which runs every X seconds interval (default is 10 seconds) and checks if there were any change events coming from Watcher

if a change is detected, Scheduler will rsync the changes to the desginated remote host and path.

Poni will only sync from source to remote target on MODIFY events. It does not delete anything on the remote endpoint when you delete a file or directory on your source (local instance running the Poni service).

If you're looking for a Mirror-type solution that keeps both partners in exactly same state, try https://syncthing.net/


---

## Poni SystemD Service

Make sure the user you specify in the systemd service script is able to access the SSH private key path, otherwise the sync wont work.

Once config file is ready, start Poni service,

    sudo systemctl restart poni

To view Poni logs, tail the service (if using the default stanard out)

    sudo journalctl -f -u poni

Poni will spawn independent sync workers for each Sync configuration and use INotify bindings to detect any changes to the configured files or folders. Once a change is detected, Poni will sync the updated file or folder to the remote_host, using the remote_user and priv_key values (only SSH key pairs are allowed for rsyncing)

To decrease the amount of syncs between your Poni server and partner/slave hosts, use "interval" value in seconds. Specifying an Interval makes Poni sleep (interval) seconds before syncing the changes. By default, Poni will sync every 3 seconds if a change is detected.

To add additional rsync options, use rsync_opts parameter. Default rsync flags are "azP"

---

## SSH Sockets

because Poni will make constant rsync calls between the host and partner server, its a good idea to add a SSH socket for this connection, sockets will store SSH session in a file, and will decrease the CPU and MEM usage of each sync (since it doesnt have to re-establish SSH handshake with each rsync call)

for the user that will be making the rsync call, create a SSH config file, ie

    cat /home/user/.ssh/config

    Host <name of partner/slave host>
        StrictHostKeyChecking no
        UserKnownHostsFile=/dev/null
        TCPKeepAlive yes
        ServerAliveInterval 120
        Compression yes
        ControlMaster auto
        ControlPath ~/.ssh/sockets/%r@%h:%p
        ControlPersist yes
        ControlPersist 480m

create a sockets directory

    mkdir /home/user/.ssh/sockets

restart Poni, it will generate a socket file in /home/user/.ssh/sockets and use this socket file for any future connections (and will decrease your CPU and MEM usage)

---

## Development

for Fedora/RHEL/Centos/Rocky builds install libyaml-devel

    yum --enablerepo=powertools install libyaml-devel libffi-devel



to build a test binary

    crystal build src/poni.cr -o bin/poni --error-trace

to build a production release binary

    crystal build src/poni.cr -o bin/poni --release

## Contributing

1. Fork it (<https://github.com/perfecto25/poni/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [perfecto25](https://github.com/perfecto25) - creator and maintainer
