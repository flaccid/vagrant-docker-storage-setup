# vagrant-docker-storage-setup
Easily run up docker-storage-setup within Vagrant

### Clearing the attached disk manually

Its important that there is no partition scheme on the disk.
Essentially for a re-test, `/dev/sdb` should not exist in /proc/partitions.

You can wipe the partitions with something like:

    # systemctl stop docker
    # lvremove --force dockervg || true && vgchange -a n dockervg vgremove dockervg || true
    # dd if=/dev/zero of=/dev/sdb bs=512 count=1 && (rm -f /dev/sdb1 || true)

### Running the test-kitchen bootstrap manually

If the bootstrap and/or setup of the storage fails, you can login to the
running VM and call the bootstrap script again after ensuring partition wipe:

    $ kitchen login   # this gets you into the VM
    $ sudo /tmp/kitchen/bootstrap.sh
