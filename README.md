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

## Usage

Configure Poni config file by editing /etc/poni/config.yml

place each Sync configuration under "Sync" section, here are some examples:

    sync:
        /opt/dir1:
            remote_host: nycweb1                ## target host
            remote_path: /opt                   ## target path on remote host
            remote_user: jsmith                 ## user which will initiate rsync
            priv_key: /home/jsmith/.ssh/id_rsa  ## path to user's private SSH key
            port: 1122                          ## custom SSH port, default = 22
            rsync_opts: azBP                    ## additional Rsync flags (default: azP)
            interval: 15                        ## sleep time in seconds before rsyncing on a change, default = 3
            recurse: "true"                     ## watch directories recursively for changes, default = "false"

        /var/log/syslog:
            remote_host: web9
            remote_path: /mnt/backup/logs/host123
            remote_user: root
            priv_key: /root/.ssh/id_rsa

Poni will read each file or folder path as a separate sync directive, read the remote host, remote path, remote user and any given rsync options or sync interval.

Make sure the user you specify in the systemd service script is able to access the SSH private key path, otherwise the sync wont work.

Once config file is ready, start Poni service,

    sudo systemctl restart poni

To view Poni logs, tail the service

    sudo journalctl -f -u poni

Poni will spawn independent sync workers for each Sync configuration and use INotify bindings to detect any changes to the configured files or folders. Once a change is detected, Poni will sync the updated file or folder to the remote_host, using the remote_user and priv_key values (only SSH key pairs are allowed for rsyncing)

To decrease the amount of syncs between your Poni server and partner/slave hosts, use "interval" value in seconds. Specifying an Interval makes Poni sleep (interval) seconds before syncing the changes. By default, Poni will sync every 3 seconds if a change is detected.

To add additional rsync options, use rsync_opts parameter. Default rsync flags are "azP"

## Development

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
