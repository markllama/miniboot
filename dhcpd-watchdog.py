#!/usr/bin/python
#
# Reload dhcpd.service when the dhcpd-server.conf or dhcpd-leases.conf file change
#
import dbus
import os
import sys
import time
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

watchdir = "/opt/etc"
watchfiles = ("dhcpd_server.conf", "dhcpd_leases.conf")

class SystemdReloadHandler(FileSystemEventHandler):
    def on_modified(self, event):
        sysbus = dbus.SystemBus()
        systemd1 = sysbus.get_object('org.freedesktop.systemd1', '/org/freedesktop/systemd1')
        manager = dbus.Interface(systemd1, 'org.freedesktop.systemd1.Manager')
        job = manager.ReloadUnit('dhcpd.service', 'fail')

if __name__ == "__main__":
    event_handler = SystemdReloadHandler()
    observer = Observer()
    observer.schedule(event_handler, os.path.join(watchdir, watchfiles[0]))
    observer.schedule(event_handler, os.path.join(watchdir, watchfiles[1]))    
    observer.start()
    try:
        while True:
            time.sleep(5)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()
